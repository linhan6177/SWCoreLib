//
//  DateUtil.swift
//  Basic
//
//  Created by linhan on 15-5-18.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation

extension Date
{
    var DefaultFormat:String
    {
        return "YYYY-MM-dd HH:mm:SS"
    }
    
    //日期格式化
    func format(_ dateFormat:String = "YYYY-MM-dd HH:mm:SS") -> String
    {
        let formatter:DateFormatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: self)
    }
    
    //完整年份值
    var fullYear:Int
    {
        return (Calendar.current as NSCalendar).components([NSCalendar.Unit.year, NSCalendar.Unit.month], from: self).year!
    }
    
    //月份值（0 代表一月，1 代表二月，依此类推）。
    var month:Int
    {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.month, from: self).month!
    }
    
    //月中某天的值（1 到 31 之间的一个整数）
    var day:Int
    {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.day, from: self).day!
    }
    
    //（1 代表星期一，依此类推）。
    var weekday:Int
    {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.weekday, from: self).weekdayOrdinal!
    }
    
    //一天的小时值（0 到 23 之间的一个整数）
    var hours:Int
    {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.hour, from: self).hour!
    }
    
    //分钟值（0 到 59 之间的一个整数）部分。
    var minutes:Int
    {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.minute, from: self).minute!
    }
    
    //秒值（0 到 59 之间的一个整数）。
    var seconds:Int
    {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.second, from: self).second!
    }
    
    
}

class DateUtil: NSObject
{
    
    
    
    //用口语形式返回目标时间与现在时间的差距
    //time 目标时间（自1970年以来的秒数）
    //now 现在时间（自1970年以来的秒数）
    class func formatSinceDate(_ time:Double, now:Double = 0) -> String
    {
        var string:String = ""
        let nowTime:Double = now == 0 ? Date().timeIntervalSince1970 : now
        let second:Double = nowTime - time
        if second < 60
        {
            string = "刚刚"
        }
        else if second < 3600
        {
            string = "\(Int(second / 60))分钟前"
        }
        else if second < 3600 * 24
        {
            //1.8小时折合为2小时,1.1小时折合为1小时
            
            string = "\(Int(ceil(second / 3600)))小时前"
        }
        else if second < 2592000
        {
            
            string = "\(Int(ceil(second / 86400)))天前"
        }
        else if second < 31104000
        {
            string = "\(Int(second / 2592000))个月前"
        }
        else
        {
            string = "\(Int(second / 31104000))年前"
        }
        return string
    }
    
    //根据特定日期文字格式返回日期
    func dateFromString(_ dateString:String, dateFormat:String = "YYYY-MM-dd HH:mm:SS") -> Date?
    {
        let formatter:DateFormatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.date(from: dateString)
    }
    
    
}
