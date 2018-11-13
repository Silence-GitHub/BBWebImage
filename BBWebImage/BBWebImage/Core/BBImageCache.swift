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
    
    public static let none = BBImageCacheType(rawValue: 1 << 0)
    public static let memory = BBImageCacheType(rawValue: 1 << 1)
    public static let disk = BBImageCacheType(rawValue: 1 << 2)
    
    public static let all: BBImageCacheType = [.memory, .disk]
    
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    public var cached: Bool {
        return (self.rawValue & BBImageCacheType.memory.rawValue) != 0 || (self.rawValue & BBImageCacheType.disk.rawValue) != 0
    }
}

public enum BBImageCachQueryCompletionResult {
    case none
    case memory(image: UIImage)
    case disk(data: Data)
}

public typealias BBImageCacheQueryCompletion = (BBImageCachQueryCompletionResult) -> Void
public typealias BBImageCacheStoreCompletion = () -> Void
public typealias BBImageCacheRemoveCompletion = () -> Void

public protocol BBImageCache {
    // Get image
    func image(forKey key: String, completion: @escaping BBImageCacheQueryCompletion)
    func image(forKey key: String, cacheType: BBImageCacheType, completion: @escaping BBImageCacheQueryCompletion)
    
    // Store image
    func store(_ image: UIImage, forKey key: String, completion: BBImageCacheStoreCompletion?)
    func store(_ image: UIImage, forKey key: String, cacheType: BBImageCacheType, completion: BBImageCacheStoreCompletion?)
    
    // Remove image
    func removeImage(forKey key: String, completion: BBImageCacheRemoveCompletion?)
    func removeImage(forKey key: String, cacheType: BBImageCacheType, completion: BBImageCacheRemoveCompletion?)
    
    // Clear image
    func clear(_ completion: BBImageCacheRemoveCompletion?)
    func clear(_ type: BBImageCacheType, completion: BBImageCacheRemoveCompletion?)
}

public extension BBImageCache {
    // Get image
    func image(forKey key: String, completion: @escaping BBImageCacheQueryCompletion) {
        image(forKey: key, cacheType: .all, completion: completion)
    }
    
    // Store image
    func store(_ image: UIImage, forKey key: String, completion: BBImageCacheStoreCompletion? = nil) {
        store(image, forKey: key, cacheType: .all, completion: completion)
    }
    
    // Remove image
    func removeImage(forKey key: String, completion: BBImageCacheRemoveCompletion? = nil) {
        removeImage(forKey: key, cacheType: .all, completion: completion)
    }
    
    // Clear image
    func clear(_ completion: BBImageCacheRemoveCompletion? = nil) {
        clear(.all, completion: completion)
    }
}

public class BBLRUImageCache: BBImageCache {
    public let memoryCache: BBMemoryCache
    public let diskCache: BBDiskCache?
    
    init(path: String, sizeThreshold: Int) {
        memoryCache = BBMemoryCache()
        diskCache = BBDiskCache(path: path, sizeThreshold: sizeThreshold)
    }
    
    // Get image
    public func image(forKey key: String, cacheType: BBImageCacheType, completion: @escaping BBImageCacheQueryCompletion) {
        if cacheType.contains(.memory),
            let image = memoryCache.image(forKey: key) {
            return completion(.memory(image: image))
        }
        if cacheType.contains(.disk),
            let currentDiskCache = diskCache {
            return currentDiskCache.data(forKey: key) { (data) in
                if let currentData = data {
                    completion(.disk(data: currentData))
                } else {
                    completion(.none)
                }
            }
        }
        completion(.none)
    }
    
    // Store image
    public func store(_ image: UIImage, forKey key: String, cacheType: BBImageCacheType, completion: BBImageCacheStoreCompletion?) {
        if cacheType.contains(.memory) { memoryCache.store(image, forKey: key) }
        if cacheType.contains(.disk),
            let currentDiskCache = diskCache {
            return currentDiskCache.store({ () -> Data? in
                if let data = image.bb_originalImageData { return data }
                // TODO: Encode image
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
    public func clear(_ type: BBImageCacheType, completion: BBImageCacheRemoveCompletion? = nil) {
        if type.contains(.memory) { memoryCache.clear() }
        if type.contains(.disk),
            let currentDiskCache = diskCache {
            return currentDiskCache.clear(completion)
        }
        completion?()
    }
}
