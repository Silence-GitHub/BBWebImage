//
//  TestFilterVC.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2018/11/28.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit
import BBWebImage

class TestFilterVC: UIViewController {

    private var imageView: UIImageView!
    private var button: UIButton!
    private var filtered: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        imageView = UIImageView(frame: CGRect(x: 10, y: 100, width: view.bounds.width - 20, height: view.bounds.height - 200))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "sunflower.jpg")
        view.addSubview(imageView)
        
        button = UIButton(frame: CGRect(x: 10, y: imageView.frame.maxY + 10, width: imageView.frame.width, height: 30))
        button.backgroundColor = .blue
        button.setTitle("Add filter", for: .normal)
        button.setTitle("Reset", for: .selected)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc private func clickButton() {
        filtered = !filtered
        if filtered {
            let filter = BBCILookupTestFilter()
            filter.inputImage = CIImage(cgImage: imageView.image!.cgImage!)
            let output = filter.outputImage!
            // Set working color space or color is wrong
            let context = CIContext(options: [CIContextOption.workingColorSpace : CGColorSpaceCreateDeviceRGB()])
            let cgimage = context.createCGImage(output, from: output.extent)!
            imageView.image = UIImage(cgImage: cgimage)
        } else {
            imageView.image = UIImage(named: "sunflower.jpg")
        }
        button.isSelected = filtered
    }
}
