//
//  BBWebImageEditor.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/10.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public typealias BBWebImageEditMethod = (UIImage?, Data?) -> UIImage?

public let bb_shareColorSpace = CGColorSpaceCreateDeviceRGB()
public let bb_ScreenScale = UIScreen.main.scale

private var _bb_shareCIContext: CIContext?
public var bb_shareCIContext: CIContext {
    var localContext = _bb_shareCIContext
    if localContext == nil {
        localContext = CIContext(options: [CIContextOption.workingColorSpace : bb_shareColorSpace])
        _bb_shareCIContext = localContext
    }
    return localContext!
}

public func bb_clearCIContext() { _bb_shareCIContext = nil }

public func bb_imageEditor(with displaySize: CGSize, contentMode: UIView.ContentMode) -> BBWebImageEditor {
    let edit: BBWebImageEditMethod = { (image, _) in
        if let currentImage = image?.resizedImage(with: displaySize, contentMode: contentMode) {
            return currentImage
        }
        return image
    }
    return BBWebImageEditor(key: "size=\(displaySize),contentMode=\(contentMode.rawValue)", needData: false, edit: edit)
}

/// BBWebImageEditor defines how to edit and cache image in memory
public struct BBWebImageEditor {
    public var key: String
    public var needData: Bool
    public var edit: BBWebImageEditMethod
    
    /// Creates a BBWebImageEditor variable
    ///
    /// - Parameters:
    ///   - key: identification of editor
    ///   - needData: whether image data is necessary or not for editing
    ///   - edit: an edit image closure
    public init(key: String, needData: Bool, edit: @escaping BBWebImageEditMethod) {
        self.key = key
        self.needData = needData
        self.edit = edit
    }
    
    /// Creates a BBWebImageEditor for scaleAspectFill content mode.
    /// This method can draw an image with corner, border and background color.
    /// To prevent large image consuming too much memory, specify a positive value for maxResolution.
    ///
    /// - Parameters:
    ///   - displaySize: size of view displaying image with scaleAspectFill content mode
    ///   - maxResolution: an expected maximum resolution of decoded image
    ///   - corner: how many image corners are drawn
    ///   - cornerRadius: corner radius of image, in view's coordinate
    ///   - borderWidth: border width of image, in view's coordinate
    ///   - borderColor: border color of image
    ///   - backgroundColor: background color of image
    /// - Returns: a BBWebImageEditor variable
    public static func editorForScaleAspectFillContentMode(with displaySize: CGSize,
                                                           maxResolution: Int = 0,
                                                           corner: UIRectCorner = UIRectCorner(rawValue: 0),
                                                           cornerRadius: CGFloat = 0,
                                                           borderWidth: CGFloat = 0,
                                                           borderColor: UIColor? = nil,
                                                           backgroundColor: UIColor? = nil) -> BBWebImageEditor {
        let edit: BBWebImageEditMethod = { (image: UIImage?, data: Data?) in
            autoreleasepool { () -> UIImage? in
                guard displaySize.width > 0,
                    displaySize.height > 0,
                    let currentData = data,
                    let currentImage = UIImage(data: currentData),
                    let sourceImage = currentImage.cgImage?.cropping(to: currentImage.rectToDisplay(with: displaySize, contentMode: .scaleAspectFill)) else { return image }
                var bitmapInfo = sourceImage.bitmapInfo
                bitmapInfo.remove(.alphaInfoMask)
                if sourceImage.bb_containsAlpha {
                    bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
                } else {
                    bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
                }
                // Make sure resolution is not too small
                let currentMaxResolution = max(maxResolution, Int(displaySize.width * displaySize.height * 7))
                let resolutionRatio = sqrt(CGFloat(sourceImage.width * sourceImage.height) / CGFloat(currentMaxResolution))
                let shouldScaleDown = maxResolution > 0 && resolutionRatio > 1
                var width = sourceImage.width
                var height = sourceImage.height
                if shouldScaleDown {
                    width = Int(CGFloat(sourceImage.width) / resolutionRatio)
                    height = Int(CGFloat(sourceImage.height) / resolutionRatio)
                } else if CGFloat(width) < displaySize.width * bb_ScreenScale {
                    width = Int(displaySize.width * bb_ScreenScale)
                    height = Int(displaySize.height * bb_ScreenScale)
                }
                guard let context = CGContext(data: nil,
                                              width: width,
                                              height: height,
                                              bitsPerComponent: sourceImage.bitsPerComponent,
                                              bytesPerRow: 0,
                                              space: bb_shareColorSpace,
                                              bitmapInfo: bitmapInfo.rawValue) else { return nil }
                context.scaleBy(x: 1, y: -1)
                context.translateBy(x: 0, y: CGFloat(-height))
                context.interpolationQuality = .high
                context.saveGState()
                
                let ratio = CGFloat(width) / displaySize.width
                let currentCornerRadius = cornerRadius * ratio
                let currentBorderWidth = borderWidth * ratio
                
                if let fillColor = backgroundColor?.cgColor {
                    context.setFillColor(fillColor)
                    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
                }
                if cornerRadius > 0 && corner.isSubset(of: .allCorners) && !corner.isEmpty {
                    let clipPath = borderPath(with: CGSize(width: width, height: height), corner: corner, cornerRadius: currentCornerRadius, borderWidth: currentBorderWidth)
                    context.addPath(clipPath.cgPath)
                    context.clip()
                }
                context.scaleBy(x: 1, y: -1)
                context.translateBy(x: 0, y: CGFloat(-height))
                if shouldScaleDown {
                    drawForScaleDown(context, sourceImage: sourceImage)
                } else {
                    context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                }
                context.restoreGState()
                if let strokeColor = borderColor?.cgColor,
                    borderWidth > 0 {
                    let strokePath = borderPath(with: CGSize(width: width, height: height), corner: corner, cornerRadius: currentCornerRadius, borderWidth: currentBorderWidth)
                    context.addPath(strokePath.cgPath)
                    context.setLineWidth(currentBorderWidth)
                    context.setStrokeColor(strokeColor)
                    context.strokePath()
                }
                return context.makeImage().flatMap { UIImage(cgImage: $0) }
            }
        }
        let cornerKey = corner.intersection([.topLeft, .topRight, .bottomLeft, .bottomRight]).rawValue
        let borderColorKey = borderColor?.cgColor.components ?? []
        let backgroundColorKey = backgroundColor?.cgColor.components ?? []
        let key = "size=\(displaySize),corner=\(cornerKey),cornerRadius=\(cornerRadius),borderWidth=\(borderWidth),borderColor=\(borderColorKey),backgroundColor=\(backgroundColorKey)"
        return BBWebImageEditor(key: key, needData: true, edit: edit)
    }
    
    private static func borderPath(with size: CGSize, corner: UIRectCorner, cornerRadius: CGFloat, borderWidth: CGFloat) -> UIBezierPath {
        let halfBorderWidth = borderWidth / 2
        let path = UIBezierPath()
        if corner.isSuperset(of: .topLeft) {
            path.move(to: CGPoint(x: halfBorderWidth, y: cornerRadius + halfBorderWidth))
            path.addArc(withCenter: CGPoint(x: cornerRadius + halfBorderWidth, y: cornerRadius + halfBorderWidth),
                        radius: cornerRadius,
                        startAngle: CGFloat.pi,
                        endAngle: CGFloat.pi * 3 / 2,
                        clockwise: true)
        } else {
            path.move(to: CGPoint(x: halfBorderWidth, y: halfBorderWidth))
        }
        if corner.isSuperset(of: .topRight) {
            path.addLine(to: CGPoint(x: size.width - cornerRadius - halfBorderWidth, y: halfBorderWidth))
            path.addArc(withCenter: CGPoint(x: size.width - cornerRadius - halfBorderWidth, y: cornerRadius + halfBorderWidth),
                        radius: cornerRadius,
                        startAngle: CGFloat.pi * 3 / 2,
                        endAngle: 0,
                        clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: size.width - halfBorderWidth, y: halfBorderWidth))
        }
        if corner.isSuperset(of: .bottomRight) {
            path.addLine(to: CGPoint(x: size.width - halfBorderWidth, y: size.height - cornerRadius - halfBorderWidth))
            path.addArc(withCenter: CGPoint(x: size.width - cornerRadius - halfBorderWidth, y: size.height - cornerRadius - halfBorderWidth),
                        radius: cornerRadius,
                        startAngle: 0,
                        endAngle: CGFloat.pi / 2,
                        clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: size.width - halfBorderWidth, y: size.height - halfBorderWidth))
        }
        if corner.isSuperset(of: .bottomLeft) {
            path.addLine(to: CGPoint(x: cornerRadius + halfBorderWidth, y: size.height - halfBorderWidth))
            path.addArc(withCenter: CGPoint(x: cornerRadius + halfBorderWidth, y: size.height - cornerRadius - halfBorderWidth),
                        radius: cornerRadius,
                        startAngle: CGFloat.pi / 2,
                        endAngle: CGFloat.pi,
                        clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: halfBorderWidth, y: size.height - halfBorderWidth))
        }
        path.close()
        return path
    }
    
    private static func drawForScaleDown(_ context: CGContext, sourceImage: CGImage) {
        let sourceImageTileSizeMB = 20
        let pixelsPerMB = 1024 * 1024 * 4
        let tileTotalPixels = sourceImageTileSizeMB * pixelsPerMB
        let imageScale = sqrt(CGFloat(context.width * context.height) / CGFloat(sourceImage.width * sourceImage.height))
        var sourceTile = CGRect(x: 0, y: 0, width: sourceImage.width, height: tileTotalPixels / sourceImage.width)
        var destTile = CGRect(x: 0, y: 0, width: CGFloat(context.width), height: ceil(sourceTile.height * imageScale))
        let destSeemOverlap: CGFloat = 2
        let sourceSeemOverlap = trunc(destSeemOverlap / imageScale)
        var iterations = Int(CGFloat(sourceImage.height) / sourceTile.height)
        let remainder = sourceImage.height % Int(sourceTile.height)
        if remainder != 0 { iterations += 1 }
        let sourceTileHeightMinusOverlap = sourceTile.height
        let destTileHeightMinusOverlap = destTile.height
        sourceTile.size.height += sourceSeemOverlap
        destTile.size.height += destSeemOverlap
        for y in 0..<iterations {
            autoreleasepool {
                sourceTile.origin.y = CGFloat(y) * sourceTileHeightMinusOverlap // + sourceSeemOverlap
                destTile.origin.y = CGFloat(context.height) - ceil(CGFloat(y + 1) * destTileHeightMinusOverlap + destSeemOverlap)
                if let sourceTileImage = sourceImage.cropping(to: sourceTile) {
                    if y == iterations - 1 && remainder != 0 {
                        var dify = destTile.height
                        destTile.size.height = ceil(CGFloat(sourceTileImage.height) * imageScale)
                        dify -= destTile.height
                        destTile.origin.y += dify
                    }
                    context.draw(sourceTileImage, in: destTile)
                }
            }
        }
    }
}

public extension UIImage {
    public func resizedImage(with displaySize: CGSize, contentMode: UIView.ContentMode) -> UIImage? {
        if displaySize.width <= 0 || displaySize.height <= 0 { return nil }
        let rect = rectToDisplay(with: displaySize, contentMode: contentMode)
        if let sourceImage = cgImage?.cropping(to: rect) {
            return UIImage(cgImage: sourceImage, scale: scale, orientation: imageOrientation)
        }
        if let ciimage = ciImage?.cropped(to: rect),
            let sourceImage = bb_shareCIContext.createCGImage(ciimage, from: ciimage.extent) {
            return UIImage(cgImage: sourceImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
    
    /// Calculates image rect to display with view size and content mode.
    /// Use the rect to crop image to fit view size and content mode.
    ///
    /// - Parameters:
    ///   - displaySize: view size
    ///   - contentMode: view content mode
    /// - Returns: image rect to display in image coordinate
    public func rectToDisplay(with displaySize: CGSize, contentMode: UIView.ContentMode) -> CGRect {
        var rect = CGRect(origin: .zero, size: size)
        switch contentMode {
        case .scaleAspectFill:
            let sourceRatio = size.width / size.height
            let displayRatio = displaySize.width / displaySize.height
            if sourceRatio < displayRatio {
                rect.size.height = size.width / displayRatio
                rect.origin.y = (size.height - rect.height) / 2
            } else {
                rect.size.width = size.height * displayRatio
                rect.origin.x = (size.width - rect.width) / 2
            }
        case .center:
            if size.width > displaySize.width {
                rect.origin.x = (size.width - displaySize.width) / 2
                rect.size.width = displaySize.width
            }
            if size.height > displaySize.height {
                rect.origin.y = (size.height - displaySize.height) / 2
                rect.size.height = displaySize.height
            }
        case .top:
            if size.width > displaySize.width {
                rect.origin.x = (size.width - displaySize.width) / 2
                rect.size.width = displaySize.width
            }
            if size.height > displaySize.height {
                rect.size.height = displaySize.height
            }
        case .bottom:
            if size.width > displaySize.width {
                rect.origin.x = (size.width - displaySize.width) / 2
                rect.size.width = displaySize.width
            }
            if size.height > displaySize.height {
                rect.origin.y = size.height - displaySize.height
                rect.size.height = displaySize.height
            }
        case .left:
            if size.height > displaySize.height {
                rect.origin.y = (size.height - displaySize.height) / 2
                rect.size.height = displaySize.height
            }
            if size.width > displaySize.width {
                rect.size.width = displaySize.width
            }
        case .right:
            if size.height > displaySize.height {
                rect.origin.y = (size.height - displaySize.height) / 2
                rect.size.height = displaySize.height
            }
            if size.width > displaySize.width {
                rect.origin.x = size.width - displaySize.width
                rect.size.width = displaySize.width
            }
        case .topLeft:
            if size.width > displaySize.width {
                rect.size.width = displaySize.width
            }
            if size.height > displaySize.height {
                rect.size.height = displaySize.height
            }
        case .topRight:
            if size.width > displaySize.width {
                rect.origin.x = size.width - displaySize.width
                rect.size.width = displaySize.width
            }
            if size.height > displaySize.height {
                rect.size.height = displaySize.height
            }
        case .bottomLeft:
            if size.width > displaySize.width {
                rect.size.width = displaySize.width
            }
            if size.height > displaySize.height {
                rect.origin.y = size.height - displaySize.height
                rect.size.height = displaySize.height
            }
        case .bottomRight:
            if size.width > displaySize.width {
                rect.origin.x = size.width - displaySize.width
                rect.size.width = displaySize.width
            }
            if size.height > displaySize.height {
                rect.origin.y = size.height - displaySize.height
                rect.size.height = displaySize.height
            }
        default:
            return rect
        }
        return rect
    }
}

public extension UIView {
    /// BBFillContentMode specifies how content fills its view
    public enum BBFillContentMode {
        case scale
        case center
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}
