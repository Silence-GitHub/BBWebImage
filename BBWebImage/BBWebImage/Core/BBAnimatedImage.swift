//
//  BBAnimatedImage.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2/6/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

private struct BBAnimatedImageFrame {
    fileprivate var image: UIImage? {
        didSet {
            if let currentImage = image {
                size = currentImage.size
            }
        }
    }
    fileprivate var size: CGSize?
    fileprivate var duration: TimeInterval
    
    fileprivate var bytes: Int64? { return image?.bb_bytes }
}

public class BBAnimatedImage: UIImage {
    public var bb_editor: BBWebImageEditor? {
        get {
            lock.wait()
            let e = editor
            lock.signal()
            return e
        }
        set {
            if let e = newValue, e.needData { return }
            lock.wait()
            editor = newValue
            lock.signal()
        }
    }
    
    public var bb_frameCount: Int { return frameCount }
    
    public var bb_loopCount: Int { return loopCount }
    
    public var bb_maxCacheSize: Int64 {
        get {
            lock.wait()
            let m = maxCacheSize!
            lock.signal()
            return m
        }
        set {
            lock.wait()
            if newValue >= 0 {
                maxCacheSize = newValue
                autoUpdateMaxCacheSize = false
            } else {
                maxCacheSize = 0
                autoUpdateMaxCacheSize = true
            }
            lock.signal()
        }
    }
    
    public var bb_originalImageData: Data { return decoder.imageData! }
    
    private var editor: BBWebImageEditor?
    private var frameCount: Int!
    private var loopCount: Int!
    private var maxCacheSize: Int64!
    private var currentCacheSize: Int64!
    private var autoUpdateMaxCacheSize: Bool!
    private var cachedFrameCount: Int!
    private var frames: [BBAnimatedImageFrame]!
    private var decoder: BBAnimatedImageCoder!
    private var views: NSHashTable<BBAnimatedImageView>!
    private var lock: DispatchSemaphore!
    private var sentinel: Int32!
    private var preloadTask: (() -> Void)?
    
    deinit {
        cancelPreloadTask()
        NotificationCenter.default.removeObserver(self)
    }
    
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
        guard let firstFrame = currentDecoder.imageFrame(at: 0, decompress: true),
            let firstFrameSourceImage = firstFrame.cgImage,
            let currentFrameCount = currentDecoder.frameCount,
            currentFrameCount > 0 else { return nil }
        var imageFrames: [BBAnimatedImageFrame] = []
        for i in 0..<currentFrameCount {
            if let duration = currentDecoder.duration(at: i) {
                let image = (i == 0 ? firstFrame : nil)
                let size = currentDecoder.imageFrameSize(at: i)
                imageFrames.append(BBAnimatedImageFrame(image: image, size: size, duration: duration))
            } else {
                return nil
            }
        }
        self.init(cgImage: firstFrameSourceImage, scale: 1, orientation: firstFrame.imageOrientation)
        frameCount = currentFrameCount
        loopCount = currentDecoder.loopCount ?? 0
        maxCacheSize = Int64.max
        currentCacheSize = Int64(imageFrames.first!.bytes!)
        autoUpdateMaxCacheSize = true
        cachedFrameCount = 1
        frames = imageFrames
        decoder = currentDecoder
        views = NSHashTable(options: .weakMemory)
        lock = DispatchSemaphore(value: 1)
        sentinel = 0
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    public func imageFrame(at index: Int, decodeIfNeeded: Bool) -> UIImage? {
        if index >= frameCount { return nil }
        lock.wait()
        let cacheImage = frames[index].image
        let editor = self.editor
        lock.signal()
        return imageFrame(at: index,
                          cachedImage: cacheImage,
                          editor: editor,
                          decodeIfNeeded: decodeIfNeeded)
    }
    
    private func imageFrame(at index: Int,
                            cachedImage: UIImage?,
                            editor bbEditor: BBWebImageEditor?,
                            decodeIfNeeded: Bool) -> UIImage? {
        if let currentImage = cachedImage {
            if let editor = bbEditor {
                if currentImage.bb_imageEditKey == editor.key {
                    return currentImage
                } else if decodeIfNeeded {
                    if currentImage.bb_imageEditKey == nil {
                        let editedImage = editor.edit(currentImage, nil)
                        editedImage?.bb_imageEditKey = editor.key
                        return editedImage
                    } else if let imageFrame = decoder.imageFrame(at: index, decompress: false) {
                        let editedImage = editor.edit(imageFrame, nil)
                        editedImage?.bb_imageEditKey = editor.key
                        return editedImage
                    }
                }
            } else if currentImage.bb_imageEditKey == nil {
                return currentImage
            } else if decodeIfNeeded {
                return decoder.imageFrame(at: index, decompress: true)
            }
        }
        if !decodeIfNeeded { return nil }
        if let editor = bbEditor {
            if let imageFrame = decoder.imageFrame(at: index, decompress: false) {
                let editedImage = editor.edit(imageFrame, nil)
                editedImage?.bb_imageEditKey = editor.key
                return editedImage
            }
        } else {
            return decoder.imageFrame(at: index, decompress: true)
        }
        return nil
    }
    
    public func duration(at index: Int) -> TimeInterval? {
        if index >= frameCount { return nil }
        lock.wait()
        let duration = frames[index].duration
        lock.signal()
        return duration
    }
    
    public func updateCacheSizeIfNeeded() {
        lock.wait()
        defer { lock.signal() }
        if !autoUpdateMaxCacheSize { return }
        let total = Int64(Double(UIDevice.totalMemory) * 0.2)
        let free = Int64(Double(UIDevice.freeMemory) * 0.6)
        maxCacheSize = min(total, free)
    }
    
    public func preloadImageFrame(fromIndex startIndex: Int) {
        if startIndex >= frameCount { return }
        lock.wait()
        let shouldReturn = (preloadTask != nil || cachedFrameCount >= self.frameCount)
        lock.signal()
        if shouldReturn { return }
        let sentinel = self.sentinel
        let work: () -> Void = { [weak self] in
            guard let self = self, sentinel == self.sentinel else { return }
            self.lock.wait()
            let cleanCache = (self.currentCacheSize > self.maxCacheSize)
            self.lock.signal()
            if cleanCache {
                for i in 0..<self.frameCount {
                    let index = (startIndex + self.frameCount * 2 - i - 2) % self.frameCount // last second frame of start index
                    var shouldBreak = false
                    self.lock.wait()
                    if let oldImage = self.frames[index].image {
                        self.frames[index].image = nil
                        self.cachedFrameCount -= 1
                        self.currentCacheSize -= oldImage.bb_bytes
                        shouldBreak = (self.currentCacheSize <= self.maxCacheSize)
                    }
                    self.lock.signal()
                    if shouldBreak { break }
                }
                return
            }
            for i in 0..<self.frameCount {
                let index = (startIndex + i) % self.frameCount
                self.lock.wait()
                let cachedImage = self.frames[index].image
                let editor = self.editor
                self.lock.signal()
                if let image = self.imageFrame(at: index,
                                               cachedImage: cachedImage,
                                               editor: editor,
                                               decodeIfNeeded: true) {
                    if sentinel != self.sentinel { return }
                    var shouldBreak = false
                    self.lock.wait()
                    if let oldImage = self.frames[index].image {
                        if oldImage.bb_imageEditKey != image.bb_imageEditKey {
                            if self.currentCacheSize + image.bb_bytes - oldImage.bb_bytes <= self.maxCacheSize {
                                self.frames[index].image = image
                                self.cachedFrameCount += 1
                                self.currentCacheSize += image.bb_bytes - oldImage.bb_bytes
                            } else {
                                shouldBreak = true
                            }
                        }
                    } else if self.currentCacheSize + image.bb_bytes <= self.maxCacheSize {
                        self.frames[index].image = image
                        self.cachedFrameCount += 1
                        self.currentCacheSize += image.bb_bytes
                    } else {
                        shouldBreak = true
                    }
                    self.lock.signal()
                    if shouldBreak { break }
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
    
    public func didAddToView(_ view: BBAnimatedImageView) {
        views.add(view)
    }
    
    public func didRemoveFromView(_ view: BBAnimatedImageView) {
        views.remove(view)
        if views.count <= 0 {
            cancelPreloadTask()
            clear(completion: nil)
        }
    }
    
    private func cancelPreloadTask() {
        lock.wait()
        if preloadTask != nil {
            OSAtomicIncrement32(&sentinel)
            preloadTask = nil
        }
        lock.signal()
    }
    
    private func clear(completion: (() -> Void)?) {
        BBDispatchQueuePool.default.async { [weak self] in
            guard let self = self else { return }
            self.lock.wait()
            for i in 0..<self.frames.count {
                self.frames[i].image = nil
            }
            self.cachedFrameCount = 0
            self.currentCacheSize = 0
            self.lock.signal()
            completion?()
        }
    }
    
    @objc private func didReceiveMemoryWarning() {
        clear { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                self.updateCacheSizeIfNeeded()
            }
        }
    }
}
