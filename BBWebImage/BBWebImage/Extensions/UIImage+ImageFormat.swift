//
//  UIImage+ImageFormat.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/8.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

private var imageFormatKey: Void?
private var imageDataKey: Void?
private var imageEditKey: Void?

public extension UIImage {
    var bb_imageFormat: BBImageFormat? {
        get { return objc_getAssociatedObject(self, &imageFormatKey) as? BBImageFormat }
        set { objc_setAssociatedObject(self, &imageFormatKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var bb_originalImageData: Data? {
        get { return objc_getAssociatedObject(self, &imageDataKey) as? Data }
        set { objc_setAssociatedObject(self, &imageDataKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var bb_imageEditKey: String? {
        get { return objc_getAssociatedObject(self, &imageEditKey) as? String }
        set { objc_setAssociatedObject(self, &imageEditKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

public extension CGImage {
    var containsAlpha: Bool {
        return !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
    }
}
