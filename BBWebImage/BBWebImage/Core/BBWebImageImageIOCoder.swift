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
        return image
    }
    
    public func decompressedImage(withImage image: UIImage, data: Data) -> UIImage? {
        guard let sourceImage = image.cgImage else { return image }
        let width = sourceImage.width
        let height = sourceImage.height
        var bitmapInfo = sourceImage.bitmapInfo
        bitmapInfo.remove(.alphaInfoMask)
        if sourceImage.bb_containsAlpha {
            bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        } else {
            bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        }
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: sourceImage.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: bb_shareColorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else { return image }
        context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        if let cgimage = context.makeImage() {
            let finalImage = UIImage(cgImage: cgimage, scale: image.scale, orientation: image.imageOrientation)
            finalImage.bb_imageFormat = image.bb_imageFormat
            return finalImage
        }
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
