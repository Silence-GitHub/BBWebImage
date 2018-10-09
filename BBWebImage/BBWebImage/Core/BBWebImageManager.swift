//
//  BBWebImageManager.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public let BBWebImageErrorDomain: String = "BBWebImageErrorDomain"
public typealias BBWebImageManagerCompletion = (UIImage?, Error?, BBImageCacheType) -> Void

public class BBWebImageLoadTask {
    fileprivate let sentinel: Int32
    fileprivate var downloadTask: BBImageDownloadTask?
    fileprivate weak var imageManager: BBWebImageManager?
    public private(set) var isCancelled: Bool = false
    
    init(sentinel: Int32) { self.sentinel = sentinel }
    
    public func cancel() {
        isCancelled = true
        if let task = downloadTask,
            let downloader = imageManager?.imageDownloader {
            downloader.cancel(task: task)
        }
        imageManager?.remove(loadTask: self)
    }
}

extension BBWebImageLoadTask: Hashable {
    public static func == (lhs: BBWebImageLoadTask, rhs: BBWebImageLoadTask) -> Bool {
        return lhs.sentinel == rhs.sentinel
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sentinel)
    }
}

public class BBWebImageManager {
    public static let shared = BBWebImageManager()
    
    public private(set) var imageCache: BBImageCache
    public private(set) var imageDownloader: BBMergeRequestImageDownloader
    public private(set) var imageCoderManager: BBImageCoderManager
    private let coderQueue: DispatchQueue
    private var tasks: Set<BBWebImageLoadTask>
    private var taskSentinel: Int32
    private let taskLock: DispatchSemaphore
    
    public init() {
        imageCache = BBLRUImageCache()
        imageDownloader = BBMergeRequestImageDownloader(sessionConfiguration: .default)
        imageCoderManager = BBImageCoderManager()
        coderQueue = DispatchQueue(label: "com.Kaibo.BBWebImage.ImageManager.Coder", qos: .userInitiated)
        tasks = Set()
        taskSentinel = 0
        taskLock = DispatchSemaphore(value: 1)
    }
    
    @discardableResult
    public func loadImage(with url: URL, completion: @escaping BBWebImageManagerCompletion) -> BBWebImageLoadTask {
        let task = newLoadTask()
        taskLock.wait()
        tasks.insert(task)
        taskLock.signal()
        weak var wtask = task
        imageCache.image(forKey: url.absoluteString) { [weak self] (image: UIImage?, cacheType: BBImageCacheType) in
            guard let self = self, let task = wtask else { return }
            guard !task.isCancelled else {
                self.remove(loadTask: task)
                return
            }
            if let currentImage = image {
                DispatchQueue.main.safeAsync { completion(currentImage, nil, cacheType) }
                self.remove(loadTask: task)
            } else {
                weak var wtask = task
                task.downloadTask = self.imageDownloader.downloadImage(with: url) { [weak self] (data: Data?, error: Error?) in
                    guard let self = self, let task = wtask else { return }
                    guard !task.isCancelled else {
                        self.remove(loadTask: task)
                        return
                    }
                    if let currentData = data {
                        weak var wtask = task
                        self.coderQueue.async { [weak self] in
                            guard let self = self, let task = wtask else { return }
                            guard !task.isCancelled else {
                                self.remove(loadTask: task)
                                return
                            }
                            if let image = self.imageCoderManager.decode(imageData: currentData) {
                                if image.size.width > 0 && image.size.height > 0 {
                                    DispatchQueue.main.async { completion(image, nil, .none) }
                                } else {
                                    DispatchQueue.main.async { completion(nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Download image has 0 pixels"]), .none) }
                                }
                            } else {
                                DispatchQueue.main.async { completion(nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid image data"]), .none) }
                            }
                            self.remove(loadTask: task)
                        }
                    } else if let currentError = error {
                        DispatchQueue.main.async { completion(nil, currentError, .none) }
                        self.remove(loadTask: task)
                    }
                }
            }
        }
        return task
    }
    
    private func newLoadTask() -> BBWebImageLoadTask {
        let task = BBWebImageLoadTask(sentinel: OSAtomicIncrement32(&taskSentinel))
        task.imageManager = self
        return task
    }
    
    fileprivate func remove(loadTask: BBWebImageLoadTask) {
        taskLock.wait()
        tasks.remove(loadTask)
        taskLock.signal()
    }
}
