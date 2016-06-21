//
//  PinYin.swift
//  Bus
//
//  Created by linhan on 14-10-28.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
class PinYin:NSObject
{
    //POAPinyin
    
    //转换为拼音（转换后,是否成功）
    //stripDiacritics  是否去掉拼音升调降调,去掉升降调非常消耗性能，慎用
    class func transform(input:String, stripDiacritics:Bool = true) -> (String,Bool)
    {
        let cf:CFMutableString = NSMutableString(string: input) as CFMutableString
        var success:Bool = CFStringTransform(cf, nil, kCFStringTransformToLatin, false)
        if success && stripDiacritics
        {
            success = CFStringTransform(cf, nil, kCFStringTransformStripDiacritics, false)
        }
        var latin:String = success ? cf as String : input
        latin = latin.lowercaseString
        return (latin, success)
    }
    
    //获取这个字符串拼音的首字母
    class func getFirstLetter(str:String) -> String
    {
        let latin:String = transform(str, stripDiacritics:false).0
        return latin.characters.count > 0 ? (latin as NSString).substringToIndex(1) : ""
    }
    
    //获取每个字的拼音的首字母
    class func getEveryFirstLetter(str:String)->String
    {
        var returnString:String = ""
        for character in str.characters {
            let char = String([character])
            let result = transform(char, stripDiacritics:false)
            let success = result.1
            returnString = returnString + (success ? getFirstLetter(char) : "")
        }
        return returnString
    }
    
    /**
    //获取每个字的拼音的首字母
    class func getEveryFirstLetter(str:String)->String
    {
        var returnString:String = ""
        if count(str) < 1
        {
            return ""
        }
        var nsstring:NSString = str
        for var i:Int = 0; i < nsstring.length; i++
        {
            var char = nsstring.substringWithRange(NSMakeRange(i, 1))
            var pin:NSString = POAPinyin.quickConvert(char)
            returnString = returnString + (pin.length > 0 ? pin.substringToIndex(1) : "")
        }
        return returnString
    }
    
    //获取这个字符串拼音的首字母
    class func getFirstLetter(str:String) -> String
    {
        if count(str) < 1
        {
            return ""
        }
        
        var firstChar = (str as NSString).substringToIndex(1)
        var pin:NSString = POAPinyin.quickConvert(firstChar)
        pin = pin.length > 0 ? pin.substringToIndex(1) : ""
        return pin as String
    }
**/
    
    
    
}