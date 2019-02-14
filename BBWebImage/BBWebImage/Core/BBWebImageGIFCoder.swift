//
//  BBWebImageGIFCoder.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2/6/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

public class BBWebImageGIFCoder: BBAnimatedImageCoder {
    private var imageSource: CGImageSource?
    private var imageOrientation: UIImage.Orientation
    
    public var imageData: Data? {
        didSet {
            if let data = imageData {
                imageSource = CGImageSourceCreateWithData(data as CFData, nil)
                if let source = imageSource,
                    let properties = CGImageSourceCopyProperties(source, nil) as? [CFString : Any],
                    let rawValue = properties[kCGImagePropertyOrientation] as? UInt32,
                    let orientation = CGImagePropertyOrientation(rawValue: rawValue) {
                    imageOrientation = orientation.toUIImageOrientation
                }
            } else {
                imageSource = nil
            }
        }
    }
    
    public var frameCount: Int? {
        if let source = imageSource {
            let count = CGImageSourceGetCount(source)
            if count > 0 { return count }
        }
        return nil
    }
    
    public var loopCount: Int? {
        if let source = imageSource,
            let properties = CGImageSourceCopyProperties(source, nil) as? [CFString : Any],
            let gifInfo = properties[kCGImagePropertyGIFDictionary] as? [CFString : Any],
            let count = gifInfo[kCGImagePropertyGIFLoopCount] as? Int {
            return count
        }
        return nil
    }
    
    public init() {
        imageOrientation = .up
    }
    
    public func imageFrame(at index: Int, decompress: Bool) -> UIImage? {
        if let source = imageSource,
            let sourceImage = CGImageSourceCreateImageAtIndex(source, index, [kCGImageSourceShouldCache : true] as CFDictionary) {
            if decompress {
                if let cgimage = BBWebImageImageIOCoder.decompressedImage(sourceImage) {
                    return UIImage(cgImage: cgimage, scale: 1, orientation: imageOrientation)
                }
            } else {
                return UIImage(cgImage: sourceImage, scale: 1, orientation: imageOrientation)
            }
        }
        return nil
    }
    
    public func duration(at index: Int) -> TimeInterval? {
        if let source = imageSource,
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString : Any],
            let gifInfo = properties[kCGImagePropertyGIFDictionary] as? [CFString : Any] {
            var currentDuration: TimeInterval = -1
            if let d = gifInfo[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval {
                currentDuration = d
            } else if let d = gifInfo[kCGImagePropertyGIFDelayTime] as? TimeInterval {
                currentDuration = d
            }
            if currentDuration >= 0 {
                if currentDuration < 0.01 { currentDuration = 0.1 }
                return currentDuration
            }
        }
        return nil
    }
    
    public func imageFrameSize(at index: Int) -> CGSize? {
        if let source = imageSource,
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString : Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            width > 0,
            let height = properties[kCGImagePropertyPixelHeight] as? Int,
            height > 0 {
            return CGSize(width: width, height: height)
        }
        return nil
    }
}

extension BBWebImageGIFCoder: BBImageCoder {
    public func canDecode(_ data: Data) -> Bool {
        return data.bb_imageFormat == .GIF
    }
    
    public func decodedImage(with data: Data) -> UIImage? {
        let image = BBAnimatedImage(bb_data: data, decoder: copy() as? BBAnimatedImageCoder)
        image?.bb_imageFormat = data.bb_imageFormat
        return image
    }
    
    public func decompressedImage(with image: UIImage, data: Data) -> UIImage? {
        return nil
    }
    
    public func canEncode(_ format: BBImageFormat) -> Bool {
        return format == .GIF
    }
    
    public func encodedData(with image: UIImage, format: BBImageFormat) -> Data? {
        if let animatedImage = image as? BBAnimatedImage,
            animatedImage.bb_imageFormat == .GIF,
            format == .GIF {
            return animatedImage.bb_originalImageData
        }
        // TODO: Encode gif
        return nil
    }
    
    public func copy() -> BBImageCoder {
        return BBWebImageGIFCoder()
    }
}
