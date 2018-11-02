//
//  BBMemoryCache.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/29.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public class BBMemoryCache {
    public func image(forKey key: String) -> UIImage? {
        #warning("Image for key")
        return nil
    }
    
    public func store(_ image: UIImage, forKey key: String) {
        #warning("Store image for key")
    }
    
    public func removeImage(forKey key: String) {
        #warning("Remove image for key")
    }
    
    public func clear() {
        #warning("Clear image")
    }
}
