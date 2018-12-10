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
    public static let ignoreDiskCache = BBWebImageOptions(rawValue: 1 << 1)
    public static let refreshCache = BBWebImageOptions(rawValue: 1 << 2)
    public static let useURLCache = BBWebImageOptions(rawValue: 1 << 3)
    public static let handleCookies = BBWebImageOptions(rawValue: 1 << 4)
    public static let progressiveDownload = BBWebImageOptions(rawValue: 1 << 5)
    public static let ignorePlaceholder = BBWebImageOptions(rawValue: 1 << 6)
    public static let ignoreImageDecoding = BBWebImageOptions(rawValue: 1 << 7)
    
    public init(rawValue: Int) { self.rawValue = rawValue }
}

public let BBWebImageErrorDomain: String = "BBWebImageErrorDomain"
public typealias BBWebImageManagerCompletion = (UIImage?, Data?, Error?, BBImageCacheType) -> Void

public class BBWebImageLoadTask {
    public var isCancelled: Bool {
        pthread_mutex_lock(&lock)
        let c = cancelled
        pthread_mutex_unlock(&lock)
        return c
    }
    public let sentinel: Int32
    private var cancelled: Bool
    private var lock: pthread_mutex_t
    fileprivate var downloadTask: BBImageDownloadTask?
    fileprivate weak var imageManager: BBWebImageManager?
    
    init(sentinel: Int32) {
        self.sentinel = sentinel
        cancelled = false
        lock = pthread_mutex_t()
        pthread_mutex_init(&lock, nil)
    }
    
    public func cancel() {
        pthread_mutex_lock(&lock)
        if cancelled {
            pthread_mutex_unlock(&lock)
            return
        }
        cancelled = true
        pthread_mutex_unlock(&lock)
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

// If not subclass NSObject, there is memory leak (unknown reason)
public class BBWebImageManager: NSObject {
    public static let shared: BBWebImageManager = { () -> BBWebImageManager in
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/com.Kaibo.BBWebImage"
        return BBWebImageManager(cachePath: path, sizeThreshold: 20 * 1024)
    }()
    
    public private(set) var imageCache: BBImageCache
    public private(set) var imageDownloader: BBImageDownloader
    public private(set) var imageCoder: BBImageCoder
    private let coderQueue: BBDispatchQueuePool
    private var tasks: Set<BBWebImageLoadTask>
    private var taskLock: pthread_mutex_t
    private var taskSentinel: Int32
    
    public var currentTaskCount: Int {
        pthread_mutex_lock(&taskLock)
        let c = tasks.count
        pthread_mutex_unlock(&taskLock)
        return c
    }
    
    public init(cachePath: String, sizeThreshold: Int) {
        let cache = BBLRUImageCache(path: cachePath, sizeThreshold: sizeThreshold)
        imageCache = cache
        let downloader = BBMergeRequestImageDownloader(sessionConfiguration: .default)
        imageDownloader = downloader
        imageCoder = BBImageCoderManager()
        cache.imageCoder = imageCoder
        downloader.imageCoder = imageCoder
        coderQueue = BBDispatchQueuePool.userInitiated
        tasks = Set()
        taskSentinel = 0
        taskLock = pthread_mutex_t()
        pthread_mutex_init(&taskLock, nil)
    }
    
    @discardableResult
    public func loadImage(with resource: BBWebCacheResource,
                          options: BBWebImageOptions = .none,
                          editor: BBWebImageEditor? = nil,
                          progress: BBImageDownloaderProgress? = nil,
                          completion: @escaping BBWebImageManagerCompletion) -> BBWebImageLoadTask {
        let task = newLoadTask()
        pthread_mutex_lock(&taskLock)
        tasks.insert(task)
        pthread_mutex_unlock(&taskLock)
        
        if options.contains(.refreshCache) {
            downloadImage(with: resource,
                          options: options,
                          task: task,
                          editor: editor,
                          progress: progress,
                          completion: completion)
            return task
        }
        
        // Get memory image
        var memoryImage: UIImage?
        imageCache.image(forKey: resource.cacheKey, cacheType: .memory) { (result: BBImageCachQueryCompletionResult) in
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
                    complete(with: task,
                             completion: completion,
                             image: currentImage,
                             data: nil,
                             cacheType: .memory)
                    remove(loadTask: task)
                    finished = true
                } else if !currentEditor.needData {
                    coderQueue.async { [weak self, weak task] in
                        guard let self = self, let task = task, !task.isCancelled else { return }
                        if let image = currentEditor.edit(currentImage, nil) {
                            guard !task.isCancelled else { return }
                            image.bb_imageEditKey = currentEditor.key
                            image.bb_imageFormat = currentImage.bb_imageFormat
                            self.complete(with: task,
                                          completion: completion,
                                          image: image,
                                          data: nil,
                                          cacheType: .memory)
                            self.imageCache.store(image,
                                                  data: nil,
                                                  forKey: resource.cacheKey,
                                                  cacheType: .memory,
                                                  completion: nil)
                        } else {
                            self.complete(with: task, completion: completion, error: NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No edited image"]))
                        }
                        self.remove(loadTask: task)
                    }
                    finished = true
                }
            } else if currentImage.bb_imageEditKey == nil {
                complete(with: task,
                         completion: completion,
                         image: currentImage,
                         data: nil,
                         cacheType: .memory)
                remove(loadTask: task)
                finished = true
            }
        }
        if finished { return task }
        
        if options.contains(.ignoreDiskCache) {
            downloadImage(with: resource,
                          options: options,
                          task: task,
                          editor: editor,
                          progress: progress,
                          completion: completion)
        } else {
            // Get disk data
            imageCache.image(forKey: resource.cacheKey, cacheType: .disk) { [weak self, weak task] (result: BBImageCachQueryCompletionResult) in
                guard let self = self, let task = task, !task.isCancelled else { return }
                switch result {
                case .disk(data: let data):
                    self.handle(imageData: data,
                                options: options,
                                cacheType: (memoryImage != nil ? .all : .disk),
                                forTask: task,
                                resource: resource,
                                editor: editor,
                                completion: completion)
                case .none:
                    // Download
                    self.downloadImage(with: resource,
                                       options: options,
                                       task: task,
                                       editor: editor,
                                       progress: progress,
                                       completion: completion)
                default:
                    print("Error: illegal query disk data result")
                    break
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
        pthread_mutex_lock(&taskLock)
        tasks.remove(loadTask)
        pthread_mutex_unlock(&taskLock)
    }
    
    private func handle(imageData data: Data,
                        options: BBWebImageOptions,
                        cacheType: BBImageCacheType,
                        forTask task: BBWebImageLoadTask,
                        resource: BBWebCacheResource,
                        editor: BBWebImageEditor?,
                        completion: @escaping BBWebImageManagerCompletion) {
        self.coderQueue.async { [weak self, weak task] in
            guard let self = self, let task = task, !task.isCancelled else { return }
            if let currentEditor = editor {
                if currentEditor.needData {
                    if let image = currentEditor.edit(nil, data) {
                        guard !task.isCancelled else { return }
                        image.bb_imageEditKey = currentEditor.key
                        image.bb_imageFormat = data.bb_imageFormat
                        self.complete(with: task,
                                      completion: completion,
                                      image: image,
                                      data: data,
                                      cacheType: cacheType)
                        let storeCacheType: BBImageCacheType = (cacheType == .disk || options.contains(.ignoreDiskCache) ? .memory : .all)
                        self.imageCache.store(image,
                                              data: data,
                                              forKey: resource.cacheKey,
                                              cacheType: storeCacheType,
                                              completion: nil)
                    } else {
                        self.complete(with: task, completion: completion, error: NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No edited image"]))
                    }
                } else {
                    if let inputImage = self.imageCoder.decodedImage(with: data) {
                        if let image = currentEditor.edit(inputImage, nil) {
                            guard !task.isCancelled else { return }
                            image.bb_imageEditKey = currentEditor.key
                            image.bb_imageFormat = data.bb_imageFormat
                            self.complete(with: task,
                                          completion: completion,
                                          image: image,
                                          data: data,
                                          cacheType: cacheType)
                            let storeCacheType: BBImageCacheType = (cacheType == .disk || options.contains(.ignoreDiskCache) ? .memory : .all)
                            self.imageCache.store(image,
                                                  data: data,
                                                  forKey: resource.cacheKey,
                                                  cacheType: storeCacheType,
                                                  completion: nil)
                        } else {
                            self.complete(with: task, completion: completion, error: NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No edited image"]))
                        }
                    } else {
                        self.complete(with: task, completion: completion, error: NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid image data"]))
                    }
                }
            } else if var image = self.imageCoder.decodedImage(with: data) {
                if !options.contains(.ignoreImageDecoding),
                    let decompressedImage = self.imageCoder.decompressedImage(with: image, data: data) {
                    image = decompressedImage
                }
                self.complete(with: task,
                              completion: completion,
                              image: image,
                              data: data,
                              cacheType: cacheType)
                let storeCacheType: BBImageCacheType = (cacheType == .disk || options.contains(.ignoreDiskCache) ? .memory : .all)
                self.imageCache.store(image,
                                      data: data,
                                      forKey: resource.cacheKey,
                                      cacheType: storeCacheType,
                                      completion: nil)
            } else {
                self.complete(with: task, completion: completion, error: NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid image data"]))
            }
            self.remove(loadTask: task)
        }
    }
    
    private func downloadImage(with resource: BBWebCacheResource,
                               options: BBWebImageOptions,
                               task: BBWebImageLoadTask,
                               editor: BBWebImageEditor?,
                               progress: BBImageDownloaderProgress?,
                               completion: @escaping BBWebImageManagerCompletion) {
        task.downloadTask = self.imageDownloader.downloadImage(with: resource.downloadUrl, options: options, progress: progress) { [weak self, weak task] (data: Data?, error: Error?) in
            guard let self = self, let task = task, !task.isCancelled else { return }
            if let currentData = data {
                self.handle(imageData: currentData,
                            options: options,
                            cacheType: .none,
                            forTask: task,
                            resource: resource,
                            editor: editor,
                            completion: completion)
            } else if let currentError = error {
                self.complete(with: task, completion: completion, error: currentError)
                self.remove(loadTask: task)
            } else {
                print("Error: illegal result of download")
            }
        }
    }
    
    private func complete(with task: BBWebImageLoadTask,
                          completion: @escaping BBWebImageManagerCompletion,
                          image: UIImage?,
                          data: Data?,
                          cacheType: BBImageCacheType) {
        complete(with: task,
                 completion: completion,
                 image: image,
                 data: data,
                 error: nil,
                 cacheType: cacheType)
    }
    
    private func complete(with task: BBWebImageLoadTask, completion: @escaping BBWebImageManagerCompletion, error: Error) {
        complete(with: task,
                 completion: completion,
                 image: nil,
                 data: nil,
                 error: error,
                 cacheType: .none)
    }
    
    private func complete(with task: BBWebImageLoadTask,
                          completion: @escaping BBWebImageManagerCompletion,
                          image: UIImage?,
                          data: Data?,
                          error: Error?,
                          cacheType: BBImageCacheType) {
        DispatchQueue.main.safeAsync { [weak self] in
            guard self != nil, !task.isCancelled else { return }
            completion(image, data, error, cacheType)
        }
    }
}
