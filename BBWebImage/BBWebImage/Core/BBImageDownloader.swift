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
    var isCancelled: Bool { get }
    var completion: BBImageDownloaderCompletion { get }
}

protocol BBImageDownloader {
    // Donwload
    func downloadImage(with url: URL, completion: @escaping BBImageDownloaderCompletion) -> BBImageDownloadTask
    
    // Cancel
    func cancel(task: BBImageDownloadTask)
    func cancel(url: URL)
    func cancelAll()
}

struct BBImageDefaultDownloadTask: BBImageDownloadTask {
    var cancelled: Bool
    var isCancelled: Bool { return cancelled }
    var completionHandler: BBImageDownloaderCompletion
    var completion: BBImageDownloaderCompletion { return completionHandler }
}

class BBMergeRequestImageDownloader: BBImageDownloader {
    // Donwload
    func downloadImage(with url: URL, completion: @escaping BBImageDownloaderCompletion) -> BBImageDownloadTask {
        #warning ("Download image")
        return BBImageDefaultDownloadTask(cancelled: false, completionHandler: completion)
    }
    
    // Cancel
    func cancel(task: BBImageDownloadTask) {
        #warning ("Cancel download task")
    }
    
    func cancel(url: URL) {
        #warning ("Cancel download url")
    }
    
    func cancelAll() {
        #warning ("Cancel download all")
    }
}
