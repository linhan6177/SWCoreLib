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
    private static var __once: () = { Static.instance = SimpleCookie(user: "userData") }()
    var userDefaults:UserDefaults?
    var userData:[AnyHashable: Any]?
    
    class func shared()->SimpleCookie
    {
        struct Static {
            static var instance : SimpleCookie? = nil
            static var token : Int = 0
        }
        _ = SimpleCookie.__once
        
        return Static.instance!
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
    
    func getObject(_ key:String!) -> AnyObject?
    {
        let obj:AnyObject? = userData?[key] as AnyObject?
        return obj
    }
    
    
    func setObject(_ anObject: AnyObject?, forKey key:String)
    {
        userData?[key] = anObject
        userDefaults?.set(userData, forKey:"UserData")
        userDefaults?.synchronize()
    }
    
    
    
    
    
    
    
    
    
    
}
