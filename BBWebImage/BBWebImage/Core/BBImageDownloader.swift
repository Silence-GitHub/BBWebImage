//
//  BBImageDownloader.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

typealias BBImageDownloaderCompletion = (Data?, Error?) -> Void

protocol BBImageDownloadTask {
    var url: URL { get }
    var isCancelled: Bool { get }
    var completion: BBImageDownloaderCompletion { get }
    
    func cancel()
}

protocol BBImageDownloader {
    // Donwload
    func downloadImage(with url: URL, completion: @escaping BBImageDownloaderCompletion) -> BBImageDownloadTask
    
    // Cancel
    func cancel(task: BBImageDownloadTask)
    func cancel(url: URL)
    func cancelAll()
}

class BBImageDefaultDownloadTask: BBImageDownloadTask {
    var imageUrl: URL
    var url: URL { return imageUrl }
    var cancelled: Bool
    var isCancelled: Bool { return cancelled }
    var completionHandler: BBImageDownloaderCompletion
    var completion: BBImageDownloaderCompletion { return completionHandler }
    
    init(url: URL, completion: @escaping BBImageDownloaderCompletion) {
        imageUrl = url
        cancelled = false
        completionHandler = completion
    }
    
    func cancel() { cancelled = false }
}

class BBMergeRequestImageDownloader: BBImageDownloader {
    var donwloadTimeout: TimeInterval
    private var urlOperations: [URL : BBMergeRequestImageDownloadOperation]
    private let operationLock: DispatchSemaphore
    private let downloadQueue: OperationQueue
    private let sessionDelegate: BBImageDownloadSessionDelegate
    private let session: URLSession
    
    init(sessionConfiguration: URLSessionConfiguration) {
        donwloadTimeout = 15
        urlOperations = [:]
        operationLock = DispatchSemaphore(value: 1)
        downloadQueue = OperationQueue() // TODO: Set download queue qualityOfService
        downloadQueue.maxConcurrentOperationCount = 6
        sessionDelegate = BBImageDownloadSessionDelegate()
        session = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil) // TODO: Create session delegate queue
    }
    
    // Donwload
    func downloadImage(with url: URL, completion: @escaping BBImageDownloaderCompletion) -> BBImageDownloadTask {
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
    func cancel(task: BBImageDownloadTask) {
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
    
    func cancel(url: URL) {
        operationLock.wait()
        if let operation = urlOperations[url] {
            operation.cancel()
            urlOperations.removeValue(forKey: url)
        }
        operationLock.signal()
    }
    
    func cancelAll() {
        operationLock.wait()
        downloadQueue.cancelAllOperations()
        urlOperations.removeAll()
        operationLock.signal()
    }
}

class BBImageDownloadSessionDelegate: NSObject, URLSessionDelegate {
    
}
