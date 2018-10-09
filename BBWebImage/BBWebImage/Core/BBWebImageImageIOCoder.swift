//
//  BBWebImageImageIOCoder.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/8.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public class BBWebImageImageIOCoder: BBImageCoder {

    public func canDecode(imageData: Data) -> Bool {
        switch imageData.bb_imageFormat {
        case .JPEG, .PNG:
            return true
        default:
            return false
        }
    }
    
    public func decode(imageData: Data) -> UIImage? {
        let image = UIImage(data: imageData)
        image?.bb_imageFormat = imageData.bb_imageFormat
        image?.bb_originalImageData = imageData
        return image
    }
}
