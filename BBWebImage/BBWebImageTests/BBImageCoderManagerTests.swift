//
//  BBImageCoderManagerTests.swift
//  BBWebImageTests
//
//  Created by Kaibo Lu on 2018/12/4.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import XCTest

class BBImageCoderManagerTests: XCTestCase {
    var coder: BBImageCoderManager!
    
    var pngData: Data {
        let url = Bundle(for: classForCoder).url(forResource: "placeholder", withExtension: "png")!
        return try! Data(contentsOf: url)
    }
    
    var jpgData: Data {
        let url = Bundle(for: classForCoder).url(forResource: "sunflower", withExtension: "jpg")!
        return try! Data(contentsOf: url)
    }
    
    override func setUp() {
        coder = BBImageCoderManager()
    }

    override func tearDown() {}

    func testCanDecode() {
        XCTAssertFalse(coder.canDecode(imageData: Data()))
        XCTAssertTrue(coder.canDecode(imageData: pngData))
        XCTAssertTrue(coder.canDecode(imageData: jpgData))
    }
    
    func testDecode() {
        XCTAssertNil(coder.decode(imageData: Data()))
        XCTAssertNotNil(coder.decode(imageData: pngData))
        XCTAssertNotNil(coder.decode(imageData: jpgData))
    }
    
    func testDecompress() {
        let pngData = self.pngData
        let pngImage = coder.decode(imageData: pngData)!
        let pngDecompressedImage = coder.decompressedImage(withImage: pngImage, data: pngData)
        XCTAssertNotNil(pngDecompressedImage)
        XCTAssertNotEqual(pngImage, pngDecompressedImage)
        
        let jpgData = self.jpgData
        let jpgImage = coder.decode(imageData: jpgData)!
        let jpgDecompressedImage = coder.decompressedImage(withImage: jpgImage, data: jpgData)
        XCTAssertNotNil(jpgDecompressedImage)
        XCTAssertNotEqual(jpgImage, jpgDecompressedImage)
    }
    
    func testCanEncode() {
        XCTAssertTrue(coder.canEncode(.unknown))
        XCTAssertTrue(coder.canEncode(.PNG))
        XCTAssertTrue(coder.canEncode(.JPEG))
    }
    
    func testEncode() {
        let images: [UIImage] = [coder.decode(imageData: pngData)!, coder.decode(imageData: jpgData)!]
        for image in images {
            XCTAssertNotNil(coder.encode(image, toFormat: .PNG))
            XCTAssertNotNil(coder.encode(image, toFormat: .JPEG))
            XCTAssertNotNil(coder.encode(image, toFormat: .unknown))
        }
    }
}
