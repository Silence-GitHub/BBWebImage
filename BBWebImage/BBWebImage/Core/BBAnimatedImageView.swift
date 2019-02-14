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
    private var shouldUpdateLayer: Bool = true
    
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
    
    private var currentType: BBAnimatedImageViewType {
        var type: BBAnimatedImageViewType = .none
        if isHighlighted {
            if let count = highlightedAnimationImages?.count, count > 0 { type = .hilightedAnimationImages }
            else if highlightedImage != nil { type = .hilightedImage }
        }
        if type == .none {
            if let count = animationImages?.count, count > 0 { type = .animationImages }
            else if image != nil { type = .image }
        }
        return type
    }
    
    private var imageForCurrentType: Any? { return image(forType: currentType) }
    
    private var loopCount: Int = 0
    private var currentFrameIndex: Int = 0
    private var accumulatedTime: TimeInterval = 0
    private var currentLayerContent: CGImage?
    
    deinit {
        displayLink?.invalidate()
    }
    
    private func setImage(_ image: AnyObject?, withType type: BBAnimatedImageViewType) {
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
        currentLayerContent = nil
        shouldUpdateLayer = true
    }
    
    @objc private func displayLinkRefreshed(_ link: CADisplayLink) {
        guard let currentImage = imageForCurrentType as? BBAnimatedImage else { return }
        if shouldUpdateLayer,
            let cgimage = currentImage.imageFrame(at: currentFrameIndex)?.cgImage {
            currentLayerContent = cgimage
            layer.setNeedsDisplay()
            shouldUpdateLayer = false
        }
        let nextIndex = (currentFrameIndex + 1) % currentImage.bb_frameCount
        currentImage.preloadImageFrame(fromIndex: nextIndex)
        accumulatedTime += link.duration * Double(link.frameInterval)
        if let duration = currentImage.duration(at: currentFrameIndex),
            accumulatedTime >= duration {
            currentFrameIndex = nextIndex
            accumulatedTime -= duration
            shouldUpdateLayer = true
            if animationRepeatCount > 0 && currentFrameIndex == 0 {
                loopCount += 1
                if loopCount >= animationRepeatCount {
                    stopAnimating()
                    resetAnimation()
                }
            }
        }
    }
    
    private func image(forType type: BBAnimatedImageViewType) -> Any? {
        switch type {
        case .none: return nil
        case .image: return image
        case .hilightedImage: return highlightedImage
        case .animationImages: return animationImages
        case .hilightedAnimationImages: return highlightedAnimationImages
        }
    }
    
    public override func startAnimating() {
        switch currentType {
        case .image, .hilightedImage:
            if let link = displayLink {
                if link.isPaused { link.isPaused = false }
            } else {
                let link = CADisplayLink(target: BBWeakProxy(target: self), selector: #selector(displayLinkRefreshed(_:)))
                link.add(to: RunLoop.main, forMode: .common)
                displayLink = link
            }
        default:
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
    
    // MARK: - Layer delegate
    
    public override func display(_ layer: CALayer) {
        if let content = currentLayerContent { layer.contents = content }
    }
}
