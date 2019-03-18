
//
//  SegmentioView.swift
//  Parent
//
//  Created by Sx on 2018/4/26.
//  Copyright © 2018年 ETUSchool. All rights reserved.
//

import Segmentio

@objc protocol ETUSegmentDelegate: class {
    func segmentioViewDidSelectedItemAtIndex(index: Int)
}

public struct SegmentioViewState {
    var textFont: UIFont
    var textColor: UIColor
    var backgroundColor: UIColor
    
    public init(textFont: UIFont = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                textColor: UIColor = .clear,
                backGroundColor: UIColor = .white) {
        self.textFont = textFont
        self.textColor = textColor
        self.backgroundColor = backGroundColor
    }
}

private enum TextState {
    case normal
    case selected
    
    var font: CGFloat {
        switch self {
        case .normal:
            return 14.0
        case .selected:
            return 14.0
        }
    }
    
    var color: UIColor {
        switch self {
        case .normal:
            return .secondaryText
        case .selected:
            return .etuGreen
        }
    }
}

private enum SegmentioViewItemState {
    case normal
    case selected
    
    var state: SegmentioViewState {
        switch self {
        case .normal:
            return SegmentioViewState(
                textFont: UIFont.systemFont(ofSize: TextState.normal.font, weight: .medium),
                textColor: TextState.normal.color,
                backGroundColor: .white
            )
        case .selected:
            return SegmentioViewState(
                textFont: UIFont.systemFont(ofSize: TextState.selected.font, weight: .medium),
                textColor: TextState.selected.color,
                backGroundColor: .white
            )
        }
    }
}

struct SegmentioViewItem {
    
    public var title: String?
    public var image: UIImage?
    public var selectedImage: UIImage?
    public var badgeCount: Int?
    public var badgeColor: UIColor?
    public var intrinsicWidth: CGFloat {
        let label = UILabel()
        label.text = self.title
        label.sizeToFit()
        return label.intrinsicContentSize.width
    }
    
    init(title: String?, image: UIImage?, selectedImage: UIImage? = nil) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage ?? image
    }
    
    mutating func addBadge(_ count: Int?, color: UIColor) {
        if let countVale = count {
            self.badgeCount = countVale
        }
        self.badgeColor = color
    }
    
    mutating func removeBadge() {
        self.badgeCount = nil
        self.badgeColor = nil
    }
}

typealias ETUSegmentStyle = SegmentioStyle
typealias ETUSegmentOptions = SegmentioOptions
typealias ETUSegmentPosition = SegmentioPosition

class ETUSegment: UIView {
    
    weak var delegate: ETUSegmentDelegate?
    
    fileprivate let segmentViewState =  SegmentioStates(
        defaultState: SegmentioState(backgroundColor: SegmentioViewItemState.normal.state.backgroundColor,
                                     titleFont: SegmentioViewItemState.normal.state.textFont,
                                     titleTextColor: SegmentioViewItemState.normal.state.textColor),
        
        selectedState: SegmentioState(backgroundColor: SegmentioViewItemState.selected.state.backgroundColor,
                                      titleFont: SegmentioViewItemState.selected.state.textFont,
                                      titleTextColor: SegmentioViewItemState.selected.state.textColor),
        
        highlightedState: SegmentioState(backgroundColor: SegmentioViewItemState.selected.state.backgroundColor,
                                         titleFont: SegmentioViewItemState.selected.state.textFont,
                                         titleTextColor: SegmentioViewItemState.selected.state.textColor)
    )
    
    fileprivate let segmentioView = Segmentio(frame: .zero)
    fileprivate var segmentioStyle = SegmentioStyle.onlyLabel
    fileprivate var segmentPosition = ETUSegmentPosition.dynamic
    fileprivate let verticalSeparatorOptions = SegmentioVerticalSeparatorOptions(ratio: 0, color: .clear)
    fileprivate let indicatorOption = SegmentioIndicatorOptions(type: .bottom, ratio: 1, height: 2, color: .etuGreen )
    fileprivate let horizontalSeparatorOptions = SegmentioHorizontalSeparatorOptions(type: .topAndBottom, height: 1.0, color: .clear)
    fileprivate var segmentioOptions = SegmentioOptions()
    fileprivate var segmentItems = [SegmentioItem]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public func setup(contents: [SegmentioViewItem], style: ETUSegmentStyle?, options: SegmentioOptions?, position: ETUSegmentPosition?) {
        if let position = position {
            segmentPosition = position
        }
        
        segmentioOptions = SegmentioOptions(
            backgroundColor: .white,
            segmentPosition: segmentPosition,
            scrollEnabled: true,
            indicatorOptions: indicatorOption,
            horizontalSeparatorOptions: horizontalSeparatorOptions,
            verticalSeparatorOptions: verticalSeparatorOptions,
            imageContentMode: .scaleToFill,
            labelTextAlignment: .center,
            labelTextNumberOfLines: 1,
            segmentStates: segmentViewState,
            animationDuration: 0.2)
        
        if let style = style {
            segmentioStyle = style
        }
        
        if let options = options {
            segmentioOptions = options
        }
        
        
        self.addSubview(segmentioView)
        segmentioView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        segmentItems = contents.map{
            return SegmentioItem(title: $0.title, image: $0.image)
        }
        
        segmentioView.setup(content: segmentItems, style: segmentioStyle, options: segmentioOptions)
        setSelectedItem(at: 0)
        
        segmentioView.valueDidChange = { [unowned self] segmentio, segmentIndex in
            self.delegate?.segmentioViewDidSelectedItemAtIndex(index: segmentIndex)
        }
    }

}

// MARK: Instance Method
extension ETUSegment {
    
    public func setSelectedItem(at index: Int) {
        segmentioView.selectedSegmentioIndex = index
    }
    
    public func numberOfItems() -> Int {
        return segmentItems.count
    }
    
    public func item(at index: Int) -> String? {
        guard index < segmentItems.count else { return nil }
        return segmentItems[index].title
    }
    
    public func insertFirst(for itemTitle: String) {
        insert(for: itemTitle, at: 0)
    }
    
    public func insertLast(for itemTitle: String) {
        let etuItem = SegmentioItem(title: itemTitle, image: nil)
        segmentItems.append(etuItem)
        segmentioViewReload()
    }
    
    public func insert(for itemTitle: String, at index: Int) {
        let etuItem = SegmentioItem(title: itemTitle, image: nil)
        segmentItems.insert(etuItem, at: index)
        segmentioViewReload()
    }
    
    public func remove(at index: Int) {
        segmentItems.remove(at: index)
        segmentioViewReload()
    }
    
    public func index(of title: String) -> Int? {
        return segmentItems.index(where: { $0.title == title })
    }
    
    // Badge Method
    // show badge without value
    public func showBadge(at index: Int, color: UIColor = .etuDotRed) {
        segmentioView.addBadge(at: index, count: 0, color: color)
    }
    
    // show badge with value
    public func showBadgeWithValue(at index: Int, count: Int, color: UIColor = .etuDotRed) {
        segmentioView.addBadge(at: index, count: count, color: color)
    }
    
    // remove badge
    public func removeBadge(at index: Int) {
        segmentioView.removeBadge(at: index)
    }
    
    // reload
    private func segmentioViewReload() {
        segmentioView.setup(
            content: segmentItems,
            style: segmentioStyle,
            options: segmentioOptions
        )
        segmentioView.reloadSegmentio()
    }
    
}

fileprivate extension ETUSegment {
    static var SegmentOptions: SegmentioOptions {
        let option = SegmentioOptions()
        return option
    }
}
