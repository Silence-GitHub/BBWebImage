//
//  BBMergeRequestImageDownloaderTest.swift
//  BBWebImageTests
//
//  Created by Kaibo Lu on 2018/12/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import XCTest

class BBMergeRequestImageDownloaderTest: XCTestCase {
    var downloader: BBMergeRequestImageDownloader!
    var urls: [URL]!
    
    override func setUp() {
        downloader = BBMergeRequestImageDownloader(sessionConfiguration: .default)
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
}
