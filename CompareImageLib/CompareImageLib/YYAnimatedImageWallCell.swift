//
//  YYAnimatedImageWallCell.swift
//  CompareImageLib
//
//  Created by Kaibo Lu on 3/15/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit
import YYWebImage

class YYAnimatedImageWallCell: UICollectionViewCell {
    private var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = YYAnimatedImageView(frame: CGRect(origin: .zero, size: frame.size))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(url: URL) {
        let placeholder = UIImage(named: "placeholder")
        imageView.yy_setImage(with: url, placeholder: placeholder)
    }
}
