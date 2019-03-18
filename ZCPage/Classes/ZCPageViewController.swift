//
//  ZCPageViewController.swift
//  ZCPage
//
//  Created by 周子聪 on 2019/1/15.
//  Copyright © 2019 ETUSchool. All rights reserved.
//

import SnapKit
import Pageboy

public protocol ZCPageHeaderViewControllerProtocol {
    var bannerView: UIImageView { get }
    var viewHeight: CGFloat { get }
    /// 如果ZCPageViewDataSource isRefreshSinglePage是true, 则此方法不会被调用（无须实现）
    func zcRefresh()
}
public extension ZCPageHeaderViewControllerProtocol {
    func zcRefresh() { }
}
public typealias ZCPageHeaderViewController = ZCPageHeaderViewControllerProtocol & UIViewController

public protocol ZCPageChildViewControllerProtocol {
    var zcScrollView: UIScrollView? { get }
    /// 如果ZCPageViewController的refreshMode是single, 则此方法不会被调用（无须实现）。实现此方法时需要在刷新完成后手动执行completed闭包
    func zcRefresh(completed: @escaping () -> Void)
    func zcLoadMore()
}
public extension ZCPageChildViewControllerProtocol {
    func zcRefresh(completed: @escaping () -> Void) { completed() }
    func zcLoadMore() {}
}
public typealias ZCPageChildViewController = ZCPageChildViewControllerProtocol & UIViewController


public protocol ZCPageViewDataSource: AnyObject {
    func headerViewController() -> ZCPageHeaderViewController
    func numbersOfItem() -> Int
    func itemName(by index: Int) -> String
    func viewController(by index: Int) -> ZCPageChildViewController
    /// 【可选实现】默认值42
    func heightOfSegmentView() -> CGFloat
}
public extension ZCPageViewDataSource {
    func heightOfSegmentView() -> CGFloat {
        return 42
    }
}

public protocol ZCPageViewDelegate: AnyObject {
    func willFixHeaderView() -> Void
    func willUnfixHeaderView() -> Void
//    func refresh(headerViewController: ZCPageHeaderViewController, viewControllers: [ZCPageChildViewController]) -> Void
    
    /// 【可选实现】可在此方法中调用加载更多代码块; 若viewController已经在scrollViewDidScroll代理方法中实现了加载更多, 则无需在此重复编写
//    func willArriveBottom(index: Int, viewController: ZCPageChildViewController) -> Void
}
public extension ZCPageViewDelegate {
//    func willArriveBottom(index: Int, viewController: ZCPageChildViewController) -> Void {}
}

open class ZCPageViewController: UIViewController {
   
    public enum RefreshMode {
        case whole
        case single
    }
    public weak var dataSource: ZCPageViewDataSource?
    public weak var delegate: ZCPageViewDelegate?
    
    var fixedHeaderViewHeight: CGFloat!
    var maxHeaderViewOffset: CGFloat!
    
    /// Default is `whole`
    public var refreshMode: RefreshMode = .whole {
        didSet {
            switch refreshMode {
            case .whole:
                pageVC?.view.snp.updateConstraints { (make) in
                    make.height.equalTo(pageVCHeight)
                }
                // 禁止内部scrollView的直接响应滑动事件
                viewControllers?.compactMap { $0?.zcScrollView }.forEach { $0.isScrollEnabled = false }
                scrollView.isScrollEnabled = true
            case .single:
                pageVC?.view.snp.updateConstraints { (make) in
                    make.height.equalTo(pageVCHeight)
                }
                // 禁止外部scrollView响应滑动事件
                scrollView.isScrollEnabled = false
                viewControllers?.compactMap { $0?.zcScrollView }.forEach { $0.isScrollEnabled = true }
            }
        }
    }
    
    lazy var scrollView = UIScrollView()
    var lastContentOffsetY: CGFloat = 0
    private func updateLastContentOffsetY() {
        lastContentOffsetY = scrollView.bounds.origin.y
    }
    
    var headerViewController: ZCPageHeaderViewController!
    
    /// 此view是topView的容器，便于topView的层级切换
    lazy var headerContainerView = UIView()

    /// 此view是对headerViewController.view与segmentView的一层封装
    lazy var topView: UIView = UIView()
    
    lazy var segmentView: ETUSegment = ETUSegment()
    
    
    var pageVC: PageboyViewController!
    var currentIndex: Int = 0
    private var viewControllers: [ZCPageChildViewController?]!
    
    private var pageVCHeight: CGFloat {
        switch refreshMode {
        case .whole:
            return UIScreen.main.bounds.height - fixedHeaderViewHeight - (dataSource?.heightOfSegmentView() ?? 0)
        case .single:
            let topViewHeight = headerViewController.viewHeight + (dataSource?.heightOfSegmentView() ?? 0)
            return UIScreen.main.bounds.height - topViewHeight
        }
    }
    
    lazy var fixedTopViewOrginY: CGFloat = {
        let headerViewHeight = headerViewController.viewHeight
        return fixedHeaderViewHeight - headerViewHeight
    }()
    var fixed: Bool = false {
        willSet {
            guard newValue != fixed else { return }
            if newValue {
                // 将 topView 移到self.view上
                view.addSubview(topView)
                topView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalToSuperview().offset(fixedTopViewOrginY)
                    let height = headerViewController.viewHeight + (dataSource?.heightOfSegmentView() ?? 0)
                    
                    make.height.equalTo(height)
                }
                delegate?.willFixHeaderView()
            } else {
                // 将 topView 放回原处
                headerContainerView.addSubview(topView)
                topView.snp.remakeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                delegate?.willUnfixHeaderView()
            }
        }
    }
    var isTopBouncing: Bool = false
    var isBottomBouncing: Bool = false {
        willSet {
            if newValue && newValue != isBottomBouncing {
                currentViewController.zcLoadMore()
//                delegate?.willArriveBottom(index: currentIndex, viewController: currentViewController)
            }
        }
    }
    
    var currentViewController: ZCPageChildViewController {
        return viewControllers[currentIndex]!
    }
    
    var currentScrollView: UIScrollView? {
        return currentViewController.zcScrollView
    }
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()

    private var codeToAppend: (() -> Void)?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    func setupSubviews() {
        guard let ds = dataSource else {
            return
        }
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        if #available(iOS 10.0, *) {
            scrollView.refreshControl = refreshControl
        } else {
            scrollView.addSubview(refreshControl)
        }
        // 将菊花置于视图顶层
        refreshControl.layer.zPosition = 100
        var bounds = refreshControl.bounds;
        bounds.origin.y = -40
        refreshControl.bounds = bounds
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        headerViewController = ds.headerViewController()
        let numbersOfItem = ds.numbersOfItem()
        viewControllers = Array(repeating: nil, count: numbersOfItem)
    
        
        let headerViewHeight = headerViewController.viewHeight
        fixedHeaderViewHeight = isNotchScreen ? 88 : 64
        maxHeaderViewOffset = headerViewHeight - fixedHeaderViewHeight
        
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height + maxHeaderViewOffset)
        }
        navigationController?.navigationBar.isHidden = true
        
        view.backgroundColor = .white
        
        let segmentHeight = ds.heightOfSegmentView()
        
        contentView.addSubview(headerContainerView)
        headerContainerView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(headerViewHeight + segmentHeight)
        }
        headerContainerView.addSubview(topView)
        topView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let headerView = headerViewController.view!
        topView.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(headerViewHeight)
        }
        // 想要展示bannerView的放大效果，需要移除约束。否则可能会使得下拉放大时，bannerView突然恢复到初始的大小和位置
        headerViewController.bannerView.snp.removeConstraints()
        headerViewController.bannerView.translatesAutoresizingMaskIntoConstraints = true
        headerViewController.bannerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: headerViewHeight)
        
        let items: [SegmentioViewItem] = (0 ..< ds.numbersOfItem())
            .map { ds.itemName(by: $0) }
            .map { SegmentioViewItem(title: $0, image: nil) }
        
        segmentView.setup(contents: items, style: nil, options: nil, position: .fixed(maxVisibleItems: items.count))
        segmentView.delegate = self
        topView.addSubview(segmentView)
        segmentView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(segmentHeight)
        }

        pageVC = PageboyViewController()
        pageVC.dataSource = self
        pageVC.delegate = self

        addChild(pageVC)
        contentView.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)
        pageVC.view.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(headerContainerView.snp.bottom)
            make.height.equalTo(pageVCHeight)
        }
    }

    @objc func refresh() {
        if refreshControl.isRefreshing {
            let loadedViewControllers = self.viewControllers.compactMap { $0 }
            var refreshCount = loadedViewControllers.count // 需要刷新的控制器总数量
            // 刷新完成后数量减1
            let completed = {
                DispatchQueue.init(label: "refreshing").async {
                    refreshCount -= 1
                    if refreshCount == 0 {
                        DispatchQueue.main.async {
                            self.headerViewController.zcRefresh()
                            //                    print("刷新完毕")
                            self.refreshControl.endRefreshing()
                        }
                    }
                }
            }
            loadedViewControllers.forEach { $0.zcRefresh(completed: completed) }
        }
    }
    
}


extension ZCPageViewController: ETUSegmentDelegate, PageboyViewControllerDataSource, PageboyViewControllerDelegate {
    
    /// MARK: ETUSegmentDelegate
    func segmentioViewDidSelectedItemAtIndex(index: Int) {
        currentIndex = index
        pageVC.scrollToPage(.at(index: index), animated: true)
    }
    
    // MARK: PageboyViewControllerDataSource
    public func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return dataSource?.numbersOfItem() ?? 0
    }
    
    public func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return getViewController(by: index)
    }
    
    public func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .first
    }

    // MARK: PageboyViewControllerDelegate
    public func pageboyViewController(_ pageboyViewController: PageboyViewController, willScrollToPageAt index: PageboyViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        
    }
    
    public func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollTo position: CGPoint, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        
    }
    
    public func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: PageboyViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        switch refreshMode {
        case .whole:
            // 禁止内部scrollView的直接响应滑动事件
            viewControllers[index]?.zcScrollView?.isScrollEnabled = false
        case .single:
            // 禁止外部scrollView响应滑动事件
            scrollView.isScrollEnabled = false
        }
        segmentView.setSelectedItem(at: index)
    }
    
    public func pageboyViewController(_ pageboyViewController: PageboyViewController, didReloadWith currentViewController: UIViewController, currentPageIndex: PageboyViewController.PageIndex) {
        
    }
    
    
    private func getViewController(by index: Int) -> UIViewController {
        if let viewController = viewControllers[index] {
            return viewController
        } else {
            let viewController = dataSource!.viewController(by: index)
            viewControllers[index] = viewController
            return viewController
        }
    }
}

extension ZCPageViewController: UITableViewDelegate, UICollectionViewDelegate {
  
    // 实现下拉时BannerView的放大效果
    func zoomBannerView(with changedValue: CGFloat) {
        let bannerView = headerViewController.bannerView
        
        bannerView.contentMode = .scaleAspectFill
        
        var frame = bannerView.frame
        // 放大
        frame.size.height -= changedValue
        frame.origin.y += changedValue
        
        frame.size.width -= changedValue * 2
        frame.origin.x += changedValue
        
        bannerView.frame = frame
    }
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 防止其它UIScrollView设置了当前控制器为代理，造成不可预料的后果
        guard self.scrollView === scrollView else { return }
        let changedValue = scrollView.bounds.origin.y - lastContentOffsetY
        
//        #warning("Remove Debug Code!")
//        print(changedValue)

        
        // 触底的弹性效果
        if isBottomBouncing {
            let fixedContentOffsetY = scrollView.contentSize.height - scrollView.contentInset.bottom - scrollView.bounds.height
            if scrollView.contentOffset.y.isEqual(to: fixedContentOffsetY) {
                isBottomBouncing = false
            } else if scrollView.contentOffset.y < fixedContentOffsetY {
                scrollView.contentOffset.y = fixedContentOffsetY
            }
            updateLastContentOffsetY()
            return
        }
        // 顶部的弹性效果
        if isTopBouncing {
            if scrollView.contentOffset.y.isEqual(to: 0) {
                zoomBannerView(with: changedValue)
                isTopBouncing = false
            } else if scrollView.contentOffset.y > 0 {
                scrollView.contentOffset.y = 0
            } else {
                zoomBannerView(with: changedValue)
            }
            
            updateLastContentOffsetY()

            return
        }
        
        scrollView.bounds.origin.y = lastContentOffsetY
        
        if changedValue > 0 { // 上滑操作
            scrollView.contentInset.bottom = 10 // 防止上拉有弹性阻力

            if lastContentOffsetY.isEqual(to: maxHeaderViewOffset) {
                // 滑动手势代理给currentScrollView
                
                // 确保当前控制器拥有UIScrollView，否则已经到底部了
                guard let currentScrollView = currentScrollView else {
                    scrollView.contentInset.bottom = 0 // 开启scrollView的弹性阻力
                    isBottomBouncing = true
                    scrollView.bounds.origin.y += changedValue
                    updateLastContentOffsetY()
                    return
                }
                
                // 代表是否能向上滑动
                let isLeftContentExisted = currentScrollView.contentSize.height > currentScrollView.bounds.height
                
                // 代表还能向上滑动的距离
                let leftContentY = currentScrollView.contentSize.height + currentScrollView.contentInset.bottom - currentScrollView.bounds.height - currentScrollView.contentOffset.y
                
                if !isLeftContentExisted || leftContentY.isEqual(to: 0) {
                    scrollView.contentInset.bottom = 0 // 开启scrollView的弹性阻力
                    isBottomBouncing = true
                    updateLastContentOffsetY()
                    scrollView.contentOffset.y += changedValue
                    return
                } else {
                    if leftContentY - changedValue > 0 {
                        currentScrollView.contentOffset.y += changedValue
                    } else {
                        currentScrollView.contentOffset.y += leftContentY
                    }
                }
            } else {
                // scrollView响应滑动手势
                if lastContentOffsetY + changedValue < maxHeaderViewOffset {
                    scrollView.bounds.origin.y += changedValue
                } else {
                    scrollView.bounds.origin.y = maxHeaderViewOffset
                    fixed = true
                }
            }
        } else if changedValue < 0 { // 下滑操作

            if (currentScrollView?.bounds.origin.y ?? 0).isEqual(to: 0) {
                // scrollView响应滑动手势
                if lastContentOffsetY.isEqual(to: maxHeaderViewOffset) {
                    fixed = false
                    scrollView.bounds.origin.y += changedValue
                } else if lastContentOffsetY.isEqual(to: 0) {
                    isTopBouncing = true
                    updateLastContentOffsetY()
                    scrollView.contentOffset.y += changedValue
                    return
                } else {
                    if lastContentOffsetY + changedValue > 0 {
                        if lastContentOffsetY > maxHeaderViewOffset && lastContentOffsetY + changedValue < maxHeaderViewOffset {
                            updateLastContentOffsetY()
                            scrollView.contentOffset.y = maxHeaderViewOffset
                            return
                        } else {
                            scrollView.bounds.origin.y += changedValue
                        }
                    } else {
                        scrollView.bounds.origin.y = 0
                    }
                }
            } else {
                // 滑动手势代理给currentScrollView

                // 确保当前控制器拥有UIScrollView，否则直接滚动scrollView
                guard let currentScrollView = currentScrollView else {
                    scrollView.bounds.origin.y += changedValue
                    updateLastContentOffsetY()
                    return
                }
                
                if currentScrollView.contentOffset.y + changedValue < 0 {
                    currentScrollView.contentOffset.y = 0
                } else {
                    currentScrollView.contentOffset.y += changedValue
                }
            }
        }
        updateLastContentOffsetY()
    }
}

extension CGFloat {
    static let errorRange: Float = 1e-7
    func isEqual(to another: CGFloat) -> Bool {
        return fabsf(Float(self - another)) < CGFloat.errorRange
    }
}
