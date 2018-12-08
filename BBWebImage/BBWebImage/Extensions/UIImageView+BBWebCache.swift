//
//  UIImageView+BBWebCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/9.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

extension UIImageView: BBWebCache {
    public func bb_setImage(with resource: BBWebCacheResource,
                            placeholder: UIImage? = nil,
                            options: BBWebImageOptions = .none,
                            editor: BBWebImageEditor? = nil,
                            progress: BBImageDownloaderProgress? = nil,
                            completion: BBWebImageManagerCompletion? = nil) {
        let setImage: BBSetImage = { [weak self] (image) in
            if let self = self { self.image = image }
        }
        bb_setImage(with: resource,
                    placeholder: placeholder,
                    options: options,
                    editor: editor,
                    taskKey: imageLoadTaskKey,
                    setImage: setImage,
                    progress: progress,
                    completion: completion)
    }
    
    public func bb_cancelImageLoadTask() {
        bb_webCacheOperation.task(forKey: imageLoadTaskKey)?.cancel()
    }
    
    public var imageLoadTaskKey: String { return classForCoder.description() }
    
    public func bb_setHighlightedImage(with resource: BBWebCacheResource,
                                       placeholder: UIImage? = nil,
                                       options: BBWebImageOptions = .none,
                                       editor: BBWebImageEditor? = nil,
                                       progress: BBImageDownloaderProgress? = nil,
                                       completion: BBWebImageManagerCompletion? = nil) {
        let setImage: BBSetImage = { [weak self] (image) in
            if let self = self { self.highlightedImage = image }
        }
        bb_setImage(with: resource,
                    placeholder: placeholder,
                    options: options,
                    editor: editor,
                    taskKey: highlightedImageLoadTaskKey,
                    setImage: setImage,
                    progress: progress,
                    completion: completion)
    }
    
    public func bb_cancelHighlightedImageLoadTask() {
        bb_webCacheOperation.task(forKey: highlightedImageLoadTaskKey)?.cancel()
    }
    
    public var highlightedImageLoadTaskKey: String { return classForCoder.description() + "Highlighted" }
}
