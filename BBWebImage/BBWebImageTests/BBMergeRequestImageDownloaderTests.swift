//
//  BBMergeRequestImageDownloaderTests.swift
//  BBWebImageTests
//
//  Created by Kaibo Lu on 2018/12/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import XCTest

class BBMergeRequestImageDownloaderTests: XCTestCase {
    var downloader: BBMergeRequestImageDownloader!
    var urls: [URL]!
    
    lazy var imageCoder: BBImageCoder = {
        return BBImageCoderManager()
    }()
    
    override func setUp() {
        downloader = BBMergeRequestImageDownloader(sessionConfiguration: .default)
        downloader.imageCoder = imageCoder
        urls = []
        for i in 1...10 {
            urls.append(ImageURLProvider.originURL(forIndex: i)!)
        }
    }

    override func tearDown() {}

    func testDownloadImage() {
        let url = urls.first!
        let expectation = self.expectation(description: "Wait for downloading image")
        downloader.downloadImage(with: url, options: .none) { (data, error) in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testMergeRequest() {
        let url = urls.first!
        for _ in 0..<10 {
            let expectation = self.expectation(description: "Wait for downloading image")
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                expectation.fulfill()
            }
        }
        XCTAssertEqual(downloader.currentDownloadCount, 1)
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDownloadImages() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for downloading image")
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelTask() {
        let expectation = self.expectation(description: "Wait for downloading image")
        let url = urls.first!
        let task = downloader.downloadImage(with: url, options: .none) { (data, error) in
            XCTFail()
        }
        downloader.cancel(task: task)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.downloader.currentDownloadCount, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelTaskAndDownload() {
        let expectation = self.expectation(description: "Wait for downloading image")
        let url = urls.first!
        let task = downloader.downloadImage(with: url, options: .none) { (data, error) in
            XCTFail()
        }
        downloader.cancel(task: task)
        downloader.downloadImage(with: url, options: .none) { (data, error) in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelTaskAndDownloadRepeatedly() {
        let url = urls.first!
        for _ in 0..<10 {
            let task = downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTFail()
            }
            downloader.cancel(task: task)
        }
        let expectation = self.expectation(description: "Wait for downloading image")
        downloader.downloadImage(with: url, options: .none) { (data, error) in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelTaskAndDownloadRepeatedly2() {
        let url = urls.first!
        for _ in 0..<10 {
            let expectation = self.expectation(description: "Wait for downloading image")
            let task = downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTFail()
            }
            downloader.cancel(task: task)
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelTasks() {
        let expectation = self.expectation(description: "Wait for downloading image")
        var tasks: [BBImageDownloadTask] = []
        for url in urls {
            let task = downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTFail()
            }
            tasks.append(task)
        }
        for task in tasks {
            downloader.cancel(task: task)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.downloader.currentDownloadCount, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelTasksAndDownload() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for downloading image")
            let task = downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTFail()
            }
            downloader.cancel(task: task)
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelTasksAndDownloadRepeatedly() {
        for _ in 0..<10 {
            for url in urls {
                let expectation = self.expectation(description: "Wait for downloading image")
                let task = downloader.downloadImage(with: url, options: .none) { (data, error) in
                    XCTFail()
                }
                downloader.cancel(task: task)
                downloader.downloadImage(with: url, options: .none) { (data, error) in
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelSomeTasks() {
        var i = 0
        for url in urls {
            let shouldCancel = (i % 2 == 0)
            let expectation: XCTestExpectation? = shouldCancel ? nil : self.expectation(description: "Wait for downloading image")
            let task = downloader.downloadImage(with: url, options: .none) { (data, error) in
                if shouldCancel {
                    XCTFail()
                } else {
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    expectation!.fulfill()
                }
            }
            if shouldCancel {
                downloader.cancel(task: task)
            }
            i += 1
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelSomeTasksAndDownload() {
        var i = 0
        for url in urls {
            let shouldCancel = (i % 2 == 0)
            let expectation: XCTestExpectation? = shouldCancel ? nil : self.expectation(description: "Wait for downloading image")
            let task = downloader.downloadImage(with: url, options: .none) { (data, error) in
                if shouldCancel {
                    XCTFail()
                } else {
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    expectation!.fulfill()
                }
            }
            if shouldCancel {
                downloader.cancel(task: task)
                let expectation2 = self.expectation(description: "Wait for downloading image")
                downloader.downloadImage(with: url, options: .none) { (data, error) in
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    expectation2.fulfill()
                }
            }
            i += 1
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelUrl() {
        let expectation = self.expectation(description: "Wait for downloading image")
        let url = urls.first!
        downloader.downloadImage(with: url, options: .none) { (data, error) in
            XCTFail()
        }
        downloader.cancel(url: url)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.downloader.currentDownloadCount, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelUrl2() {
        let expectation = self.expectation(description: "Wait for downloading image")
        let url = urls.first!
        for _ in 0..<10 {
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTFail()
            }
        }
        downloader.cancel(url: url)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.downloader.currentDownloadCount, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelUrlAndDownload() {
        let expectation = self.expectation(description: "Wait for downloading image")
        let url = urls.first!
        downloader.downloadImage(with: url, options: .none) { (data, error) in
            XCTFail()
        }
        downloader.cancel(url: url)
        downloader.downloadImage(with: url, options: .none) { (data, error) in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelUrlAndDownloadRepeatedly() {
        let url = urls.first!
        for _ in 0..<10 {
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTFail()
            }
            downloader.cancel(url: url)
        }
        let expectation = self.expectation(description: "Wait for downloading image")
        downloader.downloadImage(with: url, options: .none) { (data, error) in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelUrls() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for downloading image")
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTFail()
            }
            downloader.cancel(url: url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertEqual(self.downloader.currentDownloadCount, 0)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelUrlsAndDownload() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for downloading image")
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTFail()
            }
            downloader.cancel(url: url)
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelSomeUrls() {
        var i = 0
        for url in urls {
            let shouldCancel = (i % 2 == 0)
            let expectation: XCTestExpectation? = shouldCancel ? nil : self.expectation(description: "Wait for downloading image")
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                if shouldCancel {
                    XCTFail()
                } else {
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    expectation!.fulfill()
                }
            }
            if shouldCancel {
                downloader.cancel(url: url)
            }
            i += 1
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelSomeUrlsAndDownload() {
        var i = 0
        for url in urls {
            let shouldCancel = (i % 2 == 0)
            let expectation: XCTestExpectation? = shouldCancel ? nil : self.expectation(description: "Wait for downloading image")
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                if shouldCancel {
                    XCTFail()
                } else {
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    expectation!.fulfill()
                }
            }
            if shouldCancel {
                downloader.cancel(url: url)
                let expectation2 = self.expectation(description: "Wait for downloading image")
                downloader.downloadImage(with: url, options: .none) { (data, error) in
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    expectation2.fulfill()
                }
            }
            i += 1
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelAll() {
        let expectation = self.expectation(description: "Wait for downloading image")
        for url in urls {
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTFail()
            }
        }
        downloader.cancelAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.downloader.currentDownloadCount, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelPreloading() {
        let expectation = self.expectation(description: "Wait for downloading image")
        for url in urls {
            downloader.downloadImage(with: url, options: .preload) { (data, error) in
                XCTFail()
            }
        }
        downloader.cancelPreloading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.downloader.currentPreloadTaskCount, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelPreloading2() {
        var count = urls.count
        for url in urls {
            let expectation = self.expectation(description: "Wait for downloading image")
            downloader.downloadImage(with: url, options: .preload) { (data, error) in
                XCTFail()
            }
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                count -= 1
                if count > 0 {
                    expectation.fulfill()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        XCTAssertEqual(self.downloader.currentPreloadTaskCount, 0)
                        expectation.fulfill()
                    }
                }
            }
        }
        downloader.cancelPreloading()
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelPreloading3() {
        var count = urls.count
        for url in urls {
            let expectation = self.expectation(description: "Wait for downloading image")
            downloader.downloadImage(with: url, options: .none) { (data, error) in
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                count -= 1
                if count > 0 {
                    expectation.fulfill()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        XCTAssertEqual(self.downloader.currentPreloadTaskCount, 0)
                        expectation.fulfill()
                    }
                }
            }
            downloader.downloadImage(with: url, options: .preload) { (data, error) in
                XCTFail()
            }
        }
        downloader.cancelPreloading()
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelPreloading4() {
        var i = 0
        var count = urls.count
        for url in urls {
            if i % 2 == 0 {
                let expectation = self.expectation(description: "Wait for downloading image")
                downloader.downloadImage(with: url, options: .none) { (data, error) in
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                    count -= 1
                    if count > 0 {
                        expectation.fulfill()
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            XCTAssertEqual(self.downloader.currentPreloadTaskCount, 0)
                            expectation.fulfill()
                        }
                    }
                }
            } else {
                count -= 1
                downloader.downloadImage(with: url, options: .preload) { (data, error) in
                    XCTFail()
                }
            }
            i += 1
        }
        downloader.cancelPreloading()
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCustomDownloadTask() {
        let expectation = self.expectation(description: "Wait for downloading image")
        downloader.generateDownloadTask = { TestImageDownloadTask(sentinel: 0, url: $0, progress: $1, completion: $2) }
        let url = urls.first!
        downloader.downloadImage(with: url) { (_, error) in
            XCTAssertEqual((error! as NSError).code, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCustomDownloadOperation() {
        let expectation = self.expectation(description: "Wait for downloading image")
        let fileUrl = Bundle(for: classForCoder).url(forResource: "mew_baseline", withExtension: "png")!
        let testImageData = try! Data(contentsOf: fileUrl)
        downloader.generateDownloadOperation = {
            let operation = TestImageDownloadOperation(request: $0, session: $1)
            operation.testImageData = testImageData
            return operation
        }
        let url = urls.first!
        downloader.downloadImage(with: url) { (data, _) in
            XCTAssertEqual(data, testImageData)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testProgressCallback() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for downloading image")
            
            let task = downloader.downloadImage(with: url, options: .none, progress: { (data, expectedSize, image) in
                XCTFail()
            }) { (data, error) in
                XCTFail()
            }
            downloader.cancel(task: task)
            
            let lock = DispatchSemaphore(value: 1)
            var finish = false
            downloader.downloadImage(with: url, options: .none, progress: { (data, expectedSize, image) in
                lock.wait()
                XCTAssertFalse(finish)
                lock.signal()
                if data == nil {
                    XCTAssertTrue(expectedSize > 0)
                } else {
                    XCTAssertTrue(data!.count <= expectedSize)
                }
                XCTAssertNil(image)
            }) { (data, error) in
                lock.wait()
                finish = true
                lock.signal()
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testProgressiveDownload() {
        for url in urls {
            let expectation = self.expectation(description: "Wait for downloading image")
            
            let task = downloader.downloadImage(with: url, options: .progressiveDownload, progress: { (data, expectedSize, image) in
                XCTFail()
            }) { (data, error) in
                XCTFail()
            }
            downloader.cancel(task: task)
            
            let lock = DispatchSemaphore(value: 1)
            var finish = false
            downloader.downloadImage(with: url, options: .progressiveDownload, progress: { (data, expectedSize, image) in
                lock.wait()
                XCTAssertFalse(finish)
                lock.signal()
                if data == nil {
                    XCTAssertTrue(expectedSize > 0)
                    XCTAssertNil(image)
                } else {
                    XCTAssertTrue(data!.count <= expectedSize)
                    if data!.count >= expectedSize / 2 {
                        XCTAssertNotNil(image)
                    }
                }
            }) { (data, error) in
                lock.wait()
                finish = true
                lock.signal()
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
