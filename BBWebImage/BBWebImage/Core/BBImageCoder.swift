//
//  BBImageCoder.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public protocol BBImageCoder: AnyObject {
    func canDecode(_ data: Data) -> Bool
    func decodedImage(with data: Data) -> UIImage?
    func decompressedImage(with image: UIImage, data: Data) -> UIImage?
    func canEncode(_ format: BBImageFormat) -> Bool
    func encodedData(with image: UIImage, format: BBImageFormat) -> Data?
    func copy() -> BBImageCoder
}

public protocol BBImageProgressiveCoder: BBImageCoder {
    func canIncrementallyDecode(_ data: Data) -> Bool
    func incrementallyDecodedImage(with data: Data, finished: Bool) -> UIImage?
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
    public func canDecode(_ data: Data) -> Bool {
        let currentCoders = coders
        for coder in currentCoders where coder.canDecode(data) {
            return true
        }
        return false
    }
    
    public func decodedImage(with data: Data) -> UIImage? {
        let currentCoders = coders
        for coder in currentCoders where coder.canDecode(data) {
            return coder.decodedImage(with: data)
        }
        return nil
    }
    
    public func decompressedImage(with image: UIImage, data: Data) -> UIImage? {
        let currentCoders = coders
        for coder in currentCoders where coder.canDecode(data) {
            return coder.decompressedImage(with: image, data: data)
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
    
    public func encodedData(with image: UIImage, format: BBImageFormat) -> Data? {
        let currentCoders = coders
        for coder in currentCoders where coder.canEncode(format) {
            return coder.encodedData(with: image, format: format)
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
    public func canIncrementallyDecode(_ data: Data) -> Bool {
        let currentCoders = coders
        for coder in currentCoders {
            if let progressiveCoder = coder as? BBImageProgressiveCoder,
                progressiveCoder.canIncrementallyDecode(data) {
                return true
            }
        }
        return false
    }
    
    public func incrementallyDecodedImage(with data: Data, finished: Bool) -> UIImage? {
        let currentCoders = coders
        for coder in currentCoders {
            if let progressiveCoder = coder as? BBImageProgressiveCoder,
                progressiveCoder.canIncrementallyDecode(data) {
                return progressiveCoder.incrementallyDecodedImage(with: data, finished: finished)
            }
        }
        return nil
    }
}
