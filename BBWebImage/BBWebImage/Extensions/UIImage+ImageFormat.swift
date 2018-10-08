//
//  UIImage+ImageFormat.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/8.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

private var imageFormatKey: ()?

public extension UIImage {
    var bb_imageFormat: BBImageFormat? {
        get { return objc_getAssociatedObject(self, &imageFormatKey) as? BBImageFormat }
        set { objc_setAssociatedObject(self, &imageFormatKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
