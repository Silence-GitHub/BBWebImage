//
//  ImageWallCell.swift
//  CompareImageLib
//
//  Created by Kaibo Lu on 3/15/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit
import BBWebImage
import SDWebImage
import YYWebImage
import Kingfisher

class ImageWallCell: UICollectionViewCell {
    private var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(frame: CGRect(origin: .zero, size: frame.size))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(url: URL, type: TestType) {
        let placeholder = UIImage(named: "placeholder")
        switch type {
        case .BBWebImage:
            imageView.bb_setImage(with: url, placeholder: placeholder)
        case .SDWebImage:
            imageView.sd_setImage(with: url, placeholderImage: placeholder)
        case .YYWebImage:
            imageView.yy_setImage(with: url, placeholder: placeholder)
        case .Kingfisher:
            imageView.kf.setImage(with: url, placeholder: placeholder)
        }
    }
}
