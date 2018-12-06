//
//  BBImageDownloader.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public typealias BBImageDownloaderProgress = (Data?, Int, UIImage?) -> Void
public typealias BBImageDownloaderCompletion = (Data?, Error?) -> Void

private class BBLinkedListNode {
    fileprivate let value: Any
    fileprivate var next: BBLinkedListNode?
    
    fileprivate init(value: Any) { self.value = value }
}

private class BBLinkedListQueue {
    fileprivate var head: BBLinkedListNode?
    fileprivate var tail: BBLinkedListNode?
    
    fileprivate func enqueue(_ node: BBLinkedListNode) {
        if head == nil { head = node }
        tail?.next = node
        tail = node
    }
    
    fileprivate func dequeue() -> BBLinkedListNode? {
        let node = head
        head = head?.next
        return node
    }
}

public protocol BBImageDownloadTask {
    var url: URL { get }
    var isCancelled: Bool { get }
    var progress: BBImageDownloaderProgress? { get }
    var completion: BBImageDownloaderCompletion { get }
    
    func cancel()
}

public protocol BBImageDownloader: AnyObject {
    // Donwload
    func downloadImage(with url: URL, options: BBWebImageOptions, progress: BBImageDownloaderProgress?, completion: @escaping BBImageDownloaderCompletion) -> BBImageDownloadTask
    
    // Cancel
    func cancel(task: BBImageDownloadTask)
    func cancel(url: URL)
    func cancelAll()
}

private class BBImageDefaultDownloadTask: BBImageDownloadTask {
    private(set) var url: URL
    private(set) var isCancelled: Bool
    private(set) var progress: BBImageDownloaderProgress?
    private(set) var completion: BBImageDownloaderCompletion
    
    init(url: URL, progress: BBImageDownloaderProgress?, completion: @escaping BBImageDownloaderCompletion) {
        self.url = url
        self.isCancelled = false
        self.progress = progress
        self.completion = completion
    }
    
    func cancel() { isCancelled = true }
}

public class BBMergeRequestImageDownloader {
    public var donwloadTimeout: TimeInterval
    public weak var imageCoder: BBImageCoder?
    
    public var currentDownloadCount: Int {
        lock.wait()
        let count = urlOperations.count
        lock.signal()
        return count
    }
    
    public var maxConcurrentDownloadCount: Int {
        get {
            lock.wait()
            let count = maxRunningCount
            lock.signal()
            return count
        }
        set {
            lock.wait()
            maxRunningCount = newValue
            lock.signal()
        }
    }
    
    private let waitingQueue: BBLinkedListQueue
    private var urlOperations: [URL : BBImageDownloadOperation]
    private var maxRunningCount: Int
    private var currentRunningCount: Int
    private var httpHeaders: [String : String]
    private let lock: DispatchSemaphore
    private let sessionConfiguration: URLSessionConfiguration
    private lazy var sessionDelegate: BBImageDownloadSessionDelegate = { BBImageDownloadSessionDelegate(downloader: self) }()
    private lazy var session: URLSession = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 1
        queue.name = "com.Kaibo.BBWebImage.download"
        return URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: queue)
    }()
    
    public init(sessionConfiguration: URLSessionConfiguration) {
        donwloadTimeout = 15
        waitingQueue = BBLinkedListQueue()
        urlOperations = [:]
        maxRunningCount = 6
        currentRunningCount = 0
        httpHeaders = ["Accept" : "image/*;q=0.8"]
        lock = DispatchSemaphore(value: 1)
        self.sessionConfiguration = sessionConfiguration
    }
    
    public func update(value: String?, forHTTPHeaderField field: String) {
        lock.wait()
        httpHeaders[field] = value
        lock.signal()
    }
    
    fileprivate func operation(for url: URL) -> BBImageDownloadOperation? {
        lock.wait()
        let operation = urlOperations[url]
        lock.signal()
        return operation
    }
}

extension BBMergeRequestImageDownloader: BBImageDownloader {
    // Donwload
    @discardableResult
    public func downloadImage(with url: URL, options: BBWebImageOptions = .none, progress: BBImageDownloaderProgress? = nil, completion: @escaping BBImageDownloaderCompletion) -> BBImageDownloadTask {
        let task = BBImageDefaultDownloadTask(url: url, progress: progress, completion: completion)
        lock.wait()
        var operation: BBImageDownloadOperation? = urlOperations[url]
        if operation == nil {
            let timeout = donwloadTimeout > 0 ? donwloadTimeout : 15
            let cachePolicy: URLRequest.CachePolicy = options.contains(.useURLCache) ? .useProtocolCachePolicy : .reloadIgnoringLocalCacheData
            var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeout)
            request.httpShouldHandleCookies = options.contains(.handleCookies)
            request.allHTTPHeaderFields = httpHeaders
            request.httpShouldUsePipelining = true
            let newOperation = BBMergeRequestImageDownloadOperation(request: request, session: session)
            if options.contains(.progressiveDownload) { newOperation.imageCoder = imageCoder }
            newOperation.completion = { [weak self] in
                guard let self = self else { return }
                self.lock.wait()
                self.urlOperations.removeValue(forKey: url)
                if let next = self.waitingQueue.dequeue()?.value as? BBImageDownloadOperation {
                    BBDispatchQueuePool.background.async {
                        next.start()
                    }
                } else if self.currentRunningCount > 0 {
                    self.currentRunningCount -= 1
                }
                self.lock.signal()
            }
            urlOperations[url] = newOperation
            if currentRunningCount < maxRunningCount {
                currentRunningCount += 1
                BBDispatchQueuePool.background.async { [weak self] in
                    guard self != nil else { return }
                    newOperation.start()
                }
            } else {
                let node = BBLinkedListNode(value: newOperation)
                waitingQueue.enqueue(node)
            }
            operation = newOperation
        }
        operation?.add(task: task)
        lock.signal()
        return task
    }
    
    // Cancel
    public func cancel(task: BBImageDownloadTask) {
        task.cancel()
        lock.wait()
        let operation = urlOperations[task.url]
        lock.signal()
        if let operation = operation,
            operation.taskCount <= 1 {
            operation.cancel()
        }
    }
    
    public func cancel(url: URL) {
        lock.wait()
        let operation = urlOperations[url]
        lock.signal()
        operation?.cancel()
    }
    
    public func cancelAll() {
        self.lock.wait()
        let operations = urlOperations
        self.lock.signal()
        for (_, operation) in operations {
            operation.cancel()
        }
    }
}

private class BBImageDownloadSessionDelegate: NSObject, URLSessionTaskDelegate {
    private weak var downloader: BBMergeRequestImageDownloader?
    
    init(downloader: BBMergeRequestImageDownloader) {
        self.downloader = downloader
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let url = task.originalRequest?.url,
            let operation = downloader?.operation(for: url),
            operation.taskId == task.taskIdentifier,
            let taskDelegate = operation as? URLSessionTaskDelegate {
            taskDelegate.urlSession?(session, task: task, didCompleteWithError: error)
        }
    }
}

extension BBImageDownloadSessionDelegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let url = dataTask.originalRequest?.url,
            let operation = downloader?.operation(for: url),
            operation.taskId == dataTask.taskIdentifier,
            let dataDelegate = operation as? URLSessionDataDelegate {
            dataDelegate.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        } else {
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let url = dataTask.originalRequest?.url,
            let operation = downloader?.operation(for: url),
            operation.taskId == dataTask.taskIdentifier,
            let dataDelegate = operation as? URLSessionDataDelegate {
            dataDelegate.urlSession?(session, dataTask: dataTask, didReceive: data)
        }
    }
}
