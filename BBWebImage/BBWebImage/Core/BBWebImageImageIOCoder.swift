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
    
    public func canEncode(_ format: BBImageFormat) -> Bool {
        return true
    }
    
    public func encode(_ image: UIImage, toFormat format: BBImageFormat) -> Data? {
        guard let sourceImage = image.cgImage,
            let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else { return nil }
        var imageFormat = format
        if format == .unknown {
            imageFormat = sourceImage.bb_containsAlpha ? .PNG : .JPEG
        }
        if let destination = CGImageDestinationCreateWithData(data, imageFormat.UTType, 1, nil) {
            CGImageDestinationAddImage(destination, sourceImage, nil)
            if !CGImageDestinationFinalize(destination) {
                return nil
            }
            return data as Data
        }
        return nil
    }
}
