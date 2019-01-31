//
//  ImageWallVC.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2018/11/7.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit
import BBWebImage

class ImageWallVC: UIViewController {

    var preloadTasks: [Int : BBWebImageLoadTask]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        preloadTasks = [:]
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cellWidth = view.bounds.width / 4
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        let colletionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        colletionView.register(ImageWallCell.self, forCellWithReuseIdentifier: ImageWallCell.description())
        colletionView.backgroundColor = .gray
        colletionView.dataSource = self
        if #available(iOS 10.0, *) { colletionView.prefetchDataSource = self }
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
            cell.set(url: url)
        }
        return cell
    }
}

extension ImageWallVC: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        var urls: [URL] = []
        for indexPath in indexPaths {
            if let url = ImageURLProvider.originURL(forIndex: indexPath.item + 1) {
                urls.append(url)
            }
        }
        let tasks = BBWebImageManager.shared.preload(urls, options: .none, progress: { (successCount, finishCount, total) in
            print("Preload progress. success count = \(successCount), finish count = \(finishCount), total = \(total)")
        }) { (successCount, total) in
            print("Preload completion. success count = \(successCount), total = \(total)")
        }
        for i in 0..<tasks.count {
            preloadTasks[indexPaths[i].item] = tasks[i]
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let task = preloadTasks.removeValue(forKey: indexPath.item) {
                task.cancel()
            }
        }
    }
}
