//
//  Data+ImageFormat.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/8.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

public enum BBImageFormat {
    case unknown
    case JPEG
    case PNG
}

public extension Data {
    var bb_imageFormat: BBImageFormat {
        if let firstByte = self.first {
            switch firstByte {
            case 0xFF: return .JPEG // https://en.wikipedia.org/wiki/JPEG
            case 0x89: return .PNG // https://en.wikipedia.org/wiki/Portable_Network_Graphics
            default: return .unknown
            }
        }
        return .unknown
    }
}
