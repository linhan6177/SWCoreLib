//
//  StringUtil.swift
//  iosapphello
//
//  Created by linhan on 14-8-7.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation

#if os(iOS)
    import UIKit
    typealias Font = UIFont
#else
    import AppKit
    typealias Font = NSFont
#endif

extension String
{
    var length:Int
    {
        return characters.count
    }
    
    /**
    func indexOf(val:String) -> Int
    {
        var range:Range<String.Index>? = rangeOfString(val)
        if range == nil
        {
            return -1
        }
        return distance(startIndex, range!.startIndex)
    }

    
    subscript (i: Int) -> Character?
    {
        if i < 0 || i >= length
        {
            return nil
        }
        var index = advance(self.startIndex, i)
        return self[index]
    }
    
    subscript (subRange: Range<Int>) -> String
    {
        let startIndex: String.Index = advance(self.startIndex, max(subRange.startIndex, 0))
        let endIndex: String.Index = advance(self.startIndex, min(subRange.endIndex, length - 1))
        var range:Range<String.Index> = Range<String.Index>(start: startIndex,end: endIndex)
        return self[range]
    }

**/
    
    //文字替换
    //"aaBBcc".replaceString("aa", with:"dd") //ddBBcc
    func replaceString(val:String, with replacement:String, greed:Bool = true) -> String
    {
        var returnString:String = self
        if let range:Range<String.Index> = returnString.rangeOfString(val)
        {
            returnString.replaceRange(range, with: replacement)
            if greed
            {
                returnString = returnString.replaceString(val, with: replacement, greed: true)
            }
        }
        return returnString
    }
    
}

public class StringUtil:NSObject
{
    //获取随机字符
    class func getUniqid(length:Int)->String
    {
        let CHARS:[String] = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9"]
        var uniqid:String = "";
        var index:Int = 0
        for _ in 0..<length
        {
            index = Int(arc4random_uniform(UInt32(CHARS.count)))
            uniqid += CHARS[index];
        }
        return uniqid;
    }
    
    
    
    //版本号比较
    //operation操作符(< <= == >= >)
    //如果符合条件，返回true
    public class func versionCompare(lhs:String, rhs:String, operation:String) -> Bool
    {
        let result:NSComparisonResult = lhs.compare(rhs, options: NSStringCompareOptions.NumericSearch)
        switch operation
        {
        case "<":
            return result == NSComparisonResult.OrderedAscending
        case "<=":
            return result == NSComparisonResult.OrderedAscending || result == NSComparisonResult.OrderedSame
        case "==":
            return result == NSComparisonResult.OrderedSame
        case ">=":
            return result == NSComparisonResult.OrderedDescending || result == NSComparisonResult.OrderedSame
        case ">" :
            return result == NSComparisonResult.OrderedDescending
        default:
            return false
        }
    }
    
    //获取已知文字在限定宽度内布局后的高度
    class func getStringHeight(text:String, font:Font, width:CGFloat, lineSpacing:CGFloat = 2) -> CGFloat
    {
        let size = CGSizeMake(width, CGFloat.max)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .ByWordWrapping;
        paragraphStyle.lineSpacing = lineSpacing
        let  attributes = [NSFontAttributeName:font,
            NSParagraphStyleAttributeName:paragraphStyle.copy()]
        let rect = text.boundingRectWithSize(size, options:.UsesLineFragmentOrigin, attributes: attributes, context:nil)
        return rect.size.height
    }
    
    //获取已知文字单行的宽度
    class func getStringWidth(text:String, font:Font) -> CGFloat
    {
        let size = CGSizeMake(CGFloat.max, CGFloat.max)
        let attributes = [NSFontAttributeName:font]
        let rect = text.boundingRectWithSize(size, options:.UsesLineFragmentOrigin, attributes: attributes, context:nil)
        return rect.size.width
    }
    
    
}