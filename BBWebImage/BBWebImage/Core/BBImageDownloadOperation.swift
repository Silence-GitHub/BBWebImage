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
    private var tasks: [BBImageDownloadTask]
    private let lock: DispatchSemaphore
    
    required init(request: URLRequest, session: URLSession) {
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
