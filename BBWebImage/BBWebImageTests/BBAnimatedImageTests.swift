//
//  BBAnimatedImageTests.swift
//  BBWebImageTests
//
//  Created by Kaibo Lu on 2/19/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import XCTest

class BBAnimatedImageTests: XCTestCase {
    var image: BBAnimatedImage!
    var imageData: Data {
        let url = Bundle(for: classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
        return try! Data(contentsOf: url)
    }
    
    override func setUp() {
        image = BBAnimatedImage(bb_data: imageData)
    }

    override func tearDown() {}

    func testFormat() {
        XCTAssertEqual(image.bb_imageFormat, .GIF)
    }
    
    func testFrameCount() {
        XCTAssertEqual(image.bb_frameCount, 44)
    }
    
    func testLoopCount() {
        XCTAssertEqual(image.bb_loopCount, 65535)
    }
    
    func testMaxCacheSize() {
        image.bb_maxCacheSize = 1024
        XCTAssertEqual(image.bb_maxCacheSize, 1024)
        
        image.bb_maxCacheSize = 0
        XCTAssertEqual(image.bb_maxCacheSize, 0)
        
        image.bb_maxCacheSize = -1
        XCTAssertGreaterThan(image.bb_maxCacheSize, 0)
    }
    
    func testCurrentCacheSize() {
        XCTAssertEqual(image.bb_currentCacheSize, image.bb_bytes)
    }
    
    func testOriginalImageData() {
        XCTAssertEqual(image.bb_originalImageData, imageData)
    }
    
    func testImageFrame() {
        for i in 0..<image.bb_frameCount {
            let cachedFrame = image.bb_imageFrame(at: i, decodeIfNeeded: false)
            if i == 0 {
                XCTAssertNotNil(cachedFrame)
            } else {
                XCTAssertNil(cachedFrame)
            }
            let decodedFrame = image.bb_imageFrame(at: i, decodeIfNeeded: true)
            XCTAssertNotNil(decodedFrame)
        }
    }
    
    func testDuration() {
        for i in 0..<image.bb_frameCount {
            let duration = image.bb_duration(at: i)
            XCTAssertEqual(duration, 0.09)
        }
    }
    
    func testPreloadImageFrame() {
        let expectation = self.expectation(description: "Wait for preloading images")
        image.bb_preloadImageFrame(fromIndex: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var count = self.image.bb_frameCount
            for i in 0..<self.image.bb_frameCount {
                let cachedFrame = self.image.bb_imageFrame(at: i, decodeIfNeeded: false)
                XCTAssertNotNil(cachedFrame)
                count -= 1
                if count == 0 { expectation.fulfill() }
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCancelPreloadTask() {
        let expectation = self.expectation(description: "Wait for preloading images")
        image.bb_preloadImageFrame(fromIndex: 0)
        image.bb_cancelPreloadTask()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var count = self.image.bb_frameCount
            for i in 0..<self.image.bb_frameCount {
                let cachedFrame = self.image.bb_imageFrame(at: i, decodeIfNeeded: false)
                if i == 0 {
                    XCTAssertNotNil(cachedFrame)
                } else {
                    XCTAssertNil(cachedFrame)
                }
                count -= 1
                if count == 0 { expectation.fulfill() }
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testPreloadAllImageFrames() {
        image.bb_preloadAllImageFrames()
        for i in 0..<image.bb_frameCount {
            let cachedFrame = image.bb_imageFrame(at: i, decodeIfNeeded: false)
            XCTAssertNotNil(cachedFrame)
        }
    }
    
    func testClear() {
        image.bb_preloadAllImageFrames()
        image.bb_clear()
        for i in 0..<image.bb_frameCount {
            let cachedFrame = image.bb_imageFrame(at: i, decodeIfNeeded: false)
            XCTAssertNil(cachedFrame)
        }
    }
    
    func testClearAsynchronously() {
        let expectation = self.expectation(description: "Wait for preloading images")
        image.bb_preloadAllImageFrames()
        image.bb_clearAsynchronously {
            for i in 0..<self.image.bb_frameCount {
                let cachedFrame = self.image.bb_imageFrame(at: i, decodeIfNeeded: false)
                XCTAssertNil(cachedFrame)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testEditor() {
        for i in 0..<image.bb_frameCount {
            let frame = image.bb_imageFrame(at: i, decodeIfNeeded: true)
            let size = frame?.size
            XCTAssertEqual(size, CGSize(width: 400, height: 400))
        }
        image.bb_editor = bb_imageEditorResize(with: CGSize(width: 200, height: 200))
        for i in 0..<image.bb_frameCount {
            let frame = image.bb_imageFrame(at: i, decodeIfNeeded: false)
            XCTAssertNil(frame)
        }
        for i in 0..<image.bb_frameCount {
            let frame = image.bb_imageFrame(at: i, decodeIfNeeded: true)
            let size = frame?.size
            XCTAssertEqual(size, CGSize(width: 200, height: 200))
        }
    }
}
