//
//  Base64.swift
//  iosapphello
//
//  Created by linhan on 14-8-7.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
open class Base64:NSObject
{
    class func encode(_ string:String)->String
    {
        let data:Data = string.data(using: String.Encoding.utf8)!
        let baseData:Data = data.base64EncodedData(options: NSData.Base64EncodingOptions.endLineWithLineFeed)
        
        return  NSString(data:baseData, encoding:String.Encoding.utf8.rawValue)! as String
    }
    
    class func decode(_ string:String)->String
    {
        let data:Data = Data(base64Encoded: string, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
        
        return NSString(data:data, encoding:String.Encoding.utf8.rawValue) as? String ?? ""
    }
}
