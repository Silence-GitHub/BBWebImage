//
//  UIImageView+BBWebCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/9.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

extension UIImageView: BBWebCache {
    public func bb_setImage(with url: URL,
                            placeholder: UIImage? = nil,
                            options: BBWebImageOptions = .none,
                            editor: BBWebImageEditor? = nil,
                            progress: BBImageDownloaderProgress? = nil,
                            completion: BBWebImageManagerCompletion? = nil) {
        let setImage: BBSetImage = { [weak self] (image) in
            if let self = self { self.image = image }
        }
        bb_setImage(with: url,
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
    
    private var imageLoadTaskKey: String { return classForCoder.description() }
    
    public func bb_setHighlightedImage(with url: URL,
                                       placeholder: UIImage? = nil,
                                       options: BBWebImageOptions = .none,
                                       editor: BBWebImageEditor? = nil,
                                       progress: BBImageDownloaderProgress? = nil,
                                       completion: BBWebImageManagerCompletion? = nil) {
        let setImage: BBSetImage = { [weak self] (image) in
            if let self = self { self.highlightedImage = image }
        }
        bb_setImage(with: url,
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
    
    private var highlightedImageLoadTaskKey: String { return classForCoder.description() + "Highlighted" }
}
