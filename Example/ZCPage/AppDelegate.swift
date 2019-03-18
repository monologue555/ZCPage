//
//  AppDelegate.swift
//  ZCPage
//
//  Created by 周子聪 on 2019/1/15.
//  Copyright © 2019 ETUSchool. All rights reserved.
//

import ZCPage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var profileVC = ZCPageViewController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        profileVC.dataSource = self
        window?.rootViewController = UINavigationController(rootViewController: profileVC)
        window?.makeKeyAndVisible()
        let pinBtn = UIButton()
        pinBtn.backgroundColor = .red
        pinBtn.setTitle("钉", for: .normal)
        window?.addSubview(pinBtn)
        pinBtn.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }
        
        window?.bringSubview(toFront: pinBtn)
        pinBtn.addTarget(self, action: #selector(pinHeaderView), for: .touchUpInside)
        return true
    }
    
    @objc func pinHeaderView() {
        profileVC.refreshMode = profileVC.refreshMode == .single ? .whole : .single
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension AppDelegate: ZCPageViewDataSource {
    func headerViewController() -> ZCPageHeaderViewController {
        let vc = ExampleHeaderViewController()
        vc.view.backgroundColor = .red
        return vc
    }
    
    func viewController(by index: Int) -> ZCPageChildViewController {
        switch index {
        case 0:
            return ArchivesViewController()
        case 1:
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.itemSize = .init(width: 100, height: 100)
            flowLayout.scrollDirection = .vertical
            let vc = RecordsViewController(collectionViewLayout: flowLayout)
            return vc
        default:
            fatalError("Impossible!!!")
        }
    }
    
    func scrollView(viewController: UIViewController, index: Int) -> UIScrollView? {
        switch index {
        case 0:
            return (viewController as? ArchivesViewController)?.tableView
        case 1:
            return (viewController as? RecordsViewController)?.collectionView
        default:
            fatalError("Impossible!!!")
        }
    }
    
    func heightOfSegmentView() -> CGFloat {
        return 44
    }
    
    func numbersOfItem() -> Int {
        return 2
    }
    
    func itemName(by index: Int) -> String {
        switch index {
        case 0:
            return "档案"
        case 1:
            return "记录"
        default:
            fatalError("Impossible!!!")
        }
    }
    
}
