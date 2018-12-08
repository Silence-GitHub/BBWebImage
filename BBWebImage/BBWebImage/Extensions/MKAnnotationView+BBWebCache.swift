//
//  MKAnnotationView+BBWebCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/12/7.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit
import MapKit

extension MKAnnotationView: BBWebCache {
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
    
    public var imageLoadTaskKey: String { return classForCoder.description() }
}
