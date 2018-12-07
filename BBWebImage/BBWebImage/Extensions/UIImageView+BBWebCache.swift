//
//  UIImageView+BBWebCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/9.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

extension UIImageView: BBWebCache {
    public func bb_setImage(_ image: UIImage?) {
        self.image = image
    }
    
    public func bb_cancelImageLoadTask() {
        // TODO: Cancel
    }
    
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
                    setImage: setImage,
                    progress: progress,
                    completion: completion)
    }
    
    public func bb_cancelHighlightedImageLoadTask() {
        // TODO: Cancel
    }
}
