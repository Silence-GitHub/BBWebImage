//
//  BBCILookupFilter.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/11/27.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public class BBCILookupFilter {
    private static var _kernel: CIKernel?
    
    private static var kernel: CIKernel? {
        var localKernel = _kernel // Use local var to prevent multithreading problem
        if localKernel == nil {
            localKernel = CIKernel(source: kernelString)
            _kernel = localKernel
        }
        return localKernel
    }
    
    private static var kernelString: String {
        let path = Bundle(for: self).path(forResource: "BBCILookup", ofType: "cikernel")!
        return try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
    }
    
    public static func clear() { _kernel = nil }
    
    public static func outputImage(withInputImage inputImage: CIImage, lookupTable: CIImage, intensity: CGFloat) -> CIImage? {
        return kernel?.apply(extent: inputImage.extent, roiCallback: { (index: Int32, destRect: CGRect) -> CGRect in
            if index == 0 { return destRect }
            return lookupTable.extent
        }, arguments: [inputImage, lookupTable, intensity])
    }
}
