//
//  ImageWallCell.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2018/11/7.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit
import BBWebImage

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
    
    func set(url: URL) {
        let editor = BBWebImageEditor.editorForScaleAspectFillContentMode(with: imageView.frame.size,
                                                                          corner: .allCorners,
                                                                          cornerRadius: 5,
                                                                          borderWidth: 1,
                                                                          borderColor: .yellow,
                                                                          backgroundColor: .gray)
        imageView.bb_setImage(with: url, placeholder: UIImage(named: "placeholder"), options: .progressiveDownload, editor: editor, progress: nil, completion: nil)
    }
}
