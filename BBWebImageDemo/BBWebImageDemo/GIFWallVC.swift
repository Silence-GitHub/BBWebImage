//
//  GIFWallVC.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2/12/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

class GIFWallVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cellWidth = view.bounds.width / 4
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        let colletionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        colletionView.register(GIFWallCell.self, forCellWithReuseIdentifier: GIFWallCell.description())
        colletionView.backgroundColor = .gray
        colletionView.dataSource = self
        view.addSubview(colletionView)
    }
}

extension GIFWallVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageURLProvider.gifUrlStrings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GIFWallCell.description(), for: indexPath) as! GIFWallCell
        if let url = ImageURLProvider.gifURL(forIndex: indexPath.item) {
            cell.set(url: url)
        }
        return cell
    }
}
