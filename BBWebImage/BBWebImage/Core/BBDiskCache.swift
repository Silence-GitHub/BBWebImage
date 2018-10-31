//
//  BBDiskCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/29.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public class BBDiskCache {
    let storage: BBDiskStorage
    let sizeThreshold: Int
    let queue: DispatchQueue // Concurrent
    
    init?(path: String, sizeThreshold threshold: Int) {
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
    
    public func store(_ data: Data, forKey key: String, completion: @escaping () -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.store(data, forKey: key)
            completion()
        }
    }
}
