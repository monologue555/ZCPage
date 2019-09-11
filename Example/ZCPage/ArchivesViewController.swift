//
//  ArchivesViewController.swift
//  ZCPage
//
//  Created by 周子聪 on 2019/1/15.
//  Copyright © 2019 ETUSchool. All rights reserved.
//

import UIKit
import ZCPage

class ArchivesViewController: UITableViewController {
    
    lazy var refreshCtr = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshCtr
        } else {
            tableView.addSubview(refreshCtr)
        }
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
        refreshCtr.addTarget(self, action: #selector(refresh), for: .valueChanged)
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    @objc func refresh() {
        if refreshCtr.isRefreshing {
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                DispatchQueue.main.async {
                    self.refreshCtr.endRefreshing()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row) \(Int.random(in: 0 ..< 10000))"
        return cell
    }
    
}
extension ArchivesViewController: ZCPageChildViewControllerProtocol {
    var zcScrollView: UIScrollView? {
        return nil
    }
    
    func zcRefresh(completed: @escaping () -> Void) {
        print("【ArchivesViewController】刷新")
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            print("3")
            completed()
        }
    }
    
    func zcLoadMore() {
        print("【ArchivesViewController】加载更多")
    }
}
