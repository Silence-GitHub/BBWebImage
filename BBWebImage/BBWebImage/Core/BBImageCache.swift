//
//  BBImageCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

struct BBImageCacheType: OptionSet {
    let rawValue: Int
    
    static let none = BBImageCacheType(rawValue: 1 << 0)
    static let memory = BBImageCacheType(rawValue: 1 << 1)
    static let disk = BBImageCacheType(rawValue: 1 << 2)
    
    static let all: BBImageCacheType = [.memory, .disk]
    
    var cached: Bool {
        return (self.rawValue & BBImageCacheType.memory.rawValue) != 0 || (self.rawValue & BBImageCacheType.disk.rawValue) != 0
    }
}

typealias BBImageCacheQueryCompletion = (UIImage?, BBImageCacheType) -> Void
typealias BBImageCacheStoreCompletion = () -> Void
typealias BBImageCacheRemoveCompletion = () -> Void

protocol BBImageCache {
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

extension BBImageCache {
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

class BBLRUImageCache: BBImageCache {
    // Get image
    func image(forKey key: String, cacheType: BBImageCacheType, completion: @escaping BBImageCacheQueryCompletion) {
        #warning ("Get image")
        completion(nil, .none)
    }
    
    // Store image
    func store(_ image: UIImage, forKey key: String, cacheType: BBImageCacheType, completion: BBImageCacheStoreCompletion?) {
        #warning ("Store image")
        if let completion = completion { completion() }
    }
    
    // Remove image
    func removeImage(forKey key: String, cacheType: BBImageCacheType, completion: BBImageCacheRemoveCompletion?) {
        #warning ("Remove image")
        if let completion = completion { completion() }
    }
}
