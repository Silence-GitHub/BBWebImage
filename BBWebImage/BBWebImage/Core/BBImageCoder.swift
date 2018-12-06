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
    func copy() -> BBImageCoder
}

public protocol BBImageProgressiveCoder: BBImageCoder {
    func canIncrementallyDecode(imageData: Data) -> Bool
    func incrementallyDecodedImage(withData data: Data, finished: Bool) -> UIImage?
}

extension CGImagePropertyOrientation {
    var toUIImageOrientation: UIImage.Orientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .downMirrored
        default: return .up
        }
    }
}

public class BBImageCoderManager {
    public var coders: [BBImageCoder] {
        get {
            pthread_mutex_lock(&coderLock)
            let currentCoders = _coders
            pthread_mutex_unlock(&coderLock)
            return currentCoders
        }
        set {
            pthread_mutex_lock(&coderLock)
            _coders = newValue
            pthread_mutex_unlock(&coderLock)
        }
    }
    private var _coders: [BBImageCoder]
    private var coderLock: pthread_mutex_t
    
    init() {
        _coders = [BBWebImageImageIOCoder()]
        coderLock = pthread_mutex_t()
        pthread_mutex_init(&coderLock, nil)
    }
}

extension BBImageCoderManager: BBImageCoder {
    public func canDecode(imageData: Data) -> Bool {
        let currentCoders = coders
        for coder in currentCoders where coder.canDecode(imageData: imageData) {
            return true
        }
        return false
    }
    
    public func decode(imageData: Data) -> UIImage? {
        let currentCoders = coders
        for coder in currentCoders where coder.canDecode(imageData: imageData) {
            return coder.decode(imageData: imageData)
        }
        return nil
    }
    
    public func decompressedImage(withImage image: UIImage, data: Data) -> UIImage? {
        let currentCoders = coders
        for coder in currentCoders where coder.canDecode(imageData: data) {
            return coder.decompressedImage(withImage: image, data: data)
        }
        return nil
    }
    
    public func canEncode(_ format: BBImageFormat) -> Bool {
        let currentCoders = coders
        for coder in currentCoders where coder.canEncode(format) {
            return true
        }
        return false
    }
    
    public func encode(_ image: UIImage, toFormat format: BBImageFormat) -> Data? {
        let currentCoders = coders
        for coder in currentCoders where coder.canEncode(format) {
            return coder.encode(image, toFormat: format)
        }
        return nil
    }
    
    public func copy() -> BBImageCoder {
        let newObj = BBImageCoderManager()
        var newCoders: [BBImageCoder] = []
        let currentCoders = coders
        for coder in currentCoders {
            newCoders.append(coder.copy())
        }
        newObj.coders = newCoders
        return newObj
    }
}

extension BBImageCoderManager: BBImageProgressiveCoder {
    public func canIncrementallyDecode(imageData: Data) -> Bool {
        let currentCoders = coders
        for coder in currentCoders {
            if let progressiveCoder = coder as? BBImageProgressiveCoder,
                progressiveCoder.canIncrementallyDecode(imageData: imageData) {
                return true
            }
        }
        return false
    }
    
    public func incrementallyDecodedImage(withData data: Data, finished: Bool) -> UIImage? {
        let currentCoders = coders
        for coder in currentCoders {
            if let progressiveCoder = coder as? BBImageProgressiveCoder,
                progressiveCoder.canIncrementallyDecode(imageData: data) {
                return progressiveCoder.incrementallyDecodedImage(withData: data, finished: finished)
            }
        }
        return nil
    }
}
