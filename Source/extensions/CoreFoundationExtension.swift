//
//  CoreFoundationExtension.swift
//  uicomponetTest3
//
//  Created by linhan on 15/10/26.
//  Copyright © 2015年 linhan. All rights reserved.
//

import Foundation

extension FloatingPointType
{
    //返回浮点数的正常值
    var numberValue:Self{
        return isNormal ? self : Self(0)
    }
    
//    var roundValue:Self{
//        
//        return round(0.0)
//    }
}

extension Float
{
    var roundValue:Float{
        return round(self)
    }
}

extension Double
{
    var roundValue:Double{
        return round(self)
    }
}

extension String
{
    public var intValue:Int {
        return (self as NSString).integerValue
    }
    
    public var doubleValue:Double {
        return (self as NSString).doubleValue
    }
    
    public var URLEncoded:String {
        let raw: NSString = self
        let legalURLCharactersToBeEscaped: CFStringRef = ":&=;+!@#$()',*"
        return CFURLCreateStringByAddingPercentEscapes(nil, raw, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
    
    public var URLDecoded:String{
        get{
            var output:String = self
            output = output.stringByReplacingOccurrencesOfString("+", withString: " ", options: NSStringCompareOptions.LiteralSearch, range: nil)
            return output.stringByRemovingPercentEncoding ?? self
        }
    }
    
    //字符串分割
    public func split(delimiter:String) -> [String]
    {
        var collection:[String] = []
        let sequences = self.characters.split(delimiter.characters.first ?? Character(" "), maxSplit: Int.max, allowEmptySlices: true)
        for seq in sequences
        {
            collection.append(String(seq))
        }
        return collection
    }
    
    
}

extension Array
{
    //安全的获取某个索引内的值
    public func valueAt(index:Int) -> Element?
    {
        if index >= 0 && index < self.count
        {
            return self[index]
        }
        return nil
    }
    
    //安全的移除某个元素
    public mutating func removeAtIndexSafely(index:Int) -> Element?
    {
        if index >= 0 && index < self.count
        {
            return removeAtIndex(index)
        }
        return nil
    }
    
    public mutating func insertSafely(newElement:Element, atIndex index:Int)
    {
        if index >= 0 && index <= self.count
        {
            insert(newElement, atIndex: index)
        }
    }

}



extension NSRange
{
    //终点
    public var destination:Int
        {
            return location + length
    }
    
    //是否包含某个范围
    public func contains(range:NSRange) -> Bool
    {
        return range.location >= location && range.destination <= destination
    }
}

extension NSURL
{
    //获取path所在的目录(~cache/data/a.png -> ~cache/data)
    public var directoryPath:String {
        if !fileURL
        {
            return path ?? ""
        }
        let text:String = path ?? absoluteString
        let textRange = NSRange(location: 0, length: text.characters.count)
        let reg = try? NSRegularExpression(pattern: "^((\\w)?:)?([^.]+)?(\\.(\\w+)?)?", options: [])
        let result = reg?.firstMatchInString(text, options: [], range: textRange)
        if let range = result?.rangeAtIndex(3) where textRange.contains(range)
        {
            
            let separator:String = text.containsString("\\") ? "\\" : "/"
            let sequences = (text as NSString).substringWithRange(range).characters.split("/", maxSplit: Int.max, allowEmptySlices: true)
            var path:String = ""
            for i in 0..<max(sequences.count - 1, 0)
            {
                let directory:String = String(sequences[i])
                path += "\(directory)\(separator)"
            }
            return path
        }
        
        return ""
    }
}









