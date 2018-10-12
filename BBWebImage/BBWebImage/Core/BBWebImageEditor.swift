//
//  BBWebImageEditor.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/10.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public typealias BBWebImageEditMethod = (UIImage?, Data?) -> UIImage?

public struct BBWebImageEditor {
    public var key: String
    public var edit: BBWebImageEditMethod
    
    public init(key: String, edit: @escaping (UIImage?, Data?) -> UIImage?) {
        self.key = key
        self.edit = edit
    }
    
    public static func editorForScaleAspectFillContentMode(with displaySize: CGSize,
                                                           corner: UIRectCorner = UIRectCorner(rawValue: 0),
                                                           cornerRadius: CGFloat = 0,
                                                           borderWidth: CGFloat = 0,
                                                           borderColor: UIColor? = nil,
                                                           backgroundColor: UIColor? = nil) -> BBWebImageEditor {
        let edit: BBWebImageEditMethod = { (image: UIImage?, data: Data?) in
            guard let currentData = data,
                let currentImage = UIImage(data: currentData),
                let souceImage = currentImage.cgImage?.cropping(to: currentImage.rectToDisplay(with: displaySize, contentMode: .scaleAspectFill)) else { return image }
            var bitmapInfo = souceImage.bitmapInfo
            bitmapInfo.remove(.alphaInfoMask)
            let alphaInfo = souceImage.alphaInfo
            if !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast) {
                // Has alpha
                bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
            } else {
                // No alpha
                bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
            }
            let width = souceImage.width
            let height = souceImage.height
            guard let context = CGContext(data: nil,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: souceImage.bitsPerComponent,
                                          bytesPerRow: 0,
                                          space: bb_shareColorSpace,
                                          bitmapInfo: bitmapInfo.rawValue) else { return nil }
            if let fillColor = backgroundColor?.cgColor {
                context.setFillColor(fillColor)
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            }
            if cornerRadius > 0 && corner.isSubset(of: .allCorners) {
                context.scaleBy(x: 1, y: -1)
                context.translateBy(x: 0, y: CGFloat(-height))
                
                let topLeft = corner.isSuperset(of: .topLeft)
                let topRight = corner.isSuperset(of: .topRight)
                let bottomLeft = corner.isSuperset(of: .bottomLeft)
                let bottomRight = corner.isSuperset(of: .bottomRight)
                let path = UIBezierPath()
                path.lineWidth = borderWidth
                if topLeft {
                    path.move(to: CGPoint(x: 0, y: cornerRadius))
                    path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                                radius: cornerRadius,
                                startAngle: CGFloat.pi,
                                endAngle: CGFloat.pi * 3 / 2,
                                clockwise: true)
                }
                if topRight {
                    path.addLine(to: CGPoint(x: CGFloat(width) - cornerRadius, y: 0))
                    path.addArc(withCenter: CGPoint(x: CGFloat(width) - cornerRadius, y: cornerRadius),
                                radius: cornerRadius,
                                startAngle: CGFloat.pi * 3 / 2,
                                endAngle: 0,
                                clockwise: true)
                } else {
                    path.addLine(to: CGPoint(x: width, y: 0))
                }
                if bottomRight {
                    path.addLine(to: CGPoint(x: CGFloat(width), y: CGFloat(height) - cornerRadius))
                    path.addArc(withCenter: CGPoint(x: CGFloat(width) - cornerRadius, y: CGFloat(height) - cornerRadius),
                                radius: cornerRadius,
                                startAngle: 0,
                                endAngle: CGFloat.pi / 2,
                                clockwise: true)
                } else {
                    path.addLine(to: CGPoint(x: width, y: height))
                }
                if bottomLeft {
                    path.addLine(to: CGPoint(x: cornerRadius, y: CGFloat(height)))
                    path.addArc(withCenter: CGPoint(x: cornerRadius, y: CGFloat(height) - cornerRadius),
                                radius: cornerRadius,
                                startAngle: CGFloat.pi / 2,
                                endAngle: CGFloat.pi,
                                clockwise: true)
                } else {
                    path.addLine(to: CGPoint(x: 0, y: height))
                }
                path.close()
                borderColor?.setStroke()
                context.addPath(path.cgPath)
                if borderWidth > 0 { path.stroke() }
                context.clip()
                
                context.scaleBy(x: 1, y: -1)
                context.translateBy(x: 0, y: CGFloat(-height))
            }
            context.draw(souceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return context.makeImage().flatMap { UIImage(cgImage: $0) }
        }
        let key = ""
        return BBWebImageEditor(key: key, edit: edit)
    }
}

public let bb_shareColorSpace = CGColorSpaceCreateDeviceRGB()

public extension UIImage {
    public func shouldScaleDown(with displaySize: CGSize) -> Bool {
        return (displaySize.width * displaySize.height * UIScreen.main.scale) < (size.width * size.height)
    }
    
    // Image rect to display in image coordinate
    public func rectToDisplay(with displaySize: CGSize, contentMode: UIView.ContentMode) -> CGRect {
        let sourceRatio = size.width / size.height
        let displayRatio = displaySize.width / displaySize.height
        switch contentMode {
        case .scaleAspectFill:
            if sourceRatio < displayRatio {
                let h = size.width / displayRatio
                return CGRect(x: 0, y: (size.height - h) / 2, width: size.width, height: h)
            } else {
                let w = size.height * displayRatio
                return CGRect(x: (size.width - w) / 2, y: 0, width: w, height: size.height)
            }
        default:
            #warning ("Other content mode")
            return CGRect(origin: .zero, size: size)
        }
    }
}
