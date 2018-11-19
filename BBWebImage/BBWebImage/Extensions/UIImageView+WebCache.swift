//
//  UIImageView+WebCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/9.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public extension UIImageView {
    func bb_setImage(with url: URL, placeholder: UIImage? = nil, options: BBWebImageOptions = .none, editor: BBWebImageEditor? = nil, completion: BBWebImageManagerCompletion? = nil) {
        let webCacheOperation = bb_webCacheOperation
        webCacheOperation.task?.cancel()
        if !options.contains(.ignorePlaceholder) {
            DispatchQueue.main.safeSync { [weak self] in
                if let self = self { self.image = placeholder }
            }
        }
        webCacheOperation.task = BBWebImageManager.shared.loadImage(with: url, options: options, editor: editor) { [weak self] (image: UIImage?, data: Data?, error: Error?, cacheType: BBImageCacheType) in
            guard let self = self else { return }
            if let currentImage = image { self.image = currentImage }
            completion?(image, data, error, cacheType)
        }
    }
}
