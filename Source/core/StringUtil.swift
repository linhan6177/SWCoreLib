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
    typealias SWFont = UIFont
#else
    import AppKit
    typealias SWFont = NSFont
#endif

extension String
{
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
    func replaceString(_ val:String, with replacement:String, greed:Bool = true) -> String
    {
        var returnString:String = self
        if let range:Range<String.Index> = returnString.range(of: val)
        {
            returnString.replaceSubrange(range, with: replacement)
            if greed
            {
                returnString = returnString.replaceString(val, with: replacement, greed: true)
            }
        }
        return returnString
    }
    
}

open class StringUtil:NSObject
{
    //获取随机字符
    class func getUniqid(_ length:Int)->String
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
    open class func versionCompare(_ lhs:String, rhs:String, operation:String) -> Bool
    {
        let result:ComparisonResult = lhs.compare(rhs, options: NSString.CompareOptions.numeric)
        switch operation
        {
        case "<":
            return result == ComparisonResult.orderedAscending
        case "<=":
            return result == ComparisonResult.orderedAscending || result == ComparisonResult.orderedSame
        case "==":
            return result == ComparisonResult.orderedSame
        case ">=":
            return result == ComparisonResult.orderedDescending || result == ComparisonResult.orderedSame
        case ">" :
            return result == ComparisonResult.orderedDescending
        default:
            return false
        }
    }
    
    //获取已知文字在限定宽度内布局后的高度
    class func getStringHeight(_ text:String, font:SWFont, width:CGFloat, lineSpacing:CGFloat = 2) -> CGFloat
    {
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping;
        paragraphStyle.lineSpacing = lineSpacing
        let  attributes = [NSFontAttributeName:font,
            NSParagraphStyleAttributeName:paragraphStyle.copy()]
        let rect = text.boundingRect(with: size, options:.usesLineFragmentOrigin, attributes: attributes, context:nil)
        return rect.size.height
    }
    
    //获取已知文字单行的宽度
    class func getStringWidth(_ text:String, font:SWFont) -> CGFloat
    {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let attributes = [NSFontAttributeName:font]
        let rect = text.boundingRect(with: size, options:.usesLineFragmentOrigin, attributes: attributes, context:nil)
        return rect.size.width
    }
    
    
}
