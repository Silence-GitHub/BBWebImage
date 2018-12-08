//
//  BBWebCacheResource.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/12/8.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public protocol BBWebCacheResource {
    var cacheKey: String { get }
    var downloadUrl: URL { get }
}

extension URL: BBWebCacheResource {
    public var cacheKey: String { return absoluteString }
    public var downloadUrl: URL { return self }
}
