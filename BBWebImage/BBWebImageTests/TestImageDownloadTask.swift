//
//  TestImageDownloadTask.swift
//  BBWebImageTests
//
//  Created by Kaibo Lu on 1/28/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

class TestImageDownloadTask: BBImageDownloadTask {
    private(set) var sentinel: Int32
    private(set) var url: URL
    private(set) var isCancelled: Bool
    private(set) var progress: BBImageDownloaderProgress?
    private(set) var completion: BBImageDownloaderCompletion
    
    init(sentinel: Int32, url: URL, progress: BBImageDownloaderProgress?, completion: @escaping BBImageDownloaderCompletion) {
        self.sentinel = sentinel
        self.url = url
        self.isCancelled = false
        self.progress = progress
        self.completion = { (_, _) in
            completion(nil, NSError(domain: "TestError", code: 0, userInfo: nil))
        }
    }
    
    func cancel() { isCancelled = true }
}
