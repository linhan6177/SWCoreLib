//
//  CoreFoundationExtension.swift
//  此类为自定义运算符的拓展
//
//  Created by linhan on 15/10/26.
//  Copyright © 2015年 linhan. All rights reserved.
//

import Foundation




//严格匹配 "" ??? "aaa" 结果："aaa"
infix operator ??? {associativity left precedence 130}

func ???<T>(optional: T?, defaultValue:  @autoclosure () -> T) -> T
{
    switch optional
    {
        case .some(let value):
            if sw_valueEmpty(value) {
                return defaultValue()
            }
            return value
        case .none:
            return defaultValue()
    }
}

func ???<T>(optional: T?, defaultValue:  @autoclosure () -> T?) -> T?
{
    switch optional
    {
    case .some(let value):
        if sw_valueEmpty(value) {
            return defaultValue()
        }
        return value
    case .none:
        return defaultValue()
    }
}

//值为""、0时表示空
private func sw_valueEmpty<T>(_ value:T) -> Bool
{
    if let string = value as? String , string == "" {
        return true
    }
    //Int \ Float \ Double
    else if let number = value as? NSNumber , number.doubleValue == 0 {
        return true
    }
    else if let value = value as? UInt8 , value == 0 {
        return true
    }
    else if let value = value as? Int8 , value == 0 {
        return true
    }
    else if let value = value as? UInt16 , value == 0 {
        return true
    }
    else if let value = value as? Int16 , value == 0 {
        return true
    }
    else if let value = value as? UInt32 , value == 0 {
        return true
    }
    else if let value = value as? Int32 , value == 0 {
        return true
    }
    else if let value = value as? UInt64 , value == 0 {
        return true
    }
    else if let value = value as? Int64 , value == 0 {
        return true
    }
    return false
}




