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
    }
}
