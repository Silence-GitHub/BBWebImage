//
//  TestGIFVC.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2/6/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit
import BBWebImage

class TestGIFVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .lightGray
        
        let imageView = BBAnimatedImageView(frame: CGRect(x: 10, y: 100, width: view.frame.width - 20, height: view.frame.height - 200))
        imageView.backgroundColor = .yellow
        imageView.contentMode = .scaleAspectFit
        let url = Bundle(for: self.classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
        let data = try! Data(contentsOf: url)
        imageView.image = BBAnimatedImage(bb_data: data)
        view.addSubview(imageView)
    }
}
