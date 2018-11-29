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
