//
//  BBImageCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public struct BBImageCacheType: OptionSet {
    public let rawValue: Int
    
    public static let none = BBImageCacheType(rawValue: 0)
    public static let memory = BBImageCacheType(rawValue: 1 << 0)
    public static let disk = BBImageCacheType(rawValue: 1 << 1)
    
    public static let all: BBImageCacheType = [.memory, .disk]
    
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    public var cached: Bool {
        return (rawValue & BBImageCacheType.memory.rawValue) != 0 || (rawValue & BBImageCacheType.disk.rawValue) != 0
    }
}

public enum BBImageCachQueryCompletionResult {
    case none
    case memory(image: UIImage)
    case disk(data: Data)
    case all(image: UIImage, data: Data)
}

public typealias BBImageCacheQueryCompletion = (BBImageCachQueryCompletionResult) -> Void
public typealias BBImageCacheStoreCompletion = () -> Void
public typealias BBImageCacheRemoveCompletion = () -> Void

public protocol BBImageCache: AnyObject {
    // Get image
    func image(forKey key: String, cacheType: BBImageCacheType, completion: @escaping BBImageCacheQueryCompletion)
    
    // Store image
    func store(_ image: UIImage?,
               data: Data?,
               forKey key: String,
               cacheType: BBImageCacheType,
               completion: BBImageCacheStoreCompletion?)
    
    // Remove image
    func removeImage(forKey key: String, cacheType: BBImageCacheType, completion: BBImageCacheRemoveCompletion?)
    
    // Clear image
    func clear(_ type: BBImageCacheType, completion: BBImageCacheRemoveCompletion?)
}

public class BBLRUImageCache: BBImageCache {
    public let memoryCache: BBMemoryCache
    public let diskCache: BBDiskCache?
    public weak var imageCoder: BBImageCoder?
    
    init(path: String, sizeThreshold: Int) {
        memoryCache = BBMemoryCache()
        diskCache = BBDiskCache(path: path, sizeThreshold: sizeThreshold)
    }
    
    // Get image
    public func image(forKey key: String, cacheType: BBImageCacheType, completion: @escaping BBImageCacheQueryCompletion) {
        var memoryImage: UIImage?
        if cacheType.contains(.memory),
            let image = memoryCache.image(forKey: key) {
            if cacheType == .all {
                memoryImage = image
            } else {
                return completion(.memory(image: image))
            }
        }
        if cacheType.contains(.disk),
            let currentDiskCache = diskCache {
            return currentDiskCache.data(forKey: key) { (data) in
                if let currentData = data {
                    if cacheType == .all,
                        let currentImage = memoryImage {
                        completion(.all(image: currentImage, data: currentData))
                    } else {
                        completion(.disk(data: currentData))
                    }
                } else if let currentImage = memoryImage {
                    // Cache type is all
                    completion(.memory(image: currentImage))
                } else {
                    completion(.none)
                }
            }
        }
        completion(.none)
    }
    
    // Store image
    public func store(_ image: UIImage?,
                      data: Data?,
                      forKey key: String,
                      cacheType: BBImageCacheType,
                      completion: BBImageCacheStoreCompletion?) {
        if cacheType.contains(.memory),
            let currentImage = image {
            memoryCache.store(currentImage, forKey: key, cost: currentImage.cgImage?.bb_cost ?? 1)
        }
        if cacheType.contains(.disk),
            let currentDiskCache = diskCache {
            if let currentData = data {
                return currentDiskCache.store(currentData, forKey: key, completion: completion)
            }
            return currentDiskCache.store({ [weak self] () -> Data? in
                guard let self = self else { return nil }
                if let currentImage = image,
                    let coder = self.imageCoder,
                    let data = coder.encodedData(with: currentImage, format: currentImage.bb_imageFormat ?? .unknown) {
                    return data
                }
                return nil
            }, forKey: key, completion: completion)
        }
        completion?()
    }
    
    // Remove image
    public func removeImage(forKey key: String, cacheType: BBImageCacheType, completion: BBImageCacheRemoveCompletion?) {
        if cacheType.contains(.memory) { memoryCache.removeImage(forKey: key) }
        if cacheType.contains(.disk),
            let currentDiskCache = diskCache {
            return currentDiskCache.removeData(forKey: key, completion: completion)
        }
        completion?()
    }
    
    // Clear image
    public func clear(_ type: BBImageCacheType, completion: BBImageCacheRemoveCompletion?) {
        if type.contains(.memory) { memoryCache.clear() }
        if type.contains(.disk),
            let currentDiskCache = diskCache {
            return currentDiskCache.clear(completion)
        }
        completion?()
    }
}
