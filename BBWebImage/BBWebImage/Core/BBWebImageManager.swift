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
    public private(set) var imageCoder: BBImageCoder
    private let coderQueue: DispatchQueue
    private var tasks: Set<BBWebImageLoadTask>
    private var taskSentinel: Int32
    private let taskLock: DispatchSemaphore
    
    public init() {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/com.Kaibo.BBWebImage"
        imageCache = BBLRUImageCache(path: path, sizeThreshold: 20 * 1024)
        imageDownloader = BBMergeRequestImageDownloader(sessionConfiguration: .default)
        imageCoder = BBImageCoderManager()
        coderQueue = DispatchQueue(label: "com.Kaibo.BBWebImage.ImageManager.Coder", qos: .userInitiated)
        tasks = Set()
        taskSentinel = 0
        taskLock = DispatchSemaphore(value: 1)
    }
    
    @discardableResult
    public func loadImage(with url: URL, editor: BBWebImageEditor? = nil, completion: @escaping BBWebImageManagerCompletion) -> BBWebImageLoadTask {
        let task = newLoadTask()
        taskLock.wait()
        tasks.insert(task)
        taskLock.signal()
        weak var wtask = task
        imageCache.image(forKey: url.absoluteString) { [weak self] (result: BBImageCachQueryCompletionResult) in
            guard let self = self, let task = wtask else { return }
            guard !task.isCancelled else {
                self.remove(loadTask: task)
                return
            }
            switch result {
            case .memory(image: let image):
                self.handle(memoryImage: image, forTask: task, url: url, editor: editor, completion: completion)
            case .disk(data: let data):
                self.handle(imageData: data, cacheType: .disk, forTask: task, url: url, editor: editor, completion: completion)
            default:
                weak var wtask = task
                task.downloadTask = self.imageDownloader.downloadImage(with: url) { [weak self] (data: Data?, error: Error?) in
                    guard let self = self, let task = wtask else { return }
                    guard !task.isCancelled else {
                        self.remove(loadTask: task)
                        return
                    }
                    if let currentData = data {
                        self.handle(imageData: currentData, cacheType: .none, forTask: task, url: url, editor: editor, completion: completion)
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
    
    private func handle(memoryImage image: UIImage,
                        forTask task: BBWebImageLoadTask,
                        url: URL,
                        editor: BBWebImageEditor?,
                        completion: @escaping BBWebImageManagerCompletion) {
        if let currentEditor = editor {
            if currentEditor.key == image.bb_imageEditKey {
                DispatchQueue.main.safeAsync { completion(image, nil, .memory) }
                self.remove(loadTask: task)
            } else {
                weak var wtask = task
                self.coderQueue.async { [weak self] in
                    guard let self = self, let task = wtask else { return }
                    guard !task.isCancelled else {
                        self.remove(loadTask: task)
                        return
                    }
                    if let currentImage = currentEditor.edit(image, image.bb_originalImageData) {
                        guard !task.isCancelled else {
                            self.remove(loadTask: task)
                            return
                        }
                        currentImage.bb_imageEditKey = currentEditor.key
                        currentImage.bb_originalImageData = image.bb_originalImageData
                        currentImage.bb_imageFormat = image.bb_imageFormat
                        DispatchQueue.main.async { completion(currentImage, nil, .memory) }
                    } else {
                        DispatchQueue.main.async { completion(nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No edited image"]), .none) }
                    }
                    self.remove(loadTask: task)
                }
            }
        } else {
            DispatchQueue.main.safeAsync { completion(image, nil, .memory) }
            self.remove(loadTask: task)
        }
    }
    
    private func handle(imageData data: Data,
                        cacheType: BBImageCacheType,
                        forTask task: BBWebImageLoadTask,
                        url: URL,
                        editor: BBWebImageEditor?,
                        completion: @escaping BBWebImageManagerCompletion) {
        weak var wtask = task
        self.coderQueue.async { [weak self] in
            guard let self = self, let task = wtask else { return }
            guard !task.isCancelled else {
                self.remove(loadTask: task)
                return
            }
            if let currentEditor = editor {
                if let image = currentEditor.edit(nil, data) {
                    guard !task.isCancelled else {
                        self.remove(loadTask: task)
                        return
                    }
                    image.bb_imageEditKey = currentEditor.key
                    image.bb_imageFormat = data.bb_imageFormat
                    image.bb_originalImageData = data
                    DispatchQueue.main.async { completion(image, nil, cacheType) }
                    let storeCacheType: BBImageCacheType = (cacheType == .disk ? .memory : .all)
                    self.imageCache.store(image, forKey: url.absoluteString, cacheType: storeCacheType, completion: nil)
                } else {
                    DispatchQueue.main.async { completion(nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No edited image"]), .none) }
                }
            } else if let image = self.imageCoder.decode(imageData: data) {
                DispatchQueue.main.async { completion(image, nil, cacheType) }
                let storeCacheType: BBImageCacheType = (cacheType == .disk ? .memory : .all)
                self.imageCache.store(image, forKey: url.absoluteString, cacheType: storeCacheType, completion: nil)
            } else {
                DispatchQueue.main.async { completion(nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid image data"]), .none) }
            }
            self.remove(loadTask: task)
        }
    }
}
