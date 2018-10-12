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
    
    public static func editor(with displaySize: CGSize,
                              contentMode: UIView.ContentMode,
                              corner: UIRectCorner = UIRectCorner(rawValue: 0),
                              borderWidth: CGFloat = 0,
                              borderColor: UIColor? = nil) -> BBWebImageEditor {
        let edit: BBWebImageEditMethod = { (image: UIImage?, data: Data?) in
            guard let currentData = data,
                let currentImage = UIImage(data: currentData),
                let souceImage = currentImage.cgImage?.cropping(to: currentImage.rectToDisplay(with: displaySize, contentMode: contentMode)) else { return image }
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
            context.draw(souceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            #warning ("Add border")
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
