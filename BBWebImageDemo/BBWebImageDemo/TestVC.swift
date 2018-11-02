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

        view.backgroundColor = UIColor.lightGray
        
        let imageView = UIImageView(frame: CGRect(x: 10, y: 100, width: view.frame.width - 20, height: view.frame.height - 200))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        
        let url = URL(string: "http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/origin/1.jpg")!
        let editor = BBWebImageEditor.editorForScaleAspectFillContentMode(with: imageView.frame.size,
                                                                          maxResolution: 0,
                                                                          corner: [.topLeft, .bottomRight],
                                                                          cornerRadius: 10,
                                                                          borderWidth: 2,
                                                                          borderColor: UIColor.yellow,
                                                                          backgroundColor: UIColor.blue)
//        let dataUrl = Bundle.main.url(forResource: "large_leaves_70mp", withExtension: "jpg")!
//        let data = try! Data(contentsOf: dataUrl)
//        imageView.image = editor.edit(nil, data)
//        return;
        imageView.bb_setImage(with: url, placeholder: UIImage(named: "placeholder"), editor: editor) { (image: UIImage?, error: Error?, cacheType: BBImageCacheType) in
            print("Completion")
            if let currentImage = image {
                print("Image: \(currentImage)")
                print("Cache type: \(cacheType)")
                if let imageFormat = currentImage.bb_imageFormat {
                    print("Image format: \(imageFormat)")
                } else {
                    print("No image format")
                }
            } else if let currentError = error {
                print("Error: \(currentError)")
            }
        }
    }
}
