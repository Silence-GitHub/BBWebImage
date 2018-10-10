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
            lock.wait()
            let t = _task
            lock.signal()
            return t
        }
        set {
            lock.wait()
            _task = newValue
            lock.signal()
        }
    }
    private let lock: DispatchSemaphore
    
    public init() {
        lock = DispatchSemaphore(value: 1)
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
