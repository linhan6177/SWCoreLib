//
//  File.swift
//  Basic
//
//  Created by linhan on 14-12-11.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
class NetUtil: NSObject
{
    //type=guichu&a=b
    class func stringToObject(_ string:String, separator:String = "&") -> [String:Any]
    {
        var o:[String:Any] = [:]
        let nsstring:NSString = string as NSString
        var arr:[String] = nsstring.components(separatedBy: separator) 
        let n:Int = arr.count
        for i in 0..<n
        {
            var pieces:[String] = arr[i].components(separatedBy: "=") as [String]
            if pieces.count > 1
            {
                let name:String = pieces[0]
                let value:String = pieces[1]
                if value == "true"
                {
                    o[name] = true
                }
                else if value == "false"
                {
                    o[name] = false
                }
                else
                {
                    let tempInt:Int = (value as NSString).integerValue
                    let tempDouble:Double = (value as NSString).doubleValue
                    if value == "\(tempInt)"
                    {
                        o[name] = tempInt
                    }
                    else if value == "\(tempDouble)"
                    {
                        o[name] = tempDouble
                    }
                    else
                    {
                        o[name] = value
                    }
                }
                
            }
        }
        return o
        
    }
    
    class func getQuery(_ url:URL) -> [String:String]
    {
        var params:[String:String] = [:]
        if #available(iOS 8.0, *) {
            let component:URLComponents? = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let queryItems = component?.queryItems
            {
                for queryItem in queryItems
                {
                    params[queryItem.name] = queryItem.value ?? ""
                }
            }
        }
        else {
            let obj = stringToObject(url.query?.URLDecoded ?? "")
            for (key,value) in obj
            {
                params[key] = "\(value)"
            }
        }
        return params
    }
    
    
    
}
