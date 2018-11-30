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
    public static func editorForCILookupTestFilter() -> BBWebImageEditor {
        let edit: BBWebImageEditMethod = { (image: UIImage?, data: Data?) in
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
            if let input = inputImage {
                let filter = BBCILookupTestFilter()
                filter.inputImage = input
                if let output = filter.outputImage,
                    let sourceImage = bb_shareCIContext.createCGImage(output, from: output.extent),
                    let cgimage = BBWebImageImageIOCoder.decompressedImage(sourceImage) {
                    // It cost more memory without decompressing
                    return UIImage(cgImage: cgimage)
                }
            }
            return image
        }
        return BBWebImageEditor(key: BBCILookupTestFilter.description(), needData: false, edit: edit)
    }
}
