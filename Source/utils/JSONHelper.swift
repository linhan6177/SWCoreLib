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
    class func JSONEncode(_ obj:AnyObject) -> String
    {
        var returnString:String = ""
        let jsonData:Data? = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
        if let data = jsonData
        {
            returnString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        }
        return returnString
    }
}
