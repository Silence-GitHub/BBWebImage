//
//  BBWebImageManager.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public let BBWebImageErrorDomain: String = "BBWebImageErrorDomain"
public typealias BBWebImageManagerCompletion = (UIImage?, Error?, BBImageCacheType) -> Void

public class BBWebImageManager {
    public static let shared = BBWebImageManager()
    
    public private(set) var imageCache: BBImageCache
    public private(set) var imageDownloader: BBMergeRequestImageDownloader
    public private(set) var imageCoderManager: BBImageCoderManager
    private let coderQueue: DispatchQueue
    
    public init() {
        imageCache = BBLRUImageCache()
        imageDownloader = BBMergeRequestImageDownloader(sessionConfiguration: .default)
        imageCoderManager = BBImageCoderManager()
        coderQueue = DispatchQueue(label: "com.Kaibo.BBWebImage.ImageManager.Coder", qos: .userInitiated)
    }
    
    public func loadImage(with url: URL, completion: @escaping BBWebImageManagerCompletion) {
        imageCache.image(forKey: url.absoluteString) { [weak self] (image: UIImage?, cacheType: BBImageCacheType) in
            guard let self = self else { return }
            if let currentImage = image {
                DispatchQueue.main.safeAsync { completion(currentImage, nil, cacheType) }
            } else {
                self.imageDownloader.downloadImage(with: url) { [weak self] (data: Data?, error: Error?) in
                    guard let self = self else { return }
                    if let currentData = data {
                        self.coderQueue.async {
                            if let image = self.imageCoderManager.decode(imageData: currentData) {
                                if image.size.width > 0 && image.size.height > 0 {
                                    DispatchQueue.main.async { completion(image, nil, .none) }
                                } else {
                                    DispatchQueue.main.async { completion(nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Download image has 0 pixels"]), .none) }
                                }
                            } else {
                                DispatchQueue.main.async { completion(nil, NSError(domain: BBWebImageErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid image data"]), .none) }
                            }
                        }
                    } else if let currentError = error {
                        DispatchQueue.main.async { completion(nil, currentError, .none) }
                    }
                }
            }
        }
    }
}
