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

        donwloader = BBMergeRequestImageDownloader(sessionConfiguration: .default)
        let url = URL(string: "http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/origin/1.jpg")!
        donwloader.downloadImage(with: url) { (data: Data?, error: Error?) in
            print("Completion")
            if let currentData = data {
                print("Data count: \(currentData.count)")
            } else if let currentError = error {
                print("Error: \(currentError)")
            }
        }
    }
}
