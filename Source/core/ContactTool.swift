//
//  ContactTool.swift
//  TelephonyExample
//
//  Created by linhan on 15-5-9.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import AddressBook

class ContactTool: NSObject
{
    class func analyzeSysContacts(sysContacts:NSArray) -> [[String:String]] {
        var allContacts:Array = [[String:String]]()
        
        func analyzeContactProperty(contact:ABRecordRef, property:ABPropertyID, keySuffix:String) -> [String:String]? {
            var propertyValues:ABMultiValueRef? = ABRecordCopyValue(contact, property)?.takeRetainedValue()
            if propertyValues != nil {
                var valueDictionary:[String:String] = [String:String]()
                for i in 0 ..< ABMultiValueGetCount(propertyValues) {
                    var label:String = keySuffix + (ABMultiValueCopyLabelAtIndex(propertyValues, i)?.takeRetainedValue() as? String ?? "")
                    var value = ABMultiValueCopyValueAtIndex(propertyValues, i)
                    switch property {
                        // 地址
                    case kABPersonAddressProperty :
                        var addrNSDict:[NSObject:AnyObject] = value.takeRetainedValue() as! [NSObject:AnyObject]
                        
                        valueDictionary[label+"_Country"] = addrNSDict[kABPersonAddressCountryKey] as? String ?? ""
                        valueDictionary[label+"_State"] = addrNSDict[kABPersonAddressStateKey] as? String ?? ""
                        valueDictionary[label+"_City"] = addrNSDict[kABPersonAddressCityKey] as? String ?? ""
                        valueDictionary[label+"_Street"] = addrNSDict[kABPersonAddressStreetKey] as? String ?? ""
                        valueDictionary[label+"_Contrycode"] = addrNSDict[kABPersonAddressCountryCodeKey] as? String ?? ""
                        
                        // 地址整理
                        valueDictionary["fullAddress"] = (valueDictionary[label+"_Country"]! == "" ? valueDictionary[label+"_Contrycode"]! : valueDictionary[label+"_Country"]!) + ", " + valueDictionary[label+"_State"]! + ", " + valueDictionary[label+"_City"]! + ", " + valueDictionary[label+"_Street"]!
                        // SNS
                    case kABPersonSocialProfileProperty :
                        var snsNSDict:[NSObject:AnyObject] = value.takeRetainedValue() as! [NSObject:AnyObject]
                        
                        valueDictionary[label+"_Username"] = snsNSDict[kABPersonSocialProfileUsernameKey] as? String ?? ""
                        valueDictionary[label+"_URL"] = snsNSDict[kABPersonSocialProfileURLKey] as? String ?? ""
                        valueDictionary[label+"_Serves"] = snsNSDict[kABPersonSocialProfileServiceKey] as? String ?? ""
                        // IM
                    case kABPersonInstantMessageProperty :
                        var imNSDict:[NSObject:AnyObject] = value.takeRetainedValue() as! [NSObject:AnyObject]
                        
                        

                        valueDictionary[label+"_Serves"] = imNSDict[kABPersonInstantMessageServiceKey] as? String ?? ""
                        valueDictionary[label+"_Username"] = imNSDict[kABPersonInstantMessageUsernameKey] as? String ?? ""
                        // Date
                    case kABPersonDateProperty :
                        valueDictionary[label] = value != nil ? (value.takeRetainedValue() as? NSDate)?.description : nil
                    default :
                        valueDictionary[label] = value != nil ? value.takeRetainedValue() as? String ?? "" : nil
                    }
                }
                return valueDictionary
            }else{
                return nil
            }
        }
        
        for contact in sysContacts {
            var currentContact:Dictionary = [String:String]()
            
            /*
            部分单值属性
            */
            // 姓、姓氏拼音
            currentContact["FirstName"] = ABRecordCopyValue(contact, kABPersonFirstNameProperty)?.takeRetainedValue() as? String ?? ""
            currentContact["FirstNamePhonetic"] = ABRecordCopyValue(contact, kABPersonFirstNamePhoneticProperty)?.takeRetainedValue() as? String ?? ""
            // 名、名字拼音
            currentContact["LastName"] = ABRecordCopyValue(contact, kABPersonLastNameProperty)?.takeRetainedValue() as? String ?? ""
            currentContact["LirstNamePhonetic"] = ABRecordCopyValue(contact, kABPersonLastNamePhoneticProperty)?.takeRetainedValue() as? String ?? ""
            // 昵称
            currentContact["Nikename"] = ABRecordCopyValue(contact, kABPersonNicknameProperty)?.takeRetainedValue() as? String ?? ""
            
            // 姓名整理
            currentContact["FullName"] = (currentContact["LastName"] ?? "") + (currentContact["FirstName"] ?? "")
            
            // 公司（组织）
            currentContact["Organization"] = ABRecordCopyValue(contact, kABPersonOrganizationProperty)?.takeRetainedValue() as? String ?? ""
            // 职位
            currentContact["JobTitle"] = ABRecordCopyValue(contact, kABPersonJobTitleProperty)?.takeRetainedValue() as? String ?? ""
            // 部门
            currentContact["Department"] = ABRecordCopyValue(contact, kABPersonDepartmentProperty)?.takeRetainedValue() as? String ?? ""
            // 备注
            currentContact["Note"] = ABRecordCopyValue(contact, kABPersonNoteProperty)?.takeRetainedValue() as? String ?? ""
            // 生日（类型转换有问题，不可用）
            //currentContact["Brithday"] = ((ABRecordCopyValue(contact, kABPersonBirthdayProperty)?.takeRetainedValue()) as NSDate).description
            
            /*
            部分多值属性
            */
            // 电话
            for (key, value) in analyzeContactProperty(contact, property: kABPersonPhoneProperty,keySuffix: "Phone") ?? ["":""] {
                currentContact[key] = value
            }
            // E-mail
            for (key, value) in analyzeContactProperty(contact, property: kABPersonEmailProperty, keySuffix: "Email") ?? ["":""] {
                currentContact[key] = value
            }
            // 地址
            for (key, value) in analyzeContactProperty(contact, property: kABPersonAddressProperty, keySuffix: "Address") ?? ["":""] {
                currentContact[key] = value
            }
            // 纪念日
            for (key, value) in analyzeContactProperty(contact, property: kABPersonDateProperty, keySuffix: "Date") ?? ["":""] {
                currentContact[key] = value
            }
            // URL
            for (key, value) in analyzeContactProperty(contact, property: kABPersonURLProperty, keySuffix: "URL") ?? ["":""] {
                currentContact[key] = value
            }
            // SNS
            for (key, value) in analyzeContactProperty(contact, property: kABPersonSocialProfileProperty, keySuffix: "_SNS") ?? ["":""] {
                currentContact[key] = value
            }
            
            allContacts.append(currentContact)
        }
        
        return allContacts
    }
    
}