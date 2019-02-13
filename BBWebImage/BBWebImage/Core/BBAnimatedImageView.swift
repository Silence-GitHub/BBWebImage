//
//  BBAnimatedImageView.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2/6/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

enum BBAnimatedImageViewType {
    case none
    case image
    case hilightedImage
    case animationImages
    case hilightedAnimationImages
}

public class BBAnimatedImageView: UIImageView {
    public var bb_autoStartAnimation: Bool = true
    
    private var displayLink: CADisplayLink?
    
    public override var image: UIImage? {
        get { return super.image }
        set {
            if super.image == newValue {
                return
            }
            setImage(newValue, withType: .image)
        }
    }
    
    public override var isAnimating: Bool {
        return super.isAnimating
    }
    
    private var type: BBAnimatedImageViewType = .none
    private var loopCount: Int = 0
    private var currentFrameIndex: Int = 0
    private var accumulatedTime: TimeInterval = 0
    
    deinit {
        displayLink?.invalidate()
    }
    
    private func setImage(_ image: AnyObject?, withType type: BBAnimatedImageViewType) {
        self.type = type
        stopAnimating()
        if displayLink != nil { resetAnimation() }
        if let animatedImage = image as? BBAnimatedImage { animatedImage.updateCacheSizeIfNeeded() }
        switch type {
        case .none: break
        case .image: super.image = image as? UIImage
        case .hilightedImage: super.highlightedImage = image as? UIImage
        case .animationImages: super.animationImages = image as? [UIImage]
        case .hilightedAnimationImages: super.highlightedAnimationImages = image as? [UIImage]
        }
        didMove()
    }
    
    private func resetAnimation() {
        loopCount = 0
        currentFrameIndex = 0
        accumulatedTime = 0
    }
    
    @objc private func displayLinkRefreshed(_ link: CADisplayLink) {
        guard let currentImage = image as? BBAnimatedImage else { return }
        if let cgimage = currentImage.imageFrame(at: currentFrameIndex)?.cgImage {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.contents = cgimage
            CATransaction.commit()
        }
        let nextIndex = (currentFrameIndex + 1) % currentImage.bb_frameCount
        currentImage.preloadImageFrame(fromIndex: nextIndex)
        accumulatedTime += link.duration * Double(link.frameInterval)
        if let duration = currentImage.duration(at: currentFrameIndex),
            accumulatedTime >= duration {
            currentFrameIndex = nextIndex
            accumulatedTime -= duration
            if animationRepeatCount > 0 && currentFrameIndex == 0 {
                loopCount += 1
                if loopCount >= animationRepeatCount {
                    stopAnimating()
                    resetAnimation()
                }
            }
        }
    }
    
    public override func startAnimating() {
        if type == .image {
            if image != nil {
                if let link = displayLink {
                    if link.isPaused { link.isPaused = false }
                } else {
                    let link = CADisplayLink(target: BBWeakProxy(target: self), selector: #selector(displayLinkRefreshed(_:)))
                    link.add(to: RunLoop.main, forMode: .common)
                    displayLink = link
                }
            }
        } else {
            super.startAnimating()
        }
    }
    
    public override func stopAnimating() {
        super.stopAnimating()
        displayLink?.isPaused = true
    }
    
    public override func didMoveToSuperview() {
        didMove()
    }
    
    public override func didMoveToWindow() {
        didMove()
    }
    
    private func didMove() {
        if bb_autoStartAnimation {
            if superview != nil && window != nil {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
}
