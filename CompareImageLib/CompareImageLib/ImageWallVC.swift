//
//  ImageWallVC.swift
//  CompareImageLib
//
//  Created by Kaibo Lu on 3/15/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

enum TestType {
    case BBWebImage
    case SDWebImage
    case YYWebImage
    case Kingfisher
}

class ImageWallVC: UIViewController {

    private let type: TestType
    
    init(type: TestType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cellWidth = view.bounds.width / 4
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        let colletionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        colletionView.register(ImageWallCell.self, forCellWithReuseIdentifier: ImageWallCell.description())
        colletionView.backgroundColor = .white
        colletionView.dataSource = self
        view.addSubview(colletionView)
    }
}

extension ImageWallVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4000
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageWallCell.description(), for: indexPath) as! ImageWallCell
        if let url = ImageURLProvider.originURL(forIndex: indexPath.item + 1) {
            cell.set(url: url, type: type)
        }
        return cell
    }
}
