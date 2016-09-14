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
    static fileprivate var _serverTime:Double = 0
    
    //接到服务器时间时，iOS 已经初始化后并运行的时间
    static fileprivate var _runTime:Double = 0
    
    //服务端时间，以毫秒为单位
    static var serverTime:Double
    {
        get
        {
            return _serverTime + (Date().timeIntervalSince1970 * 1000) - _runTime
        }
        set
        {
            _serverTime = newValue
            _runTime = Date().timeIntervalSince1970 * 1000
        }
    }
    
    static var date:Date
    {
        return Date(timeIntervalSince1970: serverTime)
    }
    
    
}

