//
//  BBAnimatedImage.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2/6/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

private struct BBAnimatedImageFrame {
    fileprivate var image: UIImage?
    fileprivate var duration: TimeInterval
}

public class BBAnimatedImage: UIImage {
    public var frameCount: Int!
    public var loopCount: Int!
    
    private var frames: [BBAnimatedImageFrame]!
    private var decoder: BBAnimatedImageCoder!
    private var lock: DispatchSemaphore!
    private var sentinel: Int32!
    private var preloadTask: (() -> Void)?
    
    deinit { cancelPreloadTask() }
    
    public convenience init?(bb_data data: Data, decoder aDecoder: BBAnimatedImageCoder? = nil) {
        var tempDecoder = aDecoder
        var canDecode = false
        if tempDecoder == nil {
            if let manager = BBWebImageManager.shared.imageCoder as? BBImageCoderManager {
                for coder in manager.coders {
                    if let animatedCoder = coder as? BBAnimatedImageCoder,
                        animatedCoder.canDecode(data) {
                        tempDecoder = animatedCoder
                        canDecode = true
                        break
                    }
                }
            }
        }
        guard let currentDecoder = tempDecoder else { return nil }
        if !canDecode && !currentDecoder.canDecode(data) { return nil }
        currentDecoder.imageData = data
        guard let firstFrame = currentDecoder.imageFrame(at: 0),
            let currentFrameCount = currentDecoder.frameCount else { return nil }
        var imageFrames: [BBAnimatedImageFrame] = []
        for i in 0..<currentFrameCount {
            if let duration = currentDecoder.duration(at: i) {
                imageFrames.append(BBAnimatedImageFrame(image: nil, duration: duration))
            } else {
                return nil
            }
        }
        self.init(cgImage: firstFrame.cgImage!, scale: 1, orientation: firstFrame.imageOrientation)
        frameCount = currentFrameCount
        loopCount = currentDecoder.loopCount ?? 0
        frames = imageFrames
        decoder = currentDecoder
        lock = DispatchSemaphore(value: 1)
        sentinel = 0
    }
    
    public func imageFrame(at index: Int) -> UIImage? {
        if index >= frameCount { return nil }
        lock.wait()
        let image = frames[index].image
        lock.signal()
        if image != nil { return image }
        return decoder.imageFrame(at: index)
    }
    
    public func duration(at index: Int) -> TimeInterval? {
        if index >= frameCount { return nil }
        lock.wait()
        let duration = frames[index].duration
        lock.signal()
        return duration
    }
    
    public func preloadImageFrames(with indexList: [Int]) {
        lock.wait()
        let shouldReturn = preloadTask != nil
        lock.signal()
        if shouldReturn { return }
        let sentinel = self.sentinel
        let work: () -> Void = { [weak self] in
            guard let self = self, sentinel == self.sentinel else { return }
            for index in indexList {
                if index >= self.frameCount { continue }
                self.lock.wait()
                let currentFrames = self.frames!
                self.lock.signal()
                if currentFrames[index].image == nil {
                    if let image = self.decoder.imageFrame(at: index) {
                        if sentinel != self.sentinel { return }
                        self.lock.wait()
                        self.frames[index].image = image
                        self.lock.signal()
                    }
                }
            }
            self.lock.wait()
            if sentinel == self.sentinel { self.preloadTask = nil }
            self.lock.signal()
        }
        lock.wait()
        preloadTask = work
        BBDispatchQueuePool.default.async(work: work)
        lock.signal()
    }
    
    private func cancelPreloadTask() {
        lock.wait()
        OSAtomicIncrement32(&sentinel)
        preloadTask = nil
        lock.signal()
    }
}
