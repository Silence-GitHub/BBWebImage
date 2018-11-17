//
//  BBImageCoder.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public protocol BBImageCoder: AnyObject {
    func canDecode(imageData: Data) -> Bool
    func decode(imageData: Data) -> UIImage?
    func decompressedImage(withImage image: UIImage, data: Data) -> UIImage?
    func canEncode(_ format: BBImageFormat) -> Bool
    func encode(_ image: UIImage, toFormat format: BBImageFormat) -> Data?
}

public class BBImageCoderManager {
    public var coders: [BBImageCoder] {
        willSet { pthread_mutex_lock(&coderLock) }
        didSet { pthread_mutex_unlock(&coderLock) }
    }
    private var safeCoders: [BBImageCoder] {
        pthread_mutex_lock(&coderLock)
        let currentCoders = coders
        pthread_mutex_unlock(&coderLock)
        return currentCoders
    }
    private var coderLock: pthread_mutex_t
    
    init() {
        coders = [BBWebImageImageIOCoder()]
        coderLock = pthread_mutex_t()
        pthread_mutex_init(&coderLock, nil)
    }
}

extension BBImageCoderManager: BBImageCoder {
    public func canDecode(imageData: Data) -> Bool {
        let currentCoders = safeCoders
        for coder in currentCoders {
            if coder.canDecode(imageData: imageData) { return true }
        }
        return false
    }
    
    public func decode(imageData: Data) -> UIImage? {
        let currentCoders = safeCoders
        for coder in currentCoders where coder.canDecode(imageData: imageData) {
            return coder.decode(imageData: imageData)
        }
        return nil
    }
    
    public func decompressedImage(withImage image: UIImage, data: Data) -> UIImage? {
        let currentCoders = safeCoders
        for coder in currentCoders where coder.canDecode(imageData: data) {
            return coder.decompressedImage(withImage: image, data: data)
        }
        return nil
    }
    
    public func canEncode(_ format: BBImageFormat) -> Bool {
        let currentCoders = safeCoders
        for coder in currentCoders {
            if coder.canEncode(format) { return true }
        }
        return false
    }
    
    public func encode(_ image: UIImage, toFormat format: BBImageFormat) -> Data? {
        let currentCoders = safeCoders
        for coder in currentCoders where coder.canEncode(format) {
            return coder.encode(image, toFormat: format)
        }
        return nil
    }
}
