//
//  UIImageView+WebCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/9.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public extension UIImageView {
    func bb_setImage(with url: URL, placeholder: UIImage? = nil, options: BBWebImageOptions = .none, editor: BBWebImageEditor? = nil, progress: BBImageDownloaderProgress? = nil, completion: BBWebImageManagerCompletion? = nil) {
        let webCacheOperation = bb_webCacheOperation
        webCacheOperation.task?.cancel()
        webCacheOperation.downloadProgress = 0
        if !options.contains(.ignorePlaceholder) {
            DispatchQueue.main.safeSync { [weak self] in
                if let self = self { self.image = placeholder }
            }
        }
        var currentProgress = progress
        var sentinel: Int32 = 0
        if options.contains(.progressiveDownload) {
            currentProgress = { (data, expectedSize, image) in
                guard let partialData = data,
                    expectedSize > 0,
                    let partialImage = image else {
                    progress?(data, expectedSize, nil)
                    return
                }
                var displayImage = partialImage
                if let currentEditor = editor,
                    let currentImage = currentEditor.edit(partialImage, partialData) {
                    displayImage = currentImage
                } else if !options.contains(.ignoreImageDecoding),
                    let currentImage = BBWebImageManager.shared.imageCoder.decompressedImage(withImage: partialImage, data: partialData) {
                    displayImage = currentImage
                }
                let downloadProgress = min(1, Double(partialData.count) / Double(expectedSize))
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let self = self else { return }
                    let webCacheOperation = self.bb_webCacheOperation
                    if let task = webCacheOperation.task,
                        task.sentinel == sentinel,
                        !task.isCancelled,
                        webCacheOperation.downloadProgress < downloadProgress {
                        self.image = displayImage
                        webCacheOperation.downloadProgress = downloadProgress
                    }
                }
                progress?(data, expectedSize, displayImage)
            }
        }
        let task = BBWebImageManager.shared.loadImage(with: url, options: options, editor: editor, progress: currentProgress) { [weak self] (image: UIImage?, data: Data?, error: Error?, cacheType: BBImageCacheType) in
            guard let self = self else { return }
            if let currentImage = image { self.image = currentImage }
            if error == nil { self.bb_webCacheOperation.downloadProgress = 1 }
            completion?(image, data, error, cacheType)
        }
        webCacheOperation.task = task
        sentinel = task.sentinel
    }
}
