//
//  UIButton+BBWebCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/9.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

extension UIButton: BBWebCache {
    public func bb_setImage(with url: URL,
                            forState state: UIControl.State,
                            placeholder: UIImage? = nil,
                            options: BBWebImageOptions = .none,
                            editor: BBWebImageEditor? = nil,
                            progress: BBImageDownloaderProgress? = nil,
                            completion: BBWebImageManagerCompletion? = nil) {
        let setImage: BBSetImage = { [weak self] (image) in
            if let self = self { self.setImage(image, for: state) }
        }
        bb_setImage(with: url,
                    placeholder: placeholder,
                    options: options,
                    editor: editor,
                    taskKey: imageLoadTaskKey(forState: state),
                    setImage: setImage,
                    progress: progress,
                    completion: completion)
    }
    
    public func bb_cancelImageLoadTask(forState state: UIControl.State) {
        let key = imageLoadTaskKey(forState: state)
        bb_webCacheOperation.task(forKey: key)?.cancel()
    }
    
    private func imageLoadTaskKey(forState state: UIControl.State) -> String {
        return classForCoder.description() + "Image\(state.rawValue)"
    }
    
    public func bb_setBackgroundImage(with url: URL,
                                      forState state: UIControl.State,
                                      placeholder: UIImage? = nil,
                                      options: BBWebImageOptions = .none,
                                      editor: BBWebImageEditor? = nil,
                                      progress: BBImageDownloaderProgress? = nil,
                                      completion: BBWebImageManagerCompletion? = nil) {
        let setImage: BBSetImage = { [weak self] (image) in
            if let self = self { self.setBackgroundImage(image, for: state) }
        }
        bb_setImage(with: url,
                    placeholder: placeholder,
                    options: options,
                    editor: editor,
                    taskKey: backgroundImageLoadTaskKey(forState: state),
                    setImage: setImage,
                    progress: progress,
                    completion: completion)
    }
    
    public func bb_cancelBackgroundImageLoadTask(forState state: UIControl.State) {
        let key = backgroundImageLoadTaskKey(forState: state)
        bb_webCacheOperation.task(forKey: key)?.cancel()
    }
    
    private func backgroundImageLoadTaskKey(forState state: UIControl.State) -> String {
        return classForCoder.description() + "BackgroundImage\(state.rawValue)"
    }
}
