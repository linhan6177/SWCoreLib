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
    public func deleteRowsAtIndexPathsSafely(_ indexPaths: [IndexPath], withRowAnimation animation: UITableViewRowAnimation) -> Bool
    {
        var invalid:Bool = false
        if let dataSource = dataSource
        {
            var totalRowsBefore:Int = 0
            var totalRowsAfter:Int = 0
            for section in 0..<numberOfSections
            {
                totalRowsBefore += numberOfRows(inSection: section)
                totalRowsAfter += dataSource.tableView(self, numberOfRowsInSection: section)
            }
            //如果删除前后的数目没有出入，则继续检查删除位置是否正确
            if totalRowsBefore == totalRowsAfter + indexPaths.count
            {
                for indexPath in indexPaths
                {
                    let numAfter = dataSource.tableView(self, numberOfRowsInSection: (indexPath as NSIndexPath).section)
                    let numBefore = numberOfRows(inSection: (indexPath as NSIndexPath).section)
                    if (indexPath as NSIndexPath).row < 0 || (indexPath as NSIndexPath).row >= numBefore
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
            deleteRows(at: indexPaths, with: animation)
        }
        return !invalid
    }
}

extension UILabel
{
    //快键创建一个限定宽度内的Label
    class func labelWithLimitWidth(_ width:CGFloat, text:String, font:UIFont? = nil) -> UILabel
    {
        let textFont:UIFont = font ?? UIFont.systemFont(ofSize: 17)
        let textHeight:CGFloat = StringUtil.getStringHeight(text, font: textFont, width: width)
        let label:UILabel = UILabel()
        label.numberOfLines = 0
        label.font = textFont
        label.frame = CGRect(x: 0, y: 0, width: width, height: textHeight)
        label.text = text
        return label
    }
}

extension UIButton
{
    public func sizeToTouchEasy()
    {
        sizeToFit()
        frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: max(44, frame.width), height: max(44, frame.height))
    }
}

