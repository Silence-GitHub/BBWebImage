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
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public var cached: Bool {
        return (self.rawValue & BBImageCacheType.memory.rawValue) != 0 || (self.rawValue & BBImageCacheType.disk.rawValue) != 0
    }
}

public typealias BBImageCacheQueryCompletion = (UIImage?, BBImageCacheType) -> Void
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
}

public extension BBImageCache {
    // Get image
    func image(forKey key: String, completion: @escaping BBImageCacheQueryCompletion) {
        self.image(forKey: key, cacheType: .all, completion: completion)
    }
    
    // Store image
    func store(_ image: UIImage, forKey key: String, completion: BBImageCacheStoreCompletion?) {
        self.store(image, forKey: key, cacheType: .all, completion: completion)
    }
    
    // Remove image
    func removeImage(forKey key: String, completion: BBImageCacheRemoveCompletion?) {
        self.removeImage(forKey: key, cacheType: .all, completion: completion)
    }
}

public class BBLRUImageCache: BBImageCache {
    // Get image
    public func image(forKey key: String, cacheType: BBImageCacheType, completion: @escaping BBImageCacheQueryCompletion) {
        #warning ("Get image")
        completion(nil, .none)
    }
    
    // Store image
    public func store(_ image: UIImage, forKey key: String, cacheType: BBImageCacheType, completion: BBImageCacheStoreCompletion?) {
        #warning ("Store image")
        if let completion = completion { completion() }
    }
    
    // Remove image
    public func removeImage(forKey key: String, cacheType: BBImageCacheType, completion: BBImageCacheRemoveCompletion?) {
        #warning ("Remove image")
        if let completion = completion { completion() }
    }
}
