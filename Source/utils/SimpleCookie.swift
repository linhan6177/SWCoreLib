//
//  SimpleCookie.swift
//  GoldAssistant
//
//  Created by linhan on 14-7-9.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
class SimpleCookie:NSObject
{
    var userDefaults:NSUserDefaults?
    var userData:[NSObject:AnyObject]?
    
    class func shared()->SimpleCookie
    {
        struct Static {
            static var instance : SimpleCookie? = nil
            static var token : dispatch_once_t = 0
        }
        dispatch_once(&Static.token)
            { Static.instance = SimpleCookie(user: "userData") }
        
        return Static.instance!
    }
    
    init(user username: String!)
    {
        super.init()
        
        userDefaults = NSUserDefaults(suiteName:username)
        if let data = userDefaults?.objectForKey("UserData") as? [NSObject:AnyObject]
        {
            userData = data
        }
        else
        {
            userData = Dictionary()
        }
    }
    
    
    //是否包含某个键值
    /**
    func contains(key:String)->Bool
    {
        var has:Bool = false
        var keys = userData!.keys
        for akey : AnyObject in keys
        {
            if String(akey as NSString) == key
            {
                has = true
                break;
            }
        }
        return has
    }
**/
    
    func getObject(key:String!) -> AnyObject?
    {
        let obj:AnyObject? = userData?[key]
        return obj
    }
    
    
    func setObject(anObject: AnyObject?, forKey key:String)
    {
        userData?[key] = anObject
        userDefaults?.setObject(userData, forKey:"UserData")
        userDefaults?.synchronize()
    }
    
    
    
    
    
    
    
    
    
    
}