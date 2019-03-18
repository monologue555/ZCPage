//
//  ExampleHeaderViewController.swift
//  ZCPage_Example
//
//  Created by 周子聪 on 2019/2/25.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import ZCPage

class ExampleHeaderViewController: ZCPageHeaderViewController {
    
    lazy var bannerView: UIImageView = UIImageView(image: #imageLiteral(resourceName: "pageBg"))
    lazy var nameLabel: UILabel = UILabel()

    
    var viewHeight: CGFloat {
        return 220
    }
    
    func ctRefresh() {
        print("【ExampleHeaderViewController】刷新")
        print("0")
        nameLabel.text = "中文名"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(bannerView)
        bannerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = .white
        nameLabel.text = "English Name"
        view.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }
    }
}
