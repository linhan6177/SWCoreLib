//
//  SWSwift3Convert.swift
//  SWCoreLibDemo
//
//  Created by linhan on 2016/11/8.
//  Copyright © 2016年 test. All rights reserved.
//

import Foundation
import UIKit

extension UIView
{
    func convert(_ rect: CGRect, toView view: UIView?) -> CGRect
    {
        return convert(rect, to: view)
    }
    
    
}

extension UIImage
{
//    func drawInRect(_ rect:CGRect)
//    {
//        draw(in: rect)
//    }
    
    
    
    
}

////////////////////////Foundation

extension Data
{
    public var length:Int{
        return count
    }
}



//////////////////全局函数

func CGPointMake(_ x:CGFloat, _ y:CGFloat) -> CGPoint
{
    return CGPoint(x: x, y: y)
}

func CGSizeMake(_ width:CGFloat, _ height:CGFloat) -> CGSize
{
    return CGSize(width: width, height: height)
}

func CGRectMake(_ x:CGFloat,_ y:CGFloat,_ width:CGFloat,_ height:CGFloat) -> CGRect
{
    return CGRect(x: x, y: y, width: width, height: height)
}

var CGRectZero:CGRect
{
    return CGRect.zero
}

var CGPointZero:CGPoint
{
    return CGPoint.zero
}
