//
//  TestCacheVC.swift
//  CompareImageLib
//
//  Created by Kaibo Lu on 3/4/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit
import BBWebImage
import SDWebImage
import YYWebImage
import Kingfisher

private struct TestItem {
    let key: String
    let data: Data
    let image: UIImage
    
    init(key: String, data: Data) {
        self.key = key
        self.data = data
        let cgimage = BBWebImageImageIOCoder.decompressedImage(UIImage(data: data)!.cgImage!)!
        self.image = UIImage(cgImage: cgimage)
    }
}

class TestCacheVC: UIViewController {
    private var list: [(String, NoParamterBlock)]!
    private let testLoopCount = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let thumbnailItems = testItems(thumbnail: true)
        let items = testItems(thumbnail: false)
        list = [("Memory thumbnail BBWebImage", testMemoryCacheBB(with: thumbnailItems)),
                ("Memory thumbnail SDWebImage", testMemoryCacheSD(with: thumbnailItems)),
                ("Memory thumbnail YYWebImage", testMemoryCacheYY(with: thumbnailItems)),
                ("Memory thumbnail Kingfisher", testMemoryCacheKi(with: thumbnailItems)),
                ("Memory origin BBWebImage", testMemoryCacheBB(with: items)),
                ("Memory origin SDWebImage", testMemoryCacheSD(with: items)),
                ("Memory origin YYWebImage", testMemoryCacheYY(with: items)),
                ("Memory origin Kingfisher", testMemoryCacheKi(with: items))]
        
        let tableView = UITableView(frame: view.bounds)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.description())
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }
    
    private func testItems(thumbnail: Bool) -> [TestItem] {
        var list: [TestItem] = []
        for i in 1...100 {
            let key = thumbnail ? "test_\(i)_size_64" : "test_\(i)"
            let url = Bundle.main.url(forResource: key, withExtension: "jpg", subdirectory: "TestImages")!
            let data = try! Data(contentsOf: url)
            list.append(TestItem(key: key, data: data))
        }
        return list
    }
    
    private func testMemoryCacheBB(with testItems: [TestItem]) -> NoParamterBlock {
        return {
            var storeTime: Double = 0
            var getTime: Double = 0
            var removeTime: Double = 0
            for _ in 0..<self.testLoopCount {
                var startTime = CACurrentMediaTime()
                for item in testItems {
                    BBWebImageManager.shared.imageCache.store(item.image, data: nil, forKey: item.key, cacheType: .memory, completion: nil)
                }
                storeTime += CACurrentMediaTime() - startTime
                
                startTime = CACurrentMediaTime()
                for item in testItems {
                    BBWebImageManager.shared.imageCache.image(forKey: item.key, cacheType: .memory) { (result) in
                        switch result {
                        case .memory(image: _): break
                        default: assert(false)
                        }
                    }
                }
                getTime += CACurrentMediaTime() - startTime
                
                startTime = CACurrentMediaTime()
                for item in testItems {
                    BBWebImageManager.shared.imageCache.removeImage(forKey: item.key, cacheType: .memory, completion: nil)
                }
                removeTime += CACurrentMediaTime() - startTime
            }
            print(String(format: "BBWebImage time consume: store %0.4f, get %0.4f, remove %0.4f", storeTime, getTime, removeTime))
        }
    }
    
    private func testMemoryCacheSD(with testItems: [TestItem]) -> NoParamterBlock {
        return {
            var storeTime: Double = 0
            var getTime: Double = 0
            var removeTime: Double = 0
            for _ in 0..<self.testLoopCount {
                var startTime = CACurrentMediaTime()
                for item in testItems {
                    SDWebImageManager.shared().imageCache?.store(item.image, imageData: nil, forKey: item.key, toDisk: false, completion: nil)
                }
                storeTime += CACurrentMediaTime() - startTime
                
                startTime = CACurrentMediaTime()
                for item in testItems {
                    let image = SDWebImageManager.shared().imageCache?.imageFromMemoryCache(forKey: item.key)
                    assert(image != nil)
                }
                getTime += CACurrentMediaTime() - startTime
                
                startTime = CACurrentMediaTime()
                for item in testItems {
                    SDWebImageManager.shared().imageCache?.removeImage(forKey: item.key, fromDisk: false, withCompletion: nil)
                }
                removeTime += CACurrentMediaTime() - startTime
            }
            print(String(format: "SDWebImage time consume: store %0.4f, get %0.4f, remove %0.4f", storeTime, getTime, removeTime))
        }
    }
    
    private func testMemoryCacheYY(with testItems: [TestItem]) -> NoParamterBlock {
        return {
            for item in testItems {
                item.image.yy_isDecodedForDisplay = true
            }
            
            var storeTime: Double = 0
            var getTime: Double = 0
            var removeTime: Double = 0
            for _ in 0..<self.testLoopCount {
                var startTime = CACurrentMediaTime()
                for item in testItems {
                    YYWebImageManager.shared().cache?.setImage(item.image, imageData: nil, forKey: item.key, with: .memory)
                }
                storeTime += CACurrentMediaTime() - startTime
                
                startTime = CACurrentMediaTime()
                for item in testItems {
                    let image = YYWebImageManager.shared().cache?.getImageForKey(item.key, with: .memory)
                    assert(image != nil)
                }
                getTime += CACurrentMediaTime() - startTime
                
                startTime = CACurrentMediaTime()
                for item in testItems {
                    YYWebImageManager.shared().cache?.removeImage(forKey: item.key, with: .memory)
                }
                removeTime += CACurrentMediaTime() - startTime
            }
            print(String(format: "YYWebImage time consume: store %0.4f, get %0.4f, remove %0.4f", storeTime, getTime, removeTime))
        }
    }
    
    private func testMemoryCacheKi(with testItems: [TestItem]) -> NoParamterBlock {
        return {
            var storeTime: Double = 0
            var getTime: Double = 0
            var removeTime: Double = 0
            for _ in 0..<self.testLoopCount {
                var startTime = CACurrentMediaTime()
                for item in testItems {
                    KingfisherManager.shared.cache.store(item.image, original: nil, forKey: item.key, toDisk: false, completionHandler: nil)
                }
                storeTime += CACurrentMediaTime() - startTime
                
                startTime = CACurrentMediaTime()
                for item in testItems {
                    let image = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: item.key)
                    assert(image != nil)
                }
                getTime += CACurrentMediaTime() - startTime
                
                startTime = CACurrentMediaTime()
                for item in testItems {
                    KingfisherManager.shared.cache.removeImage(forKey: item.key, fromMemory: true, fromDisk: false, completionHandler: nil)
                }
                removeTime += CACurrentMediaTime() - startTime
            }
            print(String(format: "Kingfisher time consume: store %0.4f, get %0.4f, remove %0.4f", storeTime, getTime, removeTime))
        }
    }
}

extension TestCacheVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.description(), for: indexPath)
        cell.textLabel?.text = list[indexPath.row].0
        return cell
    }
}

extension TestCacheVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        list[indexPath.row].1()
    }
}
