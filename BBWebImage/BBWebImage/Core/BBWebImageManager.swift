//
//  BBWebImageManager.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public struct BBWebImageOptions: OptionSet {
    public let rawValue: Int
    
    public static let none = BBWebImageOptions(rawValue: 0)
    public static let queryDataWhenInMemory = BBWebImageOptions(rawValue: 1 << 0)
    public static let refreshCache = BBWebImageOptions(rawValue: 1 << 1)
    public static let useURLCache = BBWebImageOptions(rawValue: 1 << 2)
    public static let handleCookies = BBWebImageOptions(rawValue: 1 << 3)
    public static let ignorePlaceholder = BBWebImageOptions(rawValue: 1 << 4)
    
    public init(rawValue: Int) { self.rawValue = rawValue }
}

public let BBWebImageErrorDomain: String = "BBWebImageErrorDomain"
public typealias BBWebImageManagerCompletion = (UIImage?, Data?, Error?, BBImageCacheType) -> Void

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
    public var shouldDecompressImage: Bool
    private let coderQueue: BBDispatchQueuePool
    private var tasks: Set<BBWebImageLoadTask>
    private var taskSentinel: Int32
    private var taskLock: pthread_mutex_t
    
    public init() {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/com.Kaibo.BBWebImage"
        let cache = BBLRUImageCache(path: path, sizeThreshold: 20 * 1024)
        imageCache = cache
        imageDownloader = BBMergeRequestImageDownloader(sessionConfiguration: .default)
        imageCoder = BBImageCoderManager()
        cache.imageCoder = imageCoder
        shouldDecompressImage = true
        coderQueue = BBDispatchQueuePool.userInitiated
        tasks = Set()
        taskSentinel = 0
        taskLock = pthread_mutex_t()
        pthread_mutex_init(&taskLock, nil)
    }
    
    @discardableResult
    public func loadImage(with url: URL, options: BBWebImageOptions = .none, editor: BBWebImageEditor? = nil, completion: @escaping BBWebImageManagerCompletion) -> BBWebImageLoadTask {
        let task = newLoadTask()
        pthread_mutex_lock(&taskLock)
        tasks.insert(task)
        pthread_mutex_unlock(&taskLock)
        
        if options.contains(.refreshCache) {
            downloadImage(with: url, task: task, editor: editor, completion: completion)
            return task
        }
        
        // Get memory image first
        var memoryImage: UIImage?
        imageCache.image(forKey: url.absoluteString, cacheType: .memory) { (result: BBImageCachQueryCompletionResult) in
            switch result {
            case .memory(image: let image):
                memoryImage = image
            default:
                break
            }
        }
        var finished = false
        if let currentImage = memoryImage,
            !options.contains(.queryDataWhenInMemory) {
            if let currentEditor = editor {
                if currentEditor.key == currentImage.bb_imageEditKey {
                    DispatchQueue.main.safeAsync { completion(currentImage, nil, nil, .memory) }
                    self.remove(loadTask: task)
                    finished = true
                } else if !currentEditor.needData {
                    coderQueue.async { [weak self, weak task] in
                        guard let self = self, let task = task else { return }
                        guard !task.isCancelled else {
                            self.remove(loadTask: task)
                            return
                        }
                        if let image = currentEditor.edit(currentImage, nil) {
                            guard !task.isCancelled else {
                                self.remove(loadTask: task)
                                return
                            }
                            image.bb_imageEditKey = currentEditor.key
                            image.bb_imageFormat = currentImage.bb_imageFormat
                            DispatchQueue.main.async { completion(image, nil, nil, .memory) }
                            self.imageCache.store(image, data: nil, forKey: url.absoluteString, cacheType: .memory, completion: nil)
                        } else {
                            DispatchQueue.main.async { completion(nil, nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No edited image"]), .none) }
                        }
                        self.remove(loadTask: task)
                    }
                    finished = true
                }
            } else if currentImage.bb_imageEditKey == nil {
                DispatchQueue.main.safeAsync { completion(currentImage, nil, nil, .memory) }
                self.remove(loadTask: task)
                finished = true
            }
        }
        if finished { return task }
        
        // Get disk data
        imageCache.image(forKey: url.absoluteString, cacheType: .disk) { [weak self, weak task] (result: BBImageCachQueryCompletionResult) in
            guard let self = self, let task = task else { return }
            guard !task.isCancelled else {
                self.remove(loadTask: task)
                return
            }
            switch result {
            case .disk(data: let data):
                self.handle(imageData: data, cacheType: (memoryImage != nil ? .all : .disk), forTask: task, url: url, editor: editor, completion: completion)
            case .none:
                // Download
                self.downloadImage(with: url, task: task, editor: editor, completion: completion)
            default:
                print("Error: illegal query disk data result")
                break
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
        pthread_mutex_lock(&taskLock)
        tasks.remove(loadTask)
        pthread_mutex_unlock(&taskLock)
    }
    
    private func handle(imageData data: Data,
                        cacheType: BBImageCacheType,
                        forTask task: BBWebImageLoadTask,
                        url: URL,
                        editor: BBWebImageEditor?,
                        completion: @escaping BBWebImageManagerCompletion) {
        self.coderQueue.async { [weak self, weak task] in
            guard let self = self, let task = task else { return }
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
                    DispatchQueue.main.async { completion(image, data, nil, cacheType) }
                    let storeCacheType: BBImageCacheType = (cacheType == .disk ? .memory : .all)
                    self.imageCache.store(image, data: data, forKey: url.absoluteString, cacheType: storeCacheType, completion: nil)
                } else {
                    DispatchQueue.main.async { completion(nil, nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No edited image"]), .none) }
                }
            } else if var image = self.imageCoder.decode(imageData: data) {
                if self.shouldDecompressImage,
                    let decompressedImage = self.imageCoder.decompressedImage(withImage: image, data: data) {
                    image = decompressedImage
                }
                DispatchQueue.main.async { completion(image, data, nil, cacheType) }
                let storeCacheType: BBImageCacheType = (cacheType == .disk ? .memory : .all)
                self.imageCache.store(image, data: data, forKey: url.absoluteString, cacheType: storeCacheType, completion: nil)
            } else {
                DispatchQueue.main.async { completion(nil, nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid image data"]), .none) }
            }
            self.remove(loadTask: task)
        }
    }
    
    private func downloadImage(with url: URL, task: BBWebImageLoadTask, editor: BBWebImageEditor?, completion: @escaping BBWebImageManagerCompletion) {
        task.downloadTask = self.imageDownloader.downloadImage(with: url) { [weak self, weak task] (data: Data?, error: Error?) in
            guard let self = self, let task = task else { return }
            guard !task.isCancelled else {
                self.remove(loadTask: task)
                return
            }
            if let currentData = data {
                self.handle(imageData: currentData, cacheType: .none, forTask: task, url: url, editor: editor, completion: completion)
            } else if let currentError = error {
                DispatchQueue.main.async { completion(nil, nil, currentError, .none) }
                self.remove(loadTask: task)
            }
        }
    }
}
