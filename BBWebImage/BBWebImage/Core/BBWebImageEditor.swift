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
                                                           maxResolution: Int = 0,
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
            let resolutionRatio = sqrt(CGFloat(souceImage.width * souceImage.height) / CGFloat(maxResolution))
            let shouldScaleDown = maxResolution > 0 && resolutionRatio > 1
            let width = shouldScaleDown ? Int(CGFloat(souceImage.width) / resolutionRatio) : souceImage.width
            let height = shouldScaleDown ? Int(CGFloat(souceImage.height) / resolutionRatio) : souceImage.height
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
                let ratio = shouldScaleDown ? resolutionRatio : CGFloat(souceImage.width) / displaySize.width
                let currentCornerRadius = cornerRadius * ratio
                
                context.scaleBy(x: 1, y: -1)
                context.translateBy(x: 0, y: CGFloat(-height))
                context.saveGState()
                
                let clipPath = borderPath(with: CGSize(width: width, height: height), corner: corner, cornerRadius: currentCornerRadius)
                context.addPath(clipPath.cgPath)
                context.clip()
                
                context.scaleBy(x: 1, y: -1)
                context.translateBy(x: 0, y: CGFloat(-height))
                if shouldScaleDown {
                    drawForScaleDown(context, sourceImage: souceImage)
                } else {
                    context.draw(souceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                }
                context.restoreGState()
                
                if let strokeColor = borderColor?.cgColor,
                    borderWidth > 0 {
                    let strokePath = borderPath(with: CGSize(width: width, height: height), corner: corner, cornerRadius: currentCornerRadius)
                    context.addPath(strokePath.cgPath)
                    context.setLineWidth(borderWidth * ratio)
                    context.setStrokeColor(strokeColor)
                    context.strokePath()
                }
            } else {
                context.draw(souceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            return context.makeImage().flatMap { UIImage(cgImage: $0) }
        }
        let cornerKey = corner.intersection([.topLeft, .topRight, .bottomLeft, .bottomRight]).rawValue
        let borderColorKey = borderColor?.cgColor.components ?? []
        let backgroundColorKey = backgroundColor?.cgColor.components ?? []
        let key = "size=\(displaySize),corner=\(cornerKey),cornerRadius=\(cornerRadius),borderWidth=\(borderWidth),borderColor=\(borderColorKey),backgroundColor=\(backgroundColorKey)".md5
        return BBWebImageEditor(key: key, edit: edit)
    }
    
    private static func borderPath(with size: CGSize, corner: UIRectCorner, cornerRadius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        if corner.isSuperset(of: .topLeft) {
            path.move(to: CGPoint(x: 0, y: cornerRadius))
            path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                        radius: cornerRadius,
                        startAngle: CGFloat.pi,
                        endAngle: CGFloat.pi * 3 / 2,
                        clockwise: true)
        }
        if corner.isSuperset(of: .topRight) {
            path.addLine(to: CGPoint(x: size.width - cornerRadius, y: 0))
            path.addArc(withCenter: CGPoint(x: size.width - cornerRadius, y: cornerRadius),
                        radius: cornerRadius,
                        startAngle: CGFloat.pi * 3 / 2,
                        endAngle: 0,
                        clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: size.width, y: 0))
        }
        if corner.isSuperset(of: .bottomRight) {
            path.addLine(to: CGPoint(x: size.width, y: size.height - cornerRadius))
            path.addArc(withCenter: CGPoint(x: size.width - cornerRadius, y: size.height - cornerRadius),
                        radius: cornerRadius,
                        startAngle: 0,
                        endAngle: CGFloat.pi / 2,
                        clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: size.width, y: size.height))
        }
        if corner.isSuperset(of: .bottomLeft) {
            path.addLine(to: CGPoint(x: cornerRadius, y: size.height))
            path.addArc(withCenter: CGPoint(x: cornerRadius, y: size.height - cornerRadius),
                        radius: cornerRadius,
                        startAngle: CGFloat.pi / 2,
                        endAngle: CGFloat.pi,
                        clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: 0, y: size.height))
        }
        path.close()
        return path
    }
    
    private static func drawForScaleDown(_ context: CGContext, sourceImage: CGImage) {
        context.interpolationQuality = .high
        
        let sourceImageTileSizeMB = 20
        let pixelsPerMB = 1024 * 1024 * 4
        let tileTotalPixels = sourceImageTileSizeMB * pixelsPerMB
        let imageScale = sqrt(CGFloat(context.width * context.height) / CGFloat(sourceImage.width * sourceImage.height))
        var sourceTile = CGRect(x: 0, y: 0, width: sourceImage.width, height: tileTotalPixels / sourceImage.width)
        var destTile = CGRect(x: 0, y: 0, width: CGFloat(context.width), height: sourceTile.height * imageScale)
        let destSeemOverlap: CGFloat = 2
        let sourceSeemOverlap = Int(destSeemOverlap / CGFloat(context.height) * CGFloat(sourceImage.height))
        var iterations = Int(CGFloat(sourceImage.height) / sourceTile.height)
        let remainder = sourceImage.height % Int(sourceTile.height)
        if remainder != 0 { iterations += 1 }
        let sourceTileHeightMinusOverlap = sourceTile.height
        sourceTile.size.height += CGFloat(sourceSeemOverlap)
        destTile.size.height += destSeemOverlap
        for y in 0..<iterations {
            sourceTile.origin.y = CGFloat(y) * sourceTileHeightMinusOverlap + CGFloat(sourceSeemOverlap)
            destTile.origin.y = CGFloat(context.height) - (CGFloat(y + 1) * sourceTileHeightMinusOverlap * imageScale + destSeemOverlap)
            if let sourceTileImage = sourceImage.cropping(to: sourceTile) {
                if y == iterations - 1 && remainder != 0 {
                    var dify = destTile.height
                    destTile.size.height = CGFloat(sourceTileImage.height) * imageScale
                    dify -= destTile.height
                    destTile.origin.y += dify
                }
                context.draw(sourceTileImage, in: destTile)
            }
        }
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
