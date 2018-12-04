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
    
    func testCancelAndDownload() {
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
}
