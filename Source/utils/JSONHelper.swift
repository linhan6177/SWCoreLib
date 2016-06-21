//
//  JSONHelper.swift
//  MiU
//
//  Created by linhan on 15/11/23.
//  Copyright © 2015年 MiU. All rights reserved.
//

import Foundation
class JSONHelper: NSObject
{
    class func JSONEncode(obj:AnyObject) -> String
    {
        var returnString:String = ""
        let jsonData:NSData? = try? NSJSONSerialization.dataWithJSONObject(obj, options: .PrettyPrinted)
        if let data = jsonData
        {
            returnString = NSString(data: data, encoding: NSUTF8StringEncoding) as? String ?? ""
        }
        return returnString
    }
}