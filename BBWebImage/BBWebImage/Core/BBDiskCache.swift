//
//  BBDiskCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/29.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public class BBDiskCache {
    private let storage: BBDiskStorage
    private let sizeThreshold: Int
    private let queue: DispatchQueue // Concurrent
    
    public init?(path: String, sizeThreshold threshold: Int) {
        if let currentStorage = BBDiskStorage(path: path) {
            storage = currentStorage
        } else {
            return nil
        }
        sizeThreshold = threshold
        queue = DispatchQueue(label: "com.Kaibo.BBWebImage.DiskCache.queue", qos: .utility, attributes: .concurrent)
        // TODO: Trim by time, size, count
    }
    
    public func data(forKey key: String) -> Data? {
        return storage.data(forKey: key)
    }
    
    public func data(forKey key: String, completion: @escaping (Data?) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            completion(self.data(forKey: key))
        }
    }
    
    public func store(_ data: Data, forKey key: String) {
        storage.store(data, forKey: key, type: (data.count > sizeThreshold ? .file : .sqlite))
    }
    
    public func store(_ data: Data, forKey key: String, completion: BBImageCacheStoreCompletion?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.store(data, forKey: key)
            completion?()
        }
    }
    
    public func store(_ dataWork: @escaping () -> Data?, forKey key: String, completion: BBImageCacheStoreCompletion?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let data = dataWork() {
                self.store(data, forKey: key)
            }
            completion?()
        }
    }
    
    public func removeData(forKey key: String) {
        storage.removeData(forKey: key)
    }
    
    public func removeData(forKey key: String, completion: BBImageCacheRemoveCompletion?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.removeData(forKey: key)
            completion?()
        }
    }
}
