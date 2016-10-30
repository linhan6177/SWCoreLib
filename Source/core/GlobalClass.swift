//
//  GlobalClass.swift
//  uicomponetTest3
//
//  Created by linhan on 15-5-9.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
#if os(iOS)
   import UIKit
#endif

#if os(iOS)
private var _ios8:Bool?
public var iOS8:Bool
{
    if _ios8 == nil
    {
        _ios8 = (UIDevice.currentDevice().systemVersion as NSString).floatValue >= 8
    }
    return _ios8!
}
#endif

typealias SetTimeoutCallbackHandler = () -> Void
typealias SetTimeoutWithArgsCallbackHandler = ([NSObject:AnyObject]?) -> Void
struct SWGlobalStaticClass
{
    
    static var timers:[TimerObject] = []
}

class TimerObject
{
    var id:String
    var callback:SetTimeoutCallbackHandler?
    var callbackWithArgs:SetTimeoutWithArgsCallbackHandler?
    //weak var timer:NSTimer?
    var timer:MSWeakTimer?
    
    
    init(id:String, callback:SetTimeoutCallbackHandler?, callbackWithArgs:SetTimeoutWithArgsCallbackHandler?)
    {
        self.id = id
        self.callback = callback
        self.callbackWithArgs = callbackWithArgs
    }
    
    deinit
    {
        //print("TimerObject deinit")
    }
    
    func invalidate()
    {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func delay(timer:NSTimer)
    {
        let args:[NSObject:AnyObject]? = timer.userInfo as? [NSObject:AnyObject]
        if args != nil
        {
            callbackWithArgs?(args!)
        }
        else
        {
            callback?()
        }
        clearTimeout(id)
    }
    
    @objc private func interval(timer:NSTimer)
    {
        let args:[NSObject:AnyObject]? = timer.userInfo as? [NSObject:AnyObject]
        if args != nil
        {
            callbackWithArgs?(args!)
        }
        else
        {
            callback?()
        }
    }
}

func setTimeout(delay:Double, closure:SetTimeoutCallbackHandler) -> String
{
    let id:String = StringUtil.getUniqid(10)
    let timerObject:TimerObject = TimerObject(id: id, callback: closure, callbackWithArgs:nil)
//    dispatch_async(dispatch_get_main_queue(), {
//        timerObject.timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: timerObject, selector: #selector(TimerObject.delay(_:)), userInfo: nil, repeats: false)
//    })
    timerObject.timer = MSWeakTimer.scheduledTimerWithTimeInterval(delay, target: timerObject, selector: #selector(TimerObject.delay(_:)), userInfo: nil, repeats: false, dispatchQueue: dispatch_get_main_queue())
    SWGlobalStaticClass.timers.append(timerObject)
    return id
}

func setTimeoutWithArgs(delay:Double, closure:SetTimeoutWithArgsCallbackHandler, args:[NSObject:AnyObject]) -> String
{
    let id:String = StringUtil.getUniqid(10)
    let timerObject:TimerObject = TimerObject(id: id, callback: nil, callbackWithArgs:closure)
//    dispatch_async(dispatch_get_main_queue(), {
//        timerObject.timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: timerObject, selector: #selector(TimerObject.delay(_:)), userInfo: args, repeats: false)
//    })
    timerObject.timer = MSWeakTimer.scheduledTimerWithTimeInterval(delay, target: timerObject, selector: #selector(TimerObject.delay(_:)), userInfo: nil, repeats: false, dispatchQueue: dispatch_get_main_queue())
    SWGlobalStaticClass.timers.append(timerObject)
    return id
}

func setInterval(delay:Double, closure:SetTimeoutCallbackHandler) -> String
{
    let id:String = StringUtil.getUniqid(10)
    let timerObject:TimerObject = TimerObject(id: id, callback: closure, callbackWithArgs:nil)
//    dispatch_async(dispatch_get_main_queue(), {
//        timerObject.timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: timerObject, selector: #selector(TimerObject.interval(_:)), userInfo: nil, repeats: true)
//    })
    timerObject.timer = MSWeakTimer.scheduledTimerWithTimeInterval(delay, target: timerObject, selector: #selector(TimerObject.interval(_:)), userInfo: nil, repeats: true, dispatchQueue: dispatch_get_main_queue())
    SWGlobalStaticClass.timers.append(timerObject)
    return id
}

func setIntervalWithArgs(delay:Double, closure:SetTimeoutWithArgsCallbackHandler, args:[NSObject:AnyObject]) -> String
{
    let id:String = StringUtil.getUniqid(10)
    let timerObject:TimerObject = TimerObject(id: id, callback: nil, callbackWithArgs:closure)
//    dispatch_async(dispatch_get_main_queue(), {
//        timerObject.timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: timerObject, selector: #selector(TimerObject.interval(_:)), userInfo: args, repeats: true)
//    })
    timerObject.timer = MSWeakTimer.scheduledTimerWithTimeInterval(delay, target: timerObject, selector: #selector(TimerObject.interval(_:)), userInfo: nil, repeats: true, dispatchQueue: dispatch_get_main_queue())
    SWGlobalStaticClass.timers.append(timerObject)
    return id
}

func clearInterval(id:String)
{
    clearTimeout(id)
}

func clearTimeout(id:String)
{
    if id != ""
    {
        let count:Int = SWGlobalStaticClass.timers.count
        for i in (0..<count).reverse()
        {
            let timerObject = SWGlobalStaticClass.timers[i]
            if timerObject.id == id
            {
                timerObject.invalidate()
                SWGlobalStaticClass.timers.removeAtIndex(i)
            }
        }
    }
}

//Struct、Enum等Any值的包装器，用于Notification值传递
class SWAnyWrapper<T>
{
    var value:T
    init(value:T)
    {
        self.value = value
    }
}





