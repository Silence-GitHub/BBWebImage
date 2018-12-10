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
    var urls: [URL]!
    
    override func setUp() {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/com.Kaibo.BBWebImage.test"
        imageManager = BBWebImageManager(cachePath: path, sizeThreshold: 20 * 1024)
        urls = []
        for i in 1...10 {
            urls.append(ImageURLProvider.originURL(forIndex: i)!)
        }
    }

    override func tearDown() {
        let lock = DispatchSemaphore(value: 0)
        imageManager.imageCache.clear(.all) {
            lock.signal()
        }
        lock.wait()
    }

    func testShared() {
        XCTAssertTrue(BBWebImageManager.shared === BBWebImageManager.shared)
        XCTAssertTrue(BBWebImageManager.shared !== imageManager)
        
    }
    
    func testLoadImageFromNetwork() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = urls.first!
        let lock = DispatchSemaphore(value: 1)
        var finish = false
        imageManager.loadImage(with: url, progress: { (data, expectedSize, image) in
            lock.wait()
            XCTAssertFalse(finish)
            lock.signal()
            if data == nil {
                XCTAssertTrue(expectedSize > 0)
            } else {
                XCTAssertTrue(data!.count <= expectedSize)
            }
            XCTAssertNil(image)
            XCTAssertFalse(Thread.isMainThread)
        }) { (image, data, error, cacheType) in
            lock.wait()
            finish = true
            lock.signal()
            XCTAssertNotNil(image)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertTrue(cacheType == .none)
            XCTAssertTrue(Thread.isMainThread)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImagesFromNetwork() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            let lock = DispatchSemaphore(value: 1)
            var finish = false
            imageManager.loadImage(with: url, progress: { (data, expectedSize, image) in
                lock.wait()
                XCTAssertFalse(finish)
                lock.signal()
                if data == nil {
                    XCTAssertTrue(expectedSize > 0)
                } else {
                    XCTAssertTrue(data!.count <= expectedSize)
                }
                XCTAssertNil(image)
                XCTAssertFalse(Thread.isMainThread)
            }) { (image, data, error, cacheType) in
                lock.wait()
                finish = true
                lock.signal()
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImageFromMemory() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = urls.first!
        imageManager.loadImage(with: url) { (image, data, error, cacheType) in
            XCTAssertNotNil(image)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertTrue(cacheType == .none)
            XCTAssertTrue(Thread.isMainThread)
            var sentinel = false
            self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .memory)
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
                sentinel = true
            }
            XCTAssertTrue(sentinel)
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImagesFromMemory() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                var sentinel = false
                self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                    XCTAssertNotNil(image)
                    XCTAssertNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .memory)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
                    sentinel = true
                }
                XCTAssertTrue(sentinel)
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImageFromDisk() {
        let expectation = self.expectation(description: "Wait for loading image")
        let url = urls.first!
        imageManager.loadImage(with: url) { (image, data, error, cacheType) in
            XCTAssertNotNil(image)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertTrue(cacheType == .none)
            XCTAssertTrue(Thread.isMainThread)
            self.imageManager.imageCache.clear(.memory) {
                var sentinel = false
                self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                    XCTAssertNotNil(image)
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    XCTAssertTrue(cacheType == .disk)
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
                    sentinel = true
                }
                XCTAssertFalse(sentinel)
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoadImagesFromDisk() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for loading image")
            imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                XCTAssertNotNil(image)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                XCTAssertTrue(cacheType == .none)
                XCTAssertTrue(Thread.isMainThread)
                self.imageManager.imageCache.clear(.memory) {
                    var sentinel = false
                    self.imageManager.loadImage(with: url) { (image, data, error, cacheType) in
                        XCTAssertNotNil(image)
                        XCTAssertNotNil(data)
                        XCTAssertNil(error)
                        XCTAssertTrue(cacheType == .disk)
                        XCTAssertTrue(Thread.isMainThread)
                        expectation.fulfill()
                        sentinel = true
                    }
                    XCTAssertFalse(sentinel)
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
