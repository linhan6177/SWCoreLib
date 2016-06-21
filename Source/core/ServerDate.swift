//
//  ServerDate.swift
//  Basic
//
//  Created by linhan on 15-5-7.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
class ServerDate
{
    static private var _serverTime:Double = 0
    
    //接到服务器时间时，iOS 已经初始化后并运行的时间
    static private var _runTime:Double = 0
    
    //服务端时间，以毫秒为单位
    static var serverTime:Double
    {
        get
        {
            return _serverTime + (NSDate().timeIntervalSince1970 * 1000) - _runTime
        }
        set
        {
            _serverTime = newValue
            _runTime = NSDate().timeIntervalSince1970 * 1000
        }
    }
    
    static var date:NSDate
    {
        return NSDate(timeIntervalSince1970: serverTime)
    }
    
    
}

