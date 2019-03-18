//
//  RecordsViewController.swift
//  ZCPage
//
//  Created by 周子聪 on 2019/1/15.
//  Copyright © 2019 ETUSchool. All rights reserved.
//

import UIKit
import ZCPage

class RecordsViewController: UICollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        /// 为什么删掉下面这行编译不通过呢？（为什么collectionView不会自动强制解包）
        guard let collectionView = collectionView else { return }
        
        collectionView.backgroundColor = .clear
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = UIColor.init(red: CGFloat.random(in: 0 ... 1), green: CGFloat.random(in: 0 ... 1), blue: CGFloat.random(in: 0 ... 1), alpha: 1)
        return cell
    }
}

extension RecordsViewController: ZCPageChildViewControllerProtocol {
    var ctScrollView: UIScrollView? {
        return collectionView
    }
    
    func ctRefresh(completed: @escaping () -> Void) {
        print("【RecordsViewController】刷新")
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            print("2")
            completed()
        }
    }
    
    func ctLoadMore() {
        print("【RecordsViewController】加载更多")
    }
}
