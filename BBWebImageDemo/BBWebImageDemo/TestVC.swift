//
//  TestVC.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2018/10/5.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit
import BBWebImage

class TestVC: UIViewController {

    private var donwloader: BBMergeRequestImageDownloader!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let url = URL(string: "http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/origin/1.jpg")!
        BBWebImageManager.shared.loadImage(with: url) { (image: UIImage?, error: Error?, cacheType: BBImageCacheType) in
            print("Completion")
            if let currentImage = image {
                print("Image: \(currentImage)")
            } else if let currentError = error {
                print("Error: \(currentError)")
            }
        }
    }
}
