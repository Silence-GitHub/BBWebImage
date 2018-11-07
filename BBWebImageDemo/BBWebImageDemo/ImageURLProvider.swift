//
//  ImageURLProvider.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2018/11/7.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

class ImageURLProvider {
    static func originURL(forIndex index: Int) -> URL? {
        if index < 1 || index > 4000 { return nil }
        return URL(string: "http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/origin/\(index).jpg")
    }
}
