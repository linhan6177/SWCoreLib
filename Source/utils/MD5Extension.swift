//
//  MD5Extension.swift
//  ChildStory
//
//  Created by linhan on 16/8/24.
//  Copyright © 2016年 Aiya. All rights reserved.
//

import Foundation

extension SWMD5
{
    class func md516BitLower(_ string:String) -> String
    {
        return SWMD5.md532BitLower(string).substringWithRange(NSMakeRange(8, 16))
    }
    
    class func md516BitUpper(_ string:String) -> String
    {
        return SWMD5.md532BitUpper(string).substringWithRange(NSMakeRange(8, 16))
    }
}
