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
    private var cancelled: Bool
    private var lock: pthread_mutex_t
    fileprivate let sentinel: Int32
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
    public static let shared = BBWebImageManager()
    
    public private(set) var imageCache: BBImageCache
    public private(set) var imageDownloader: BBImageDownloader
    public private(set) var imageCoder: BBImageCoder
    private let coderQueue: BBDispatchQueuePool
    private var tasks: Set<BBWebImageLoadTask>
    private var taskSentinel: Int32
    private var taskLock: pthread_mutex_t
    
    public override init() {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/com.Kaibo.BBWebImage"
        let cache = BBLRUImageCache(path: path, sizeThreshold: 20 * 1024)
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
    public func loadImage(with url: URL, options: BBWebImageOptions = .none, editor: BBWebImageEditor? = nil, progress: BBImageDownloaderProgress? = nil, completion: @escaping BBWebImageManagerCompletion) -> BBWebImageLoadTask {
        let task = newLoadTask()
        pthread_mutex_lock(&taskLock)
        tasks.insert(task)
        pthread_mutex_unlock(&taskLock)
        
        if options.contains(.refreshCache) {
            downloadImage(with: url, options: options, task: task, editor: editor, progress: progress, completion: completion)
            return task
        }
        
        // Get memory image
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
                    remove(loadTask: task)
                    finished = true
                } else if !currentEditor.needData {
                    coderQueue.async { [weak self, weak task] in
                        guard let self = self, let task = task, !task.isCancelled else { return }
                        if let image = currentEditor.edit(currentImage, nil) {
                            guard !task.isCancelled else { return }
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
        
        if options.contains(.ignoreDiskCache) {
            downloadImage(with: url, options: options, task: task, editor: editor, progress: progress, completion: completion)
        } else {
            // Get disk data
            imageCache.image(forKey: url.absoluteString, cacheType: .disk) { [weak self, weak task] (result: BBImageCachQueryCompletionResult) in
                guard let self = self, let task = task, !task.isCancelled else { return }
                switch result {
                case .disk(data: let data):
                    self.handle(imageData: data, options: options, cacheType: (memoryImage != nil ? .all : .disk), forTask: task, url: url, editor: editor, completion: completion)
                case .none:
                    // Download
                    self.downloadImage(with: url, options: options, task: task, editor: editor, progress: progress, completion: completion)
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
                        url: URL,
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
                        DispatchQueue.main.async { completion(image, data, nil, cacheType) }
                        let storeCacheType: BBImageCacheType = (cacheType == .disk || options.contains(.ignoreDiskCache) ? .memory : .all)
                        self.imageCache.store(image, data: data, forKey: url.absoluteString, cacheType: storeCacheType, completion: nil)
                    } else {
                        DispatchQueue.main.async { completion(nil, nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No edited image"]), .none) }
                    }
                } else {
                    if let inputImage = self.imageCoder.decode(imageData: data) {
                        if let image = currentEditor.edit(inputImage, nil) {
                            guard !task.isCancelled else { return }
                            image.bb_imageEditKey = currentEditor.key
                            image.bb_imageFormat = data.bb_imageFormat
                            DispatchQueue.main.async { completion(image, data, nil, cacheType) }
                            let storeCacheType: BBImageCacheType = (cacheType == .disk || options.contains(.ignoreDiskCache) ? .memory : .all)
                            self.imageCache.store(image, data: data, forKey: url.absoluteString, cacheType: storeCacheType, completion: nil)
                        } else {
                            DispatchQueue.main.async { completion(nil, nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "No edited image"]), .none) }
                        }
                    } else {
                        DispatchQueue.main.async { completion(nil, nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid image data"]), .none) }
                    }
                }
            } else if var image = self.imageCoder.decode(imageData: data) {
                if !options.contains(.ignoreImageDecoding),
                    let decompressedImage = self.imageCoder.decompressedImage(withImage: image, data: data) {
                    image = decompressedImage
                }
                DispatchQueue.main.async { completion(image, data, nil, cacheType) }
                let storeCacheType: BBImageCacheType = (cacheType == .disk || options.contains(.ignoreDiskCache) ? .memory : .all)
                self.imageCache.store(image, data: data, forKey: url.absoluteString, cacheType: storeCacheType, completion: nil)
            } else {
                DispatchQueue.main.async { completion(nil, nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid image data"]), .none) }
            }
            self.remove(loadTask: task)
        }
    }
    
    private func downloadImage(with url: URL, options: BBWebImageOptions, task: BBWebImageLoadTask, editor: BBWebImageEditor?, progress: BBImageDownloaderProgress?, completion: @escaping BBWebImageManagerCompletion) {
        task.downloadTask = self.imageDownloader.downloadImage(with: url, options: options, progress: progress) { [weak self, weak task] (data: Data?, error: Error?) in
            guard let self = self, let task = task, !task.isCancelled else { return }
            if let currentData = data {
                self.handle(imageData: currentData, options: options, cacheType: .none, forTask: task, url: url, editor: editor, completion: completion)
            } else if let currentError = error {
                DispatchQueue.main.async { completion(nil, nil, currentError, .none) }
                self.remove(loadTask: task)
            } else {
                print("Error: illegal result of download")
            }
        }
    }
}
