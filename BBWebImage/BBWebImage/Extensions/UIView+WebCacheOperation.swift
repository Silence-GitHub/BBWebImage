//
//  UIView+WebCacheOperation.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/9.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

private var webCacheOperationKey: Void?

public class BBWebCacheOperation {
    private weak var _task: BBWebImageLoadTask?
    public var task: BBWebImageLoadTask? {
        get {
            pthread_mutex_lock(&lock)
            let t = _task
            pthread_mutex_unlock(&lock)
            return t
        }
        set {
            pthread_mutex_lock(&lock)
            _task = newValue
            pthread_mutex_unlock(&lock)
        }
    }
    
    private var _downloadProgress: Double
    public var downloadProgress: Double {
        get {
            pthread_mutex_lock(&lock)
            let d = _downloadProgress
            pthread_mutex_unlock(&lock)
            return d
        }
        set {
            pthread_mutex_lock(&lock)
            _downloadProgress = newValue
            pthread_mutex_unlock(&lock)
        }
    }
    
    private var lock: pthread_mutex_t
    
    public init() {
        _downloadProgress = 0
        lock = pthread_mutex_t()
        pthread_mutex_init(&lock, nil)
    }
}

public extension UIView {
    public var bb_webCacheOperation: BBWebCacheOperation {
        if let operation = objc_getAssociatedObject(self, &webCacheOperationKey) as? BBWebCacheOperation { return operation }
        let operation = BBWebCacheOperation()
        objc_setAssociatedObject(self, &webCacheOperationKey, operation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return operation
    }
}
