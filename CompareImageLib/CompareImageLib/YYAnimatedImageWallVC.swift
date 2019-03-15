//
//  YYAnimatedImageWallVC.swift
//  CompareImageLib
//
//  Created by Kaibo Lu on 3/15/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

class YYAnimatedImageWallVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cellWidth = view.bounds.width / 4
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        let colletionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        colletionView.register(YYAnimatedImageWallCell.self, forCellWithReuseIdentifier: YYAnimatedImageWallCell.description())
        colletionView.backgroundColor = .white
        colletionView.dataSource = self
        view.addSubview(colletionView)
    }
}

extension YYAnimatedImageWallVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageURLProvider.gifUrlStrings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: YYAnimatedImageWallCell.description(), for: indexPath) as! YYAnimatedImageWallCell
        if let url = ImageURLProvider.gifURL(forIndex: indexPath.item) {
            cell.set(url: url)
        }
        return cell
    }
}
