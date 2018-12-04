//
//  BBLRUImageCacheTest.swift
//  BBWebImageTests
//
//  Created by Kaibo Lu on 2018/12/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import XCTest

struct TestImageItem {
    let image: UIImage
    let data: Data
    let key: String
}

class BBLRUImageCacheTest: XCTestCase {

    var cache: BBLRUImageCache!
    var fileCache: BBLRUImageCache!
    var dbCache: BBLRUImageCache!
    var imageNames: [String]!
    
    var testImageItems: [TestImageItem] {
        var items: [TestImageItem] = []
        for name in imageNames {
            let url = Bundle(for: classForCoder).url(forResource: name, withExtension: nil)!
            let data = try! Data(contentsOf: url)
            let image = UIImage(data: data)!
            items.append(TestImageItem(image: image, data: data, key: name))
        }
        return items
    }
    
    override func setUp() {
        cache = BBLRUImageCache(path: "com.Kaibo.BBWebImage.cache.test", sizeThreshold: 20 * 1024)
        fileCache = BBLRUImageCache(path: "com.Kaibo.BBWebImage.fileCache.test", sizeThreshold: 0)
        dbCache = BBLRUImageCache(path: "com.Kaibo.BBWebImage.dbCache.test", sizeThreshold: .max)
        imageNames = ["placeholder.png", "sunflower.jpg"]
    }

    override func tearDown() {
        clearCaches([cache, fileCache, dbCache])
        cache = nil
        fileCache = nil
        dbCache = nil
    }
    
    func clearCaches(_ caches: [BBLRUImageCache]) {
        let lock = DispatchSemaphore(value: 0)
        for c in caches {
            c.clear(.all) {
                lock.signal()
            }
            lock.wait()
        }
    }
    
    func testDiskCacheNotNil() {
        XCTAssertNotNil(cache.diskCache)
        XCTAssertNotNil(fileCache.diskCache)
        XCTAssertNotNil(dbCache.diskCache)
    }

    func testStoreAndGetImage() {
        let item = testImageItems.first!
        let image = item.image
        let data = item.data
        let key = item.key
        let expectation = { () -> XCTestExpectation in
            return self.expectation(description: "Wait for storing and getting image")
        }
        let test = { (cache: BBLRUImageCache, expectation: XCTestExpectation) -> Void in
            cache.store(image, data: data, forKey: key, cacheType: .all) {
                cache.image(forKey: key, cacheType: .all) { (result) in
                    switch result {
                    case .all(image: let currentImage, data: let currentData):
                        XCTAssertEqual(image, currentImage)
                        XCTAssertEqual(data, currentData)
                        expectation.fulfill()
                    default:
                        break
                    }
                }
            }
        }
        test(cache, expectation())
        test(fileCache, expectation())
        test(dbCache, expectation())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStoreAndGetMemoryImage() {
        let item = testImageItems.first!
        let image = item.image
        let key = item.key
        let expectation = { () -> XCTestExpectation in
            return self.expectation(description: "Wait for storing and getting image")
        }
        let test = { (cache: BBLRUImageCache, expectation: XCTestExpectation) -> Void in
            cache.store(image, data: nil, forKey: key, cacheType: .memory) {
                cache.image(forKey: key, cacheType: .memory) { (result) in
                    switch result {
                    case .memory(image: let currentImage):
                        XCTAssertEqual(image, currentImage)
                        expectation.fulfill()
                    default:
                        break
                    }
                }
            }
        }
        test(cache, expectation())
        test(fileCache, expectation())
        test(dbCache, expectation())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStoreAndGetDiskImage() {
        let item = testImageItems.first!
        let data = item.data
        let key = item.key
        let expectation = { () -> XCTestExpectation in
            return self.expectation(description: "Wait for storing and getting image")
        }
        let test = { (cache: BBLRUImageCache, expectation: XCTestExpectation) -> Void in
            cache.store(nil, data: data, forKey: key, cacheType: .disk) {
                cache.image(forKey: key, cacheType: .disk) { (result) in
                    switch result {
                    case .disk(data: let currentData):
                        XCTAssertEqual(data, currentData)
                        expectation.fulfill()
                    default:
                        break
                    }
                }
            }
        }
        test(cache, expectation())
        test(fileCache, expectation())
        test(dbCache, expectation())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStoreAndGetImages() {
        let items = testImageItems
        let expectations = { () -> [XCTestExpectation] in
            var list: [XCTestExpectation] = []
            for _ in items {
                list.append(self.expectation(description: "Wait for storing and getting image"))
            }
            return list
        }
        let test = { (cache: BBLRUImageCache, expectations: [XCTestExpectation]) -> Void in
            let group = DispatchGroup()
            for i in 0..<items.count {
                let image = items[i].image
                let data = items[i].data
                let key = items[i].key
                group.enter()
                cache.store(image, data: data, forKey: key, cacheType: .all) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                for i in 0..<items.count {
                    let image = items[i].image
                    let data = items[i].data
                    let key = items[i].key
                    let expectation = expectations[i]
                    cache.image(forKey: key, cacheType: .all) { (result) in
                        switch result {
                        case .all(image: let currentImage, data: let currentData):
                            XCTAssertEqual(image, currentImage)
                            XCTAssertEqual(data, currentData)
                            expectation.fulfill()
                        default:
                            break
                        }
                    }
                }
            }
        }
        test(cache, expectations())
        test(fileCache, expectations())
        test(dbCache, expectations())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStoreAndGetMemoryImages() {
        let items = testImageItems
        let expectations = { () -> [XCTestExpectation] in
            var list: [XCTestExpectation] = []
            for _ in items {
                list.append(self.expectation(description: "Wait for storing and getting image"))
            }
            return list
        }
        let test = { (cache: BBLRUImageCache, expectations: [XCTestExpectation]) -> Void in
            let group = DispatchGroup()
            for i in 0..<items.count {
                let image = items[i].image
                let data = items[i].data
                let key = items[i].key
                group.enter()
                cache.store(image, data: data, forKey: key, cacheType: .memory) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                for i in 0..<items.count {
                    let image = items[i].image
                    let key = items[i].key
                    let expectation = expectations[i]
                    cache.image(forKey: key, cacheType: .memory) { (result) in
                        switch result {
                        case .memory(image: let currentImage):
                            XCTAssertEqual(image, currentImage)
                            expectation.fulfill()
                        default:
                            break
                        }
                    }
                }
            }
        }
        test(cache, expectations())
        test(fileCache, expectations())
        test(dbCache, expectations())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStoreAndGetDiskImages() {
        let items = testImageItems
        let expectations = { () -> [XCTestExpectation] in
            var list: [XCTestExpectation] = []
            for _ in items {
                list.append(self.expectation(description: "Wait for storing and getting image"))
            }
            return list
        }
        let test = { (cache: BBLRUImageCache, expectations: [XCTestExpectation]) -> Void in
            let group = DispatchGroup()
            for i in 0..<items.count {
                let image = items[i].image
                let data = items[i].data
                let key = items[i].key
                group.enter()
                cache.store(image, data: data, forKey: key, cacheType: .disk) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                for i in 0..<items.count {
                    let data = items[i].data
                    let key = items[i].key
                    let expectation = expectations[i]
                    cache.image(forKey: key, cacheType: .disk) { (result) in
                        switch result {
                        case .disk(data: let currentData):
                            XCTAssertEqual(data, currentData)
                            expectation.fulfill()
                        default:
                            break
                        }
                    }
                }
            }
        }
        test(cache, expectations())
        test(fileCache, expectations())
        test(dbCache, expectations())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveImage() {
        let item = testImageItems.first!
        let image = item.image
        let data = item.data
        let key = item.key
        let expectation = { () -> XCTestExpectation in
            return self.expectation(description: "Wait for removing image")
        }
        let test = { (cache: BBLRUImageCache, expectation: XCTestExpectation) -> Void in
            cache.store(image, data: data, forKey: key, cacheType: .all) {
                cache.removeImage(forKey: key, cacheType: .all) {
                    cache.image(forKey: key, cacheType: .all) { (result) in
                        switch result {
                        case .none:
                            expectation.fulfill()
                        default:
                            break
                        }
                    }
                }
            }
        }
        test(cache, expectation())
        test(fileCache, expectation())
        test(dbCache, expectation())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveMemoryImage() {
        let item = testImageItems.first!
        let image = item.image
        let data = item.data
        let key = item.key
        let expectation = { () -> XCTestExpectation in
            return self.expectation(description: "Wait for removing image")
        }
        let test = { (cache: BBLRUImageCache, expectation: XCTestExpectation) -> Void in
            cache.store(image, data: data, forKey: key, cacheType: .all) {
                cache.removeImage(forKey: key, cacheType: .memory) {
                    cache.image(forKey: key, cacheType: .all) { (result) in
                        switch result {
                        case .disk(data: let currentData):
                            XCTAssertEqual(data, currentData)
                            expectation.fulfill()
                        default:
                            break
                        }
                    }
                }
            }
        }
        test(cache, expectation())
        test(fileCache, expectation())
        test(dbCache, expectation())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveDiskImage() {
        let item = testImageItems.first!
        let image = item.image
        let data = item.data
        let key = item.key
        let expectation = { () -> XCTestExpectation in
            return self.expectation(description: "Wait for removing image")
        }
        let test = { (cache: BBLRUImageCache, expectation: XCTestExpectation) -> Void in
            cache.store(image, data: data, forKey: key, cacheType: .all) {
                cache.removeImage(forKey: key, cacheType: .disk) {
                    cache.image(forKey: key, cacheType: .all) { (result) in
                        switch result {
                        case .memory(image: let currentImage):
                            XCTAssertEqual(image, currentImage)
                            expectation.fulfill()
                        default:
                            break
                        }
                    }
                }
            }
        }
        test(cache, expectation())
        test(fileCache, expectation())
        test(dbCache, expectation())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveImages() {
        let items = testImageItems
        let expectations = { () -> [XCTestExpectation] in
            var list: [XCTestExpectation] = []
            for _ in items {
                list.append(self.expectation(description: "Wait for removing image"))
            }
            return list
        }
        let test = { (cache: BBLRUImageCache, expectations: [XCTestExpectation]) -> Void in
            let group = DispatchGroup()
            for i in 0..<items.count {
                let image = items[i].image
                let data = items[i].data
                let key = items[i].key
                group.enter()
                cache.store(image, data: data, forKey: key, cacheType: .all) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                for i in 0..<items.count {
                    let key = items[i].key
                    let expectation = expectations[i]
                    cache.removeImage(forKey: key, cacheType: .all) {
                        cache.image(forKey: key, cacheType: .all) { (result) in
                            switch result {
                            case .none:
                                expectation.fulfill()
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
        test(cache, expectations())
        test(fileCache, expectations())
        test(dbCache, expectations())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveMemoryImages() {
        let items = testImageItems
        let expectations = { () -> [XCTestExpectation] in
            var list: [XCTestExpectation] = []
            for _ in items {
                list.append(self.expectation(description: "Wait for removing image"))
            }
            return list
        }
        let test = { (cache: BBLRUImageCache, expectations: [XCTestExpectation]) -> Void in
            let group = DispatchGroup()
            for i in 0..<items.count {
                let image = items[i].image
                let data = items[i].data
                let key = items[i].key
                group.enter()
                cache.store(image, data: data, forKey: key, cacheType: .all) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                for i in 0..<items.count {
                    let data = items[i].data
                    let key = items[i].key
                    let expectation = expectations[i]
                    cache.removeImage(forKey: key, cacheType: .memory) {
                        cache.image(forKey: key, cacheType: .all) { (result) in
                            switch result {
                            case .disk(data: let currentData):
                                XCTAssertEqual(data, currentData)
                                expectation.fulfill()
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
        test(cache, expectations())
        test(fileCache, expectations())
        test(dbCache, expectations())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveDiskImages() {
        let items = testImageItems
        let expectations = { () -> [XCTestExpectation] in
            var list: [XCTestExpectation] = []
            for _ in items {
                list.append(self.expectation(description: "Wait for removing image"))
            }
            return list
        }
        let test = { (cache: BBLRUImageCache, expectations: [XCTestExpectation]) -> Void in
            let group = DispatchGroup()
            for i in 0..<items.count {
                let image = items[i].image
                let data = items[i].data
                let key = items[i].key
                group.enter()
                cache.store(image, data: data, forKey: key, cacheType: .all) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                for i in 0..<items.count {
                    let image = items[i].image
                    let key = items[i].key
                    let expectation = expectations[i]
                    cache.removeImage(forKey: key, cacheType: .disk) {
                        cache.image(forKey: key, cacheType: .all) { (result) in
                            switch result {
                            case .memory(image: let currentImage):
                                XCTAssertEqual(image, currentImage)
                                expectation.fulfill()
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
        test(cache, expectations())
        test(fileCache, expectations())
        test(dbCache, expectations())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testClearImages() {
        let items = testImageItems
        let expectations = { () -> [XCTestExpectation] in
            var list: [XCTestExpectation] = []
            for _ in items {
                list.append(self.expectation(description: "Wait for clearing image"))
            }
            return list
        }
        let test = { (cache: BBLRUImageCache, expectations: [XCTestExpectation]) -> Void in
            let group = DispatchGroup()
            for i in 0..<items.count {
                let image = items[i].image
                let data = items[i].data
                let key = items[i].key
                group.enter()
                cache.store(image, data: data, forKey: key, cacheType: .all) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                cache.clear(.all) {
                    for i in 0..<items.count {
                        let key = items[i].key
                        let expectation = expectations[i]
                        cache.image(forKey: key, cacheType: .all) { (result) in
                            switch result {
                            case .none:
                                expectation.fulfill()
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
        test(cache, expectations())
        test(fileCache, expectations())
        test(dbCache, expectations())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testClearMemoryImages() {
        let items = testImageItems
        let expectations = { () -> [XCTestExpectation] in
            var list: [XCTestExpectation] = []
            for _ in items {
                list.append(self.expectation(description: "Wait for clearing image"))
            }
            return list
        }
        let test = { (cache: BBLRUImageCache, expectations: [XCTestExpectation]) -> Void in
            let group = DispatchGroup()
            for i in 0..<items.count {
                let image = items[i].image
                let data = items[i].data
                let key = items[i].key
                group.enter()
                cache.store(image, data: data, forKey: key, cacheType: .all) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                cache.clear(.memory) {
                    for i in 0..<items.count {
                        let data = items[i].data
                        let key = items[i].key
                        let expectation = expectations[i]
                        cache.image(forKey: key, cacheType: .all) { (result) in
                            switch result {
                            case .disk(data: let currentData):
                                XCTAssertEqual(data, currentData)
                                expectation.fulfill()
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
        test(cache, expectations())
        test(fileCache, expectations())
        test(dbCache, expectations())
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testClearDiskImages() {
        let items = testImageItems
        let expectations = { () -> [XCTestExpectation] in
            var list: [XCTestExpectation] = []
            for _ in items {
                list.append(self.expectation(description: "Wait for clearing image"))
            }
            return list
        }
        let test = { (cache: BBLRUImageCache, expectations: [XCTestExpectation]) -> Void in
            let group = DispatchGroup()
            for i in 0..<items.count {
                let image = items[i].image
                let data = items[i].data
                let key = items[i].key
                group.enter()
                cache.store(image, data: data, forKey: key, cacheType: .all) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                cache.clear(.disk) {
                    for i in 0..<items.count {
                        let image = items[i].image
                        let key = items[i].key
                        let expectation = expectations[i]
                        cache.image(forKey: key, cacheType: .all) { (result) in
                            switch result {
                            case .memory(image: let currentImage):
                                XCTAssertEqual(image, currentImage)
                                expectation.fulfill()
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
        test(cache, expectations())
        test(fileCache, expectations())
        test(dbCache, expectations())
        waitForExpectations(timeout: 5, handler: nil)
    }
}
