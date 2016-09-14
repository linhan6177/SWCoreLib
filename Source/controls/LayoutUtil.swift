//
//  LayoutUtil.swift
//  uicomponetTest3
//
//  Created by linhan on 15/7/7.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit
class LayoutUtil: NSObject
{
    //在容器宽度内绝对平均分布（空白空间相同）
    // |-A-A-|
    class func distributeHAverageABS(_ views:[UIView], containerWidth:CGFloat)
    {
        var contentLength:CGFloat = 0
        for i in 0..<views.count
        {
            contentLength += views[i].width
        }
        let gap:CGFloat = (containerWidth - contentLength) / CGFloat(views.count + 1)
        var lastRight:CGFloat = 0
        for i in 0..<views.count
        {
            views[i].x = lastRight + gap
            lastRight = views[i].right
        }
        
    }
    
    class func distributeVAverageABS(_ views:[UIView], containerHeight:CGFloat)
    {
        var contentLength:CGFloat = 0
        for i in 0..<views.count
        {
            contentLength += views[i].height
        }
        let gap:CGFloat = (containerHeight - contentLength) / CGFloat(views.count + 1)
        var lastBottom:CGFloat = 0
        for i in 0..<views.count
        {
            views[i].y = lastBottom + gap
            lastBottom = views[i].bottom
        }
        
    }
    
    //左右两边靠边，中间宽度内绝对平均分布
    // |A-A-A|
    class func distributeHAverageWelt(_ views:[UIView], containerWidth:CGFloat)
    {
        var contentLength:CGFloat = 0
        for i in 0..<views.count
        {
            contentLength += views[i].width
        }
        if views.count > 2
        {
            let firstView:UIView = views.first!
            firstView.x = 0
            let lastView:UIView = views.last!
            lastView.x = containerWidth - lastView.width
            let segments:CGFloat = max(CGFloat(views.count - 1), 0)
            let gap:CGFloat = segments == 0 ? 0 : (containerWidth - contentLength) / segments
            var lastRight:CGFloat = firstView.right
            for i in 1..<views.count - 1
            {
                views[i].x = lastRight + gap
                lastRight = views[i].right
            }
        }
        else
        {
            distributeHAverageABS(views, containerWidth: containerWidth)
        }
    }
    
    
    //在容器宽度内相对平均分布（左右空白小，中间空白大）
    // |-A--A-|
    class func distributeHAverageRel(_ views:[UIView], containerWidth:CGFloat)
    {
        let itemWidth:CGFloat = containerWidth / CGFloat(views.count)
        for i in 0..<views.count
        {
            views[i].x = (itemWidth * CGFloat(i)) + (itemWidth - views[i].width) * 0.5
        }
    }
    
    
    
    
    
}
