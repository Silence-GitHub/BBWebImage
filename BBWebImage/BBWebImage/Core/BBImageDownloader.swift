//
//  BBImageDownloader.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public typealias BBImageDownloaderCompletion = (Data?, Error?) -> Void

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
    private var urlOperations: [URL : BBMergeRequestImageDownloadOperation]
    private let operationLock: DispatchSemaphore
    private let downloadQueue: OperationQueue
    private let sessionConfiguration: URLSessionConfiguration
    private lazy var sessionDelegate: BBImageDownloadSessionDelegate = { BBImageDownloadSessionDelegate(downloader: self) }()
    private lazy var session: URLSession = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 1
        return URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: queue)
    }()
    
    public init(sessionConfiguration: URLSessionConfiguration) {
        donwloadTimeout = 15
        urlOperations = [:]
        operationLock = DispatchSemaphore(value: 1)
        downloadQueue = OperationQueue()
        downloadQueue.qualityOfService = .background
        downloadQueue.maxConcurrentOperationCount = 6
        self.sessionConfiguration = sessionConfiguration
    }
    
    fileprivate func operation(for url: URL) -> BBMergeRequestImageDownloadOperation? {
        operationLock.wait()
        let operation = urlOperations[url]
        operationLock.signal()
        return operation
    }
}

extension BBMergeRequestImageDownloader: BBImageDownloader {
    // Donwload
    @discardableResult
    public func downloadImage(with url: URL, completion: @escaping BBImageDownloaderCompletion) -> BBImageDownloadTask {
        let task = BBImageDefaultDownloadTask(url: url, completion: completion)
        operationLock.wait()
        var operation: BBMergeRequestImageDownloadOperation? = urlOperations[url]
        if operation == nil { // TODO: Check operation is finished
            let timeout = donwloadTimeout > 0 ? donwloadTimeout : 15
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout) // TODO: Networking parameters
            operation = BBMergeRequestImageDownloadOperation(request: request, session: session)
            operation?.completionBlock = { [weak self] in
                guard let self = self else { return }
                self.operationLock.wait()
                self.urlOperations.removeValue(forKey: url)
                self.operationLock.signal()
            }
            urlOperations[url] = operation
            downloadQueue.addOperation(operation!)
        }
        operationLock.signal()
        operation?.add(task: task)
        return task
    }
    
    // Cancel
    public func cancel(task: BBImageDownloadTask) {
        operationLock.wait()
        task.cancel()
        if let operation = urlOperations[task.url] {
            if operation.taskCount <= 1 {
                operation.cancel()
                urlOperations.removeValue(forKey: task.url)
            }
        }
        operationLock.signal()
    }
    
    public func cancel(url: URL) {
        operationLock.wait()
        if let operation = urlOperations[url] {
            operation.cancel()
            urlOperations.removeValue(forKey: url)
        }
        operationLock.signal()
    }
    
    public func cancelAll() {
        operationLock.wait()
        downloadQueue.cancelAllOperations()
        urlOperations.removeAll()
        operationLock.signal()
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
