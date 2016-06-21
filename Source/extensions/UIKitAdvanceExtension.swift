//
//  UIKitAdvanceExtension.swift
//  MissMedia
//
//  Created by linhan on 16/4/16.
//  Copyright © 2016年 Miss. All rights reserved.
//

import Foundation
import UIKit


extension UITableView
{
    //安全的删除某行（return：是否成功删除）
    public func deleteRowsAtIndexPathsSafely(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) -> Bool
    {
        var invalid:Bool = false
        if let dataSource = dataSource
        {
            var totalRowsBefore:Int = 0
            var totalRowsAfter:Int = 0
            for section in 0..<numberOfSections
            {
                totalRowsBefore += numberOfRowsInSection(section)
                totalRowsAfter += dataSource.tableView(self, numberOfRowsInSection: section)
            }
            //如果删除前后的数目没有出入，则继续检查删除位置是否正确
            if totalRowsBefore == totalRowsAfter + indexPaths.count
            {
                for indexPath in indexPaths
                {
                    let numAfter = dataSource.tableView(self, numberOfRowsInSection: indexPath.section)
                    let numBefore = numberOfRowsInSection(indexPath.section)
                    if indexPath.row < 0 || indexPath.row >= numBefore
                    {
                        invalid = true
                    }
                }
            }
            else
            {
                invalid = true
            }
            
        }
        
        if !invalid
        {
            deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        }
        return !invalid
    }
}

extension UILabel
{
    //快键创建一个限定宽度内的Label
    class func labelWithLimitWidth(width:CGFloat, text:String, font:UIFont? = nil) -> UILabel
    {
        let textFont:UIFont = font ?? UIFont.systemFontOfSize(17)
        let textHeight:CGFloat = StringUtil.getStringHeight(text, font: textFont, width: width)
        let label:UILabel = UILabel()
        label.numberOfLines = 0
        label.font = textFont
        label.frame = CGRectMake(0, 0, width, textHeight)
        label.text = text
        return label
    }
}

extension UIButton
{
    public func sizeToTouchEasy()
    {
        sizeToFit()
        frame = CGRectMake(frame.origin.x, frame.origin.y, max(44, frame.width), max(44, frame.height))
    }
}

