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
    
    private var imageView: BBAnimatedImageView!
    private var scaleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .lightGray
        
        let x: CGFloat = 10
        let width = view.frame.width - 20
        
        let scrollView = UIScrollView(frame: CGRect(x: x, y: 100, width: width, height: 200))
        scrollView.contentSize = CGSize(width: width + 20, height: 200)
        view.addSubview(scrollView)
        
        imageView = BBAnimatedImageView(frame: scrollView.bounds)
        imageView.backgroundColor = .yellow
        imageView.contentMode = .scaleAspectFit
        let url = Bundle(for: self.classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
        let data = try! Data(contentsOf: url)
        imageView.image = BBAnimatedImage(bb_data: data)
        scrollView.addSubview(imageView)
        
        var y = scrollView.frame.maxY + 10
        
        scaleLabel = UILabel(frame: CGRect(x: x, y: y, width: width, height: 30))
        scaleLabel.text = "Duration scale: 1.0"
        scaleLabel.textAlignment = .center
        view.addSubview(scaleLabel)
        
        y = scaleLabel.frame.maxY
        
        let scaleSilder = UISlider(frame: CGRect(x: x + 30, y: y, width: width - 60, height: 30))
        scaleSilder.minimumValue = 0.2
        scaleSilder.maximumValue = 5
        scaleSilder.value = 1
        scaleSilder.addTarget(self, action: #selector(scaleSliderChanged(_:)), for: .valueChanged)
        view.addSubview(scaleSilder)
        
        y = scaleSilder.frame.maxY + 10
        
        var buttonIndex = 0
        let generateButton = { (title: String?, selectedTitle: String?) -> UIButton in
            let button = UIButton(frame: CGRect(x: x, y: y, width: self.imageView.frame.width, height: 30))
            button.backgroundColor = (buttonIndex % 2 == 0 ? .blue : .red)
            button.setTitle(title, for: .normal)
            button.setTitle(selectedTitle, for: .selected)
            self.view.addSubview(button)
            y = button.frame.maxY
            buttonIndex += 1
            return button
        }
        
        let stopButton = generateButton("Stop", "Start")
        stopButton.addTarget(self, action: #selector(stopButtonClicked(_:)), for: .touchUpInside)
        
        let runLoopButton = generateButton("Change to default mode", "Change to common mode")
        runLoopButton.addTarget(self, action: #selector(runLoopButtonClicked(_:)), for: .touchUpInside)
        
        let changeImageButton = generateButton("Show static image", "Show GIF")
        changeImageButton.addTarget(self, action: #selector(changeImageButtonClicked(_:)), for: .touchUpInside)
    }
    
    @objc private func scaleSliderChanged(_ slider: UISlider) {
        scaleLabel.text = String(format: "Duration scale: %.1f", slider.value)
        imageView.bb_animationDurationScale = Double(slider.value)
    }
    
    @objc private func stopButtonClicked(_ button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
            imageView.stopAnimating()
        } else {
            imageView.startAnimating()
        }
    }
    
    @objc private func runLoopButtonClicked(_ button: UIButton) {
        button.isSelected = !button.isSelected
        imageView.bb_runLoopMode = (button.isSelected ? .default : .common)
    }
    
    @objc private func changeImageButtonClicked(_ button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
            imageView.image = UIImage(named: "placeholder")
        } else {
            let url = Bundle(for: self.classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
            let data = try! Data(contentsOf: url)
            imageView.image = BBAnimatedImage(bb_data: data)
        }
    }
}
