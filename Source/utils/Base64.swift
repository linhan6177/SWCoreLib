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
    class func encode(_ string:String) -> String
    {
        guard let data = string.data(using: String.Encoding.utf8) else{
            return ""
        }
        let baseData:Data = data.base64EncodedData(options: NSData.Base64EncodingOptions.endLineWithLineFeed)
        return  String(data: baseData, encoding: String.Encoding.utf8) ?? ""
    }
    
    class func decode(_ string:String)->String
    {
        guard let data:Data = Data(base64Encoded: string, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) else{
            return ""
        }
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }
}
