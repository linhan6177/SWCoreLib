//
//  Math.swift
//  NicePlayer
//
//  Created by linhan on 15-5-29.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
#endif

class Math: NSObject
{
    class var PI:CGFloat
    {
        return CGFloat(M_PI)
    }
    
    //产生随机浮点数,数值 0 <= n < 1
    class func random() -> Double
    {
        return Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max)
    }
    
    class func random(range:Range<Int>) -> Int
    {
        return range.startIndex + Int(arc4random_uniform(UInt32(range.endIndex - range.startIndex)))
    }
    
    class func random(value:Int) -> Int
    {
        return Int(arc4random_uniform(UInt32(value)))
    }
    
    //角度转弧度
    class func angleToRadian(angle:CGFloat) -> CGFloat
    {
        return angle * CGFloat(M_PI) / 180
    }
    
}