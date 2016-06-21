//
//  Base64.swift
//  iosapphello
//
//  Created by linhan on 14-8-7.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
public class Base64:NSObject
{
    class func encode(string:String)->String
    {
        let data:NSData = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let baseData:NSData = data.base64EncodedDataWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed)
        
        return  NSString(data:baseData, encoding:NSUTF8StringEncoding)! as String
    }
    
    class func decode(string:String)->String
    {
        let data:NSData = NSData(base64EncodedString: string, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
        
        return NSString(data:data, encoding:NSUTF8StringEncoding) as? String ?? ""
    }
}