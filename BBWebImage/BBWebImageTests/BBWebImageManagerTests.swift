//
//  BBWebImageManagerTests.swift
//  BBWebImageTests
//
//  Created by Kaibo Lu on 2018/12/10.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import XCTest

class BBWebImageManagerTests: XCTestCase {
    var imageManager: BBWebImageManager!
    
    override func setUp() {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/com.Kaibo.BBWebImage.test"
        imageManager = BBWebImageManager(cachePath: path, sizeThreshold: 20 * 1024)
    }

    override func tearDown() {}

    func testShared() {
        XCTAssertTrue(BBWebImageManager.shared === BBWebImageManager.shared)
    }
}
