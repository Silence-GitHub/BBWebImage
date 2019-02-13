//
//  GIFWallCell.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2/12/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit
import BBWebImage

class GIFWallCell: UICollectionViewCell {
    private var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = BBAnimatedImageView(frame: CGRect(origin: .zero, size: frame.size))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(url: URL) {
        imageView.bb_setImage(with: url,
                              placeholder: UIImage(named: "placeholder"),
                              options: .none,
                              editor: nil,
                              progress: nil,
                              completion: nil)
    }
}
