//
//  BBImageDownloadOperation.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

protocol BBImageDownloadOperation {
    var taskCount: Int { get }
    
    init(request: URLRequest, session: URLSession)
    func add(task: BBImageDownloadTask)
}

class BBMergeRequestImageDownloadOperation: Operation {
    var url: URL { return request.url! }
    private let request: URLRequest
    private let session: URLSession
    private var tasks: [BBImageDownloadTask]
    private let lock: DispatchSemaphore
    private var imageData: Data?
    
    required init(request: URLRequest, session: URLSession) {
        self.request = request
        self.session = session
        tasks = []
        lock = DispatchSemaphore(value: 1)
    }
}

extension BBMergeRequestImageDownloadOperation: BBImageDownloadOperation {
    var taskCount: Int {
        lock.wait()
        let count = tasks.count
        lock.signal()
        return count
    }
    
    func add(task: BBImageDownloadTask) {
        lock.wait()
        tasks.append(task)
        lock.signal()
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
    }
    
    private func complete(withData data: Data?, error: Error?) {
        lock.wait()
        let currentTasks = tasks
        tasks.removeAll()
        lock.signal()
        for task in currentTasks {
            task.completion(data, error)
        }
    }
}

extension BBMergeRequestImageDownloadOperation: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if imageData == nil { imageData = Data() }
        imageData?.append(data)
    }
}
