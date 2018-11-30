//
//  BBCILookupTestFilter.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2018/11/29.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit
import BBWebImage

class BBCILookupTestFilter: BBCILookupFilter {
    private static var _sharedLookupTable: CIImage?
    private static var sharedLookupTable: CIImage? {
        var localLookupTable = _sharedLookupTable
        if localLookupTable == nil {
            let url = Bundle.main.url(forResource: "test_lookup", withExtension: "png")!
            localLookupTable = CIImage(contentsOf: url)
            _sharedLookupTable = localLookupTable
        }
        return localLookupTable
    }
    
    override static func clear() {
        _sharedLookupTable = nil
        super.clear()
    }
    
    override init() {
        super.init()
        lookupTable = BBCILookupTestFilter.sharedLookupTable
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BBWebImageEditor {
    // The higher maxTileSize, the less memory cost, the longer processing time
    public static func editorForCILookupTestFilter(maxTileSize: Int = 0) -> BBWebImageEditor {
        let edit: BBWebImageEditMethod = { (image: UIImage?, data: Data?) in
            autoreleasepool { () -> UIImage? in
                var inputImage: CIImage?
                if let currentImage = image {
                    if let ciimage = currentImage.ciImage {
                        inputImage = ciimage
                    } else if let cgimage = currentImage.cgImage {
                        inputImage = CIImage(cgImage: cgimage)
                    } else {
                        inputImage = CIImage(image: currentImage)
                    }
                }
                guard let input = inputImage else { return image }
                let filter = BBCILookupTestFilter()
                if maxTileSize <= 0 {
                    filter.inputImage = input
                    if let output = filter.outputImage,
                        let sourceImage = bb_shareCIContext.createCGImage(output, from: output.extent),
                        let cgimage = BBWebImageImageIOCoder.decompressedImage(sourceImage) {
                        // It cost more memory without decompressing
                        return UIImage(cgImage: cgimage)
                    }
                    return image
                }
                // Split image into tiles, process tiles and combine
                let width = input.extent.width
                var height = max(1, floor(CGFloat(maxTileSize) / width))
                var y: CGFloat = 0
                var context: CGContext?
                while y < input.extent.height {
                    if y + height > input.extent.height {
                        height = input.extent.height - y
                    }
                    let success = autoreleasepool { () -> Bool in
                        filter.inputImage = input.cropped(to: CGRect(x: 0, y: y, width: width, height: height))
                        guard let output = filter.outputImage,
                            let cgimage = bb_shareCIContext.createCGImage(output, from: output.extent) else { return false }
                        if context == nil {
                            var bitmapInfo = cgimage.bitmapInfo
                            bitmapInfo.remove(.alphaInfoMask)
                            if cgimage.bb_containsAlpha {
                                bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
                            } else {
                                bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
                            }
                            context = CGContext(data: nil,
                                                width: Int(width),
                                                height: Int(input.extent.height),
                                                bitsPerComponent: cgimage.bitsPerComponent,
                                                bytesPerRow: 0,
                                                space: bb_shareColorSpace,
                                                bitmapInfo: bitmapInfo.rawValue)
                            if (context == nil) { return false }
                        }
                        context?.draw(cgimage, in: CGRect(x: 0, y: y, width: width, height: height))
                        return true
                    }
                    if !success { return image }
                    y += height
                }
                return context?.makeImage().flatMap { UIImage(cgImage: $0) } ?? image
            }
        }
        return BBWebImageEditor(key: BBCILookupTestFilter.description(), needData: false, edit: edit)
    }
}
