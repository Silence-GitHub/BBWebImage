//
//  BBImageDownloadOperation.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public protocol BBImageDownloadOperation {
    var taskCount: Int { get }
    
    init(request: URLRequest, session: URLSession)
    func add(task: BBImageDownloadTask)
}

class BBMergeRequestImageDownloadOperation: Operation {
    var url: URL { return request.url! }
    private let request: URLRequest
    private let session: URLSession
    private var tasks: [BBImageDownloadTask]
    private var dataTask: URLSessionTask?
    private let taskLock: DispatchSemaphore
    private let stateLock: DispatchSemaphore
    private var imageData: Data?
    
    private var _executing: Bool
    override var isExecuting: Bool {
        get { return _executing }
        set {
            self.willChangeValue(forKey: "isExecuting")
            _executing = newValue
            self.willChangeValue(forKey: "isExecuting")
        }
    }
    
    private var _finished: Bool
    override var isFinished: Bool {
        get { return _finished }
        set {
            self.willChangeValue(forKey: "isFinished")
            _finished = newValue
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isAsynchronous: Bool { return true }
    
    required init(request: URLRequest, session: URLSession) {
        self.request = request
        self.session = session
        tasks = []
        taskLock = DispatchSemaphore(value: 1)
        stateLock = DispatchSemaphore(value: 1)
        _executing = false
        _finished = false
    }
    
    override func start() {
        stateLock.wait()
        defer { stateLock.signal() }
        if isCancelled {
            isFinished = true
            reset()
            // Completion call back will not be called when task is cancelled
            return
        }
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
        isExecuting = true
    }
    
    override func cancel() {
        stateLock.wait()
        defer { stateLock.signal() }
        if isFinished { return }
        super.cancel()
        if let task = dataTask {
            task.cancel()
            if _executing { isExecuting = false }
            if !_finished { isFinished = true }
        }
        reset()
    }
    
    private func done() {
        isFinished = true
        isExecuting = false
        reset()
    }
    
    private func reset() {
        taskLock.wait()
        tasks.removeAll()
        taskLock.signal()
        dataTask = nil
    }
}

extension BBMergeRequestImageDownloadOperation: BBImageDownloadOperation {
    var taskCount: Int {
        taskLock.wait()
        let count = tasks.count
        taskLock.signal()
        return count
    }
    
    func add(task: BBImageDownloadTask) {
        taskLock.wait()
        tasks.append(task)
        taskLock.signal()
    }
}

extension BBMergeRequestImageDownloadOperation: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            complete(withData: nil, error: error)
        } else {
            if let data = imageData {
                complete(withData: data, error: nil)
            } else {
                let noDataError = NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No image data"])
                complete(withData: nil, error: noDataError)
            }
        }
        stateLock.wait()
        done()
        stateLock.signal()
    }
    
    private func complete(withData data: Data?, error: Error?) {
        taskLock.wait()
        let currentTasks = tasks
        tasks.removeAll()
        taskLock.signal()
        for task in currentTasks {
            if !task.isCancelled { task.completion(data, error) }
        }
    }
}

extension BBMergeRequestImageDownloadOperation: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if imageData == nil { imageData = Data() }
        imageData?.append(data)
    }
}
