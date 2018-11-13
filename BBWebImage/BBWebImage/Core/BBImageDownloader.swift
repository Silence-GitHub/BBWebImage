//
//  BBImageDownloader.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

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
    var completion: BBImageDownloaderCompletion { get }
    
    func cancel()
}

public protocol BBImageDownloader {
    // Donwload
    func downloadImage(with url: URL, completion: @escaping BBImageDownloaderCompletion) -> BBImageDownloadTask
    
    // Cancel
    func cancel(task: BBImageDownloadTask)
    func cancel(url: URL)
    func cancelAll()
}

private class BBImageDefaultDownloadTask: BBImageDownloadTask {
    private(set) var url: URL
    private(set) var isCancelled: Bool
    private(set) var completion: BBImageDownloaderCompletion
    
    init(url: URL, completion: @escaping BBImageDownloaderCompletion) {
        self.url = url
        self.isCancelled = false
        self.completion = completion
    }
    
    func cancel() { isCancelled = true }
}

public class BBMergeRequestImageDownloader {
    public var donwloadTimeout: TimeInterval
    private let waitingQueue: BBLinkedListQueue
    private var urlOperations: [URL : BBMergeRequestImageDownloadOperation]
    private var maxRunningCount: Int
    private var currentRunningCount: Int
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
        lock = DispatchSemaphore(value: 1)
        self.sessionConfiguration = sessionConfiguration
    }
    
    fileprivate func operation(for url: URL) -> BBMergeRequestImageDownloadOperation? {
        lock.wait()
        let operation = urlOperations[url]
        lock.signal()
        return operation
    }
}

extension BBMergeRequestImageDownloader: BBImageDownloader {
    // Donwload
    @discardableResult
    public func downloadImage(with url: URL, completion: @escaping BBImageDownloaderCompletion) -> BBImageDownloadTask {
        let task = BBImageDefaultDownloadTask(url: url, completion: completion)
        lock.wait()
        var operation: BBMergeRequestImageDownloadOperation? = urlOperations[url]
        if operation == nil { // TODO: Check operation is finished
            let timeout = donwloadTimeout > 0 ? donwloadTimeout : 15
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout) // TODO: Networking parameters
            operation = BBMergeRequestImageDownloadOperation(request: request, session: session)
            operation?.completion = { [weak self] in
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
            urlOperations[url] = operation
            if currentRunningCount < maxRunningCount {
                currentRunningCount += 1
                BBDispatchQueuePool.background.async { [weak self] in
                    guard self != nil else { return }
                    operation?.start()
                }
            } else if let next = operation {
                let node = BBLinkedListNode(value: next)
                waitingQueue.enqueue(node)
            }
        }
        operation?.add(task: task)
        lock.signal()
        return task
    }
    
    // Cancel
    public func cancel(task: BBImageDownloadTask) {
        lock.wait()
        task.cancel()
        if let operation = urlOperations[task.url],
            operation.taskCount <= 1 {
            operation.cancel() // We do not need to remove operation from urlOperations
        }
        lock.signal()
    }
    
    public func cancel(url: URL) {
        lock.wait()
        urlOperations[url]?.cancel() // We do not need to remove operation from urlOperations
        lock.signal()
    }
    
    public func cancelAll() {
        BBDispatchQueuePool.background.async { [weak self] in
            guard let self = self else { return }
            self.lock.wait()
            for (_, operation) in self.urlOperations {
                operation.cancel()
            }
            self.lock.signal()
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
            let operation = downloader?.operation(for: url) {
            operation.urlSession(session, task: task, didCompleteWithError: error)
        }
    }
}

extension BBImageDownloadSessionDelegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let url = dataTask.originalRequest?.url,
            let operation = downloader?.operation(for: url) {
            operation.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }
}
