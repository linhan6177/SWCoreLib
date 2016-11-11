//
//  SimpleCookie.swift
//  GoldAssistant
//
//  Created by linhan on 14-7-9.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
private var _instance = SimpleCookie(user:"UserData")
class SimpleCookie:NSObject
{
    var userDefaults:UserDefaults?
    var userData:[AnyHashable: Any]?
    
    class func shared() -> SimpleCookie
    {
        return _instance
    }
    
    init(user username: String!)
    {
        super.init()
        
        userDefaults = UserDefaults(suiteName:username)
        if let data = userDefaults?.object(forKey: "UserData") as? [AnyHashable: Any]
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
    
    func getObject(_ key:String!) -> Any?
    {
        let obj:Any? = userData?[key] as Any?
        return obj
    }
    
    
    func setObject(_ anObject: Any?, forKey key:String)
    {
        userData?[key] = anObject
        userDefaults?.set(userData, forKey:"UserData")
        userDefaults?.synchronize()
    }
    
    
    
    
    
    
    
    
    
    
}
