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
    public var bb_imageFormat: BBImageFormat? {
        get { return objc_getAssociatedObject(self, &imageFormatKey) as? BBImageFormat }
        set { objc_setAssociatedObject(self, &imageFormatKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    public var bb_imageEditKey: String? {
        get { return objc_getAssociatedObject(self, &imageEditKey) as? String }
        set { objc_setAssociatedObject(self, &imageEditKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    public var bb_bytes: Int64 { return Int64(size.width * size.height * scale) }
}

public extension CGImage {
    public var bb_containsAlpha: Bool { return !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast) }
    public var bb_cost: Int { return max(1, height * bytesPerRow) }
}
