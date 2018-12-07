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
        let url = Bundle(for: classForCoder).url(forResource: "mew_baseline", withExtension: "png")!
        return try! Data(contentsOf: url)
    }
    
    var jpgData: Data {
        let url = Bundle(for: classForCoder).url(forResource: "mew_baseline", withExtension: "jpg")!
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
        
        let pngImage = coder.decode(imageData: pngData)
        XCTAssertNotNil(pngImage)
        XCTAssertEqual(pngImage?.bb_imageFormat, .PNG)
        
        let jpgImage = coder.decode(imageData: jpgData)
        XCTAssertNotNil(jpgImage)
        XCTAssertEqual(jpgImage?.bb_imageFormat, .JPEG)
    }
    
    func testDecompress() {
        let pngData = self.pngData
        let pngImage = coder.decode(imageData: pngData)!
        let pngDecompressedImage = coder.decompressedImage(withImage: pngImage, data: pngData)
        XCTAssertNotNil(pngDecompressedImage)
        XCTAssertNotEqual(pngImage, pngDecompressedImage)
        XCTAssertEqual(pngDecompressedImage?.bb_imageFormat, .PNG)
        
        let jpgData = self.jpgData
        let jpgImage = coder.decode(imageData: jpgData)!
        let jpgDecompressedImage = coder.decompressedImage(withImage: jpgImage, data: jpgData)
        XCTAssertNotNil(jpgDecompressedImage)
        XCTAssertNotEqual(jpgImage, jpgDecompressedImage)
        XCTAssertEqual(jpgDecompressedImage?.bb_imageFormat, .JPEG)
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
    
    func testCanIncrementallyDecode() {
        XCTAssertTrue(coder.canIncrementallyDecode(imageData: pngData))
        XCTAssertTrue(coder.canIncrementallyDecode(imageData: jpgData))
    }
    
    func testIncrementallyDecodedImage() {
        let test = { (data: Data, total: Int) -> Void in
            for i in 1...total {
                let finished = (i == total)
                let end = Int((Double(i) / Double(total)) * Double(data.count))
                let subdata = data.subdata(in: 0..<end)
                XCTAssertNotNil(self.coder.incrementallyDecodedImage(withData: subdata, finished: finished))
            }
        }
        test(pngData, 10)
        test(jpgData, 5) // Need enough data to decode
    }
}
