//
//  CoreFoundationExtension.swift
//  uicomponetTest3
//
//  Created by linhan on 15/10/26.
//  Copyright © 2015年 linhan. All rights reserved.
//

import Foundation

extension FloatingPoint
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
        //return round(self)
        return rounded()
    }
}

extension Double
{
    var roundValue:Double{
        //return round(self)
        return rounded()
    }
}

extension String
{
    var length:Int
    {
        return characters.count
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
        let raw: NSString = self as NSString
        let legalURLCharactersToBeEscaped: CFString = ":&=;+!@#$()',*" as CFString
        return CFURLCreateStringByAddingPercentEscapes(nil, raw, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
    
    public var URLDecoded:String{
        get{
            var output:String = self
            output = output.replacingOccurrences(of: "+", with: " ", options: NSString.CompareOptions.literal, range: nil)
            return output.removingPercentEncoding ?? self
        }
    }
    
    //字符串分割
    public func split(_ delimiter:String) -> [String]
    {
        var collection:[String] = []
        let sequences = self.characters.split(separator: delimiter.characters.first ?? Character(" "), maxSplits: Int.max, omittingEmptySubsequences: false)
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
    public func valueAt(_ index:Int) -> Element?
    {
        if index >= 0 && index < self.count
        {
            return self[index]
        }
        return nil
    }
    
    //安全的移除某个元素
    @discardableResult
    public mutating func removeAtIndexSafely(_ index:Int) -> Element?
    {
        if index >= 0 && index < self.count && self.count > 0
        {
            return remove(at: index)
        }
        return nil
    }
    
    public mutating func insertSafely(_ newElement:Element, atIndex index:Int)
    {
        if index >= 0 && index <= self.count
        {
            insert(newElement, at: index)
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
    public func contains(_ range:NSRange) -> Bool
    {
        return range.location >= location && range.destination <= destination
    }
}

extension URL
{
    //获取path所在的目录(~cache/data/a.png -> ~cache/data)
    public var directoryPath:String {
        if !isFileURL
        {
            return path ?? ""
        }
        let text:String = path ?? absoluteString
        let textRange = NSRange(location: 0, length: text.characters.count)
        let reg = try? NSRegularExpression(pattern: "^((\\w)?:)?([^.]+)?(\\.(\\w+)?)?", options: [])
        let result = reg?.firstMatch(in: text, options: [], range: textRange)
        if let range = result?.rangeAt(3) , textRange.contains(range)
        {
            
            let separator:String = text.contains("\\") ? "\\" : "/"
            let sequences = (text as NSString).substring(with: range).characters.split(separator: "/", maxSplits: Int.max, omittingEmptySubsequences: false)
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



extension DispatchQueue
{
    class var globalDefault:DispatchQueue{
        return DispatchQueue.global(priority: .default)
    }
}







