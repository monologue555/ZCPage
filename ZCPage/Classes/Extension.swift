//
//  Extension.swift
//  ZCPage
//
//  Created by 周子聪 on 2019/1/23.
//  Copyright © 2019 ETUSchool. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /// iPhoneX、iPhoneXR、iPhoneXs、iPhoneXs Max等
    /// 判断刘海屏，返回true表示是刘海屏
    /// UIView中safeAreaInsets如果是刘海屏就会发生变化，普通屏幕safeAreaInsets恒等于UIEdgeInsetsZero
    var isNotchScreen: Bool {
        let screenBounds = UIScreen.main.bounds
        return screenBounds.height == 812 || screenBounds.width == 812 || screenBounds.height == 896 || screenBounds.width == 896
    }
}

extension UIColor {
    
    /// 一土绿
    static var etuGreen: UIColor {
        return UIColor(rgb: 0x53a833)
    }
 
    /// 一土点红， 用于小红点的颜色
    static var etuDotRed: UIColor {
        return UIColor(rgb: 0xf93838)
    }
    
    /// 字体颜色之主导色
    static var mainText: UIColor {
        return UIColor(white: 33.0 / 255.0, alpha: 1.0)
    }
    
    /// 字体颜色之辅助色
    static var secondaryText: UIColor {
        return UIColor(white: 117.0 / 255.0, alpha: 1.0)
    }
    
    
    static func rgb(_ r: Int, g: Int, b: Int, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
