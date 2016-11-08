//
//  File.swift
//  Basic
//
//  Created by linhan on 14-12-11.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
    typealias SWColor = UIColor
#else
    import AppKit.NSColor
    typealias SWColor = NSColor
#endif


extension SWColor
{
    //十六进制值来表示UIColor
    convenience init(hex:Any, alpha:CGFloat = 1)
    {
        var rgb:UInt32 = 0
        if let string = hex as? String
        {
            let scanner = Scanner(string: string)
            if string.hasPrefix("#")
            {
                scanner.scanLocation = 1
            }
            else if string.hasPrefix("0x")
            {
                scanner.scanLocation = 2
            }
            scanner.scanHexInt32(&rgb)
        }
        else if let intValue = hex as? Int
        {
            rgb = UInt32(intValue)
        }
        let r:CGFloat = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g:CGFloat = CGFloat((rgb & 0xFF00) >> 8) / 255.0
        let b:CGFloat = CGFloat(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    var hexValue:String
    {
        var a:CGFloat = 0
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let hexString = String(format: "0x%02X%02X%02X%02X", Int(a * 255), Int(r * 255), Int(g * 255), Int(b * 255))
        return hexString
    }
}

extension SWColor
{
    //获取随机颜色
    class func randomColor() -> SWColor
    {
        let red:CGFloat = CGFloat(arc4random_uniform(255)) / 255
        let green:CGFloat = CGFloat(arc4random_uniform(255)) / 255
        let blue:CGFloat = CGFloat(arc4random_uniform(255)) / 255
        let color:SWColor = SWColor(red:red, green:green, blue:blue, alpha: 1)
        return color
    }
}

class ColorUtil: NSObject
{
    /**
    * 24位色彩合成     alpha,red,green,blue都是0~255之间的数
    * @return
    */
    static func colorComposite(_ r:Int, g:Int, b:Int)-> Int
    {
        return r << 16 | g << 8 | b
    }
    
    
    /**
    * 32位色彩合成     alpha,red,green,blue都是0~255之间的数
    * @return
    */
    static func colorComposite32(_ a:Int,r:Int,g:Int,b:Int)-> Int
    {
        return a << 24 | r << 16 | g << 8 | b
    }

    
    
    
    
}
