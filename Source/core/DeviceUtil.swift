//
//  DeviceUtil.swift
//  Basic
//
//  Created by linhan on 15-5-11.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit
class DeviceUtil: NSObject
{
    
    
    class var UDID:String
    {
        return UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
    }
    
    
    
}