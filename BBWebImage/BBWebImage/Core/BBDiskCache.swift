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
    private var costLimit: Int
    private var countLimit: Int
    private var ageLimit: TimeInterval
    
    public init?(path: String, sizeThreshold threshold: Int) {
        if let currentStorage = BBDiskStorage(path: path) {
            storage = currentStorage
        } else {
            return nil
        }
        sizeThreshold = threshold
        queue = DispatchQueue(label: "com.Kaibo.BBWebImage.DiskCache.queue", qos: .utility, attributes: .concurrent)
        costLimit = .max
        countLimit = .max
        ageLimit = .greatestFiniteMagnitude
        trimRecursively()
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
    
    public func clear() {
        storage.clear()
    }
    
    public func clear(_ completion: BBImageCacheRemoveCompletion?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.clear()
            completion?()
        }
    }
    
    private func trimRecursively() {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) { [weak self] in
            guard let self = self else { return }
            self.storage.trim(toCost: self.costLimit)
            self.storage.trim(toCount: self.countLimit)
            self.storage.trim(toAge: self.ageLimit)
        }
    }
}
