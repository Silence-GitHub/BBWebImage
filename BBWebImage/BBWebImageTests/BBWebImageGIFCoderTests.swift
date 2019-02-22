//
//  BBWebImageGIFCoderTests.swift
//  BBWebImageTests
//
//  Created by Kaibo Lu on 2/19/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import XCTest

class BBWebImageGIFCoderTests: XCTestCase {
    var coder: BBWebImageGIFCoder!
    
    var gifData: Data {
        let url = Bundle(for: classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
        return try! Data(contentsOf: url)
    }

    override func setUp() {
        coder = BBWebImageGIFCoder()
    }

    override func tearDown() {}

    func testCanDecode() {
        XCTAssertFalse(coder.canDecode(Data()))
        XCTAssertTrue(coder.canDecode(gifData))
    }
    
    func testDecode() {
        let test = { (gifImage: UIImage?) -> Void in
            XCTAssertNotNil(gifImage)
            XCTAssertEqual(gifImage?.bb_imageFormat, .GIF)
            XCTAssertTrue(gifImage is BBAnimatedImage)
        }
        test(coder.decodedImage(with: gifData))
        test(BBAnimatedImage(bb_data: gifData))
        test(BBAnimatedImage(bb_data: gifData, decoder: coder))
    }
    
    func testDecompress() {
        let gifData = self.gifData
        let gifImage = coder.decodedImage(with: gifData)!
        let gifDecompressedImage = coder.decompressedImage(with: gifImage, data: gifData)
        XCTAssertNil(gifDecompressedImage)
    }
    
    func testCanEncode() {
        XCTAssertFalse(coder.canEncode(.unknown))
        XCTAssertFalse(coder.canEncode(.PNG))
        XCTAssertFalse(coder.canEncode(.JPEG))
        XCTAssertTrue(coder.canEncode(.GIF))
    }
    
    func testEncode() {
        let test = { (image: UIImage) -> Void in
            XCTAssertNil(self.coder.encodedData(with: image, format: .unknown))
            XCTAssertNil(self.coder.encodedData(with: image, format: .PNG))
            XCTAssertNil(self.coder.encodedData(with: image, format: .JPEG))
            XCTAssertNotNil(self.coder.encodedData(with: image, format: .GIF))
        }
        
        let image = coder.decodedImage(with: gifData) as! BBAnimatedImage
        test(image)
        
        let jpgUrl = Bundle(for: classForCoder).url(forResource: "mew_baseline", withExtension: "jpg")!
        let jpgData = try! Data(contentsOf: jpgUrl)
        let jpgImage = UIImage(data: jpgData)!
        test(jpgImage)
        
        let pngUrl = Bundle(for: classForCoder).url(forResource: "mew_baseline", withExtension: "png")!
        let pngData = try! Data(contentsOf: pngUrl)
        let pngImage = UIImage(data: pngData)!
        test(pngImage)
        
        let images = UIImage.animatedImage(with: [jpgImage, pngImage], duration: 2)!
        test(images)
    }

    func testCopy() {
        XCTAssertFalse(coder === coder.copy())
    }
    
    func testImageData() {
        XCTAssertNil(coder.imageData)
        coder.imageData = gifData
        XCTAssertEqual(coder.imageData, gifData)
    }
    
    func testFrameCount() {
        coder.imageData = gifData
        XCTAssertEqual(coder.frameCount, 44)
    }
    
    func testLoopCount() {
        coder.imageData = gifData
        XCTAssertEqual(coder.loopCount, 65535)
    }
    
    func testImageFrame() {
        coder.imageData = gifData
        for i in 0..<coder.frameCount! {
            let frame = coder.imageFrame(at: i, decompress: false)
            let decompressedFrame = coder.imageFrame(at: i, decompress: true)
            XCTAssertNotNil(frame)
            XCTAssertNotNil(decompressedFrame)
            XCTAssertNotEqual(frame, decompressedFrame)
        }
    }
    
    func testImageFrameSize() {
        coder.imageData = gifData
        for i in 0..<coder.frameCount! {
            let size = coder.imageFrameSize(at: i)
            XCTAssertEqual(size, CGSize(width: 400, height: 400))
        }
    }
    
    func testDuration() {
        coder.imageData = gifData
        for i in 0..<coder.frameCount! {
            let duration = coder.duration(at: i)
            XCTAssertEqual(duration, 0.09)
        }
    }
}
