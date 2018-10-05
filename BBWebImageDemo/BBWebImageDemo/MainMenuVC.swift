//
//  MainMenuVC.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2018/10/3.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

class MainMenuVC: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    private var list: [(String, () -> Void)]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let test = { [weak self] in
            if let self = self { self.navigationController?.pushViewController(TestVC(), animated: true) }
        }
        list = [("Test", test)]
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.description())
    }
}

extension MainMenuVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.description(), for: indexPath)
        cell.textLabel?.text = list[indexPath.row].0
        return cell
    }
}

