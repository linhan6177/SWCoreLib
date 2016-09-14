//
//  SWDevice.swift
//  Basic2
//
//  Created by linhan on 15/11/15.
//  Copyright © 2015年 me. All rights reserved.
//

import Foundation
import UIKit


@objc public enum ScreenSize:Int
{
    case unknownSize
    case iPhone35inch
    case iPhone4inch
    case iPhone47inch
    case iPhone55inch
}

//通过实现可比较协议，使用更加简单，如 SWDevice.size >= .iPhone35inch
extension ScreenSize: Comparable {}

public func ==(lhs: ScreenSize, rhs: ScreenSize) -> Bool
{
    return lhs.rawValue == rhs.rawValue
}

public func <(lhs: ScreenSize, rhs: ScreenSize) -> Bool
{
    return lhs.rawValue < rhs.rawValue
}

public func <=(lhs: ScreenSize, rhs: ScreenSize) -> Bool
{
    return lhs.rawValue <= rhs.rawValue
}

public func >=(lhs: ScreenSize, rhs: ScreenSize) -> Bool
{
    return lhs.rawValue >= rhs.rawValue
}

public func >(lhs: ScreenSize, rhs: ScreenSize) -> Bool
{
    return lhs.rawValue > rhs.rawValue
}

class SWDevice: NSObject
{
    class var UDID:String
    {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    //当前屏幕尺寸
    class var size:ScreenSize
    {
        let w: Double = Double(UIScreen.main.bounds.size.width)
        let h: Double = Double(UIScreen.main.bounds.size.height)
        let screenHeight: Double = max(w, h)
        
        switch screenHeight {
        case 480:
            return ScreenSize.iPhone35inch
        case 568:
            return ScreenSize.iPhone4inch
        case 667:
            return UIScreen.main.scale == 3.0 ? ScreenSize.iPhone55inch : ScreenSize.iPhone47inch
        case 736:
            return ScreenSize.iPhone55inch
        default:
            return ScreenSize.unknownSize
        }
    }
    
}
