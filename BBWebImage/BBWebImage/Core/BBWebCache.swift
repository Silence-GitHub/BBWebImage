//
//  BBWebCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/12/7.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public typealias BBSetImage = (UIImage?) -> Void

private var webCacheOperationKey: Void?

public protocol BBWebCache: AnyObject {
    func bb_setImage(with url: URL,
                     placeholder: UIImage?,
                     options: BBWebImageOptions,
                     editor: BBWebImageEditor?,
                     setImage: BBSetImage?,
                     progress: BBImageDownloaderProgress?,
                     completion: BBWebImageManagerCompletion?)
    
    func bb_setImage(_ image: UIImage?)
}

public class BBWebCacheOperation {
    // TODO: Use weak value dic to find task with key
    private weak var _task: BBWebImageLoadTask?
    public var task: BBWebImageLoadTask? {
        get {
            pthread_mutex_lock(&lock)
            let t = _task
            pthread_mutex_unlock(&lock)
            return t
        }
        set {
            pthread_mutex_lock(&lock)
            _task = newValue
            pthread_mutex_unlock(&lock)
        }
    }
    
    private var _downloadProgress: Double
    public var downloadProgress: Double {
        get {
            pthread_mutex_lock(&lock)
            let d = _downloadProgress
            pthread_mutex_unlock(&lock)
            return d
        }
        set {
            pthread_mutex_lock(&lock)
            _downloadProgress = newValue
            pthread_mutex_unlock(&lock)
        }
    }
    
    private var lock: pthread_mutex_t
    
    public init() {
        _downloadProgress = 0
        lock = pthread_mutex_t()
        pthread_mutex_init(&lock, nil)
    }
}

public extension BBWebCache {
    public var bb_webCacheOperation: BBWebCacheOperation {
        if let operation = objc_getAssociatedObject(self, &webCacheOperationKey) as? BBWebCacheOperation { return operation }
        let operation = BBWebCacheOperation()
        objc_setAssociatedObject(self, &webCacheOperationKey, operation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return operation
    }
    
    func bb_setImage(with url: URL,
                     placeholder: UIImage? = nil,
                     options: BBWebImageOptions = .none,
                     editor: BBWebImageEditor? = nil,
                     setImage: BBSetImage? = nil,
                     progress: BBImageDownloaderProgress? = nil,
                     completion: BBWebImageManagerCompletion? = nil) {
        let webCacheOperation = bb_webCacheOperation
        webCacheOperation.task?.cancel()
        webCacheOperation.downloadProgress = 0
        if !options.contains(.ignorePlaceholder) {
            DispatchQueue.main.safeSync { [weak self] in
                guard let self = self else { return }
                self.bb_setImage(placeholder, setImage: setImage)
            }
        }
        var currentProgress = progress
        var sentinel: Int32 = 0
        if options.contains(.progressiveDownload) {
            currentProgress = { [weak self] (data, expectedSize, image) in
                guard let self = self else { return }
                guard let partialData = data,
                    expectedSize > 0,
                    let partialImage = image else {
                        progress?(data, expectedSize, nil)
                        return
                }
                var displayImage = partialImage
                if let currentEditor = editor,
                    let currentImage = currentEditor.edit(partialImage, partialData) {
                    currentImage.bb_imageEditKey = currentEditor.key
                    currentImage.bb_imageFormat = partialData.bb_imageFormat
                    displayImage = currentImage
                } else if !options.contains(.ignoreImageDecoding),
                    let currentImage = BBWebImageManager.shared.imageCoder.decompressedImage(withImage: partialImage, data: partialData) {
                    displayImage = currentImage
                }
                let downloadProgress = min(1, Double(partialData.count) / Double(expectedSize))
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let webCacheOperation = self.bb_webCacheOperation
                    guard let task = webCacheOperation.task,
                        task.sentinel == sentinel,
                        !task.isCancelled,
                        webCacheOperation.downloadProgress < downloadProgress else { return }
                    self.bb_setImage(displayImage, setImage: setImage)
                    webCacheOperation.downloadProgress = downloadProgress
                }
                if let userProgress = progress {
                    let webCacheOperation = self.bb_webCacheOperation
                    if let task = webCacheOperation.task,
                        task.sentinel == sentinel,
                        !task.isCancelled {
                        userProgress(partialData, expectedSize, displayImage)
                    }
                }
            }
        }
        let task = BBWebImageManager.shared.loadImage(with: url, options: options, editor: editor, progress: currentProgress) { [weak self] (image: UIImage?, data: Data?, error: Error?, cacheType: BBImageCacheType) in
            guard let self = self else { return }
            if let currentImage = image { self.bb_setImage(currentImage, setImage: setImage) }
            if error == nil { self.bb_webCacheOperation.downloadProgress = 1 }
            completion?(image, data, error, cacheType)
        }
        webCacheOperation.task = task
        sentinel = task.sentinel
    }
    
    private func bb_setImage(_ image: UIImage?, setImage: BBSetImage?) {
        if let currentSetImage = setImage {
            currentSetImage(image)
        } else {
            bb_setImage(image)
        }
    }
}
