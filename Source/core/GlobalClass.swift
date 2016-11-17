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
        _ios8 = (UIDevice.current.systemVersion as NSString).floatValue >= 8
    }
    return _ios8!
}
#endif

typealias SetTimeoutCallbackHandler = () -> Void
typealias SetTimeoutWithArgsCallbackHandler = ([AnyHashable: Any]?) -> Void
struct SWGlobalStaticClass
{
    
    static var timers:[TimerObject] = []
}

class TimerObject
{
    var id:String
    var callback:SetTimeoutCallbackHandler?
    var callbackWithArgs:SetTimeoutWithArgsCallbackHandler?
    var timer:MSWeakTimer?
    
    
    init(id:String, callback:SetTimeoutCallbackHandler?, callbackWithArgs:SetTimeoutWithArgsCallbackHandler?)
    {
        self.id = id
        self.callback = callback
        //self.callback = {callback?()}
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
    
    @objc func delay(_ timer:Timer)
    {
        let args:[AnyHashable: Any]? = timer.userInfo as? [AnyHashable: Any]
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
    
    @objc func interval(_ timer:Timer)
    {
        let args:[AnyHashable: Any]? = timer.userInfo as? [AnyHashable: Any]
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

@discardableResult
func setTimeout(_ delay:Double, closure: @escaping SetTimeoutCallbackHandler) -> String
{
    let id:String = StringUtil.getUniqid(10)
    let timerObject:TimerObject = TimerObject(id: id, callback: closure, callbackWithArgs:nil)
    timerObject.timer = MSWeakTimer.scheduledTimer(withTimeInterval: delay, target: timerObject, selector: #selector(TimerObject.delay(_:)), userInfo: nil, repeats: false, dispatchQueue: DispatchQueue.main)
    SWGlobalStaticClass.timers.append(timerObject)
    return id
}

@discardableResult
func setInterval(_ delay:Double, closure:@escaping SetTimeoutCallbackHandler) -> String
{
    let id:String = StringUtil.getUniqid(10)
    let timerObject:TimerObject = TimerObject(id: id, callback: closure, callbackWithArgs:nil)
    timerObject.timer = MSWeakTimer.scheduledTimer(withTimeInterval: delay, target: timerObject, selector: #selector(TimerObject.interval(_:)), userInfo: nil, repeats: true, dispatchQueue: DispatchQueue.main)
    SWGlobalStaticClass.timers.append(timerObject)
    return id
}

func clearInterval(_ id:String)
{
    clearTimeout(id)
}

func clearTimeout(_ id:String)
{
    if id != ""
    {
        let count:Int = SWGlobalStaticClass.timers.count
        for i in (0..<count).reversed()
        {
            let timerObject = SWGlobalStaticClass.timers[i]
            if timerObject.id == id
            {
                timerObject.invalidate()
                SWGlobalStaticClass.timers.remove(at: i)
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





