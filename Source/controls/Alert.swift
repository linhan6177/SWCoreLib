//
//  Alert.swift
//  uicomponetTest3
//
//  Created by linhan on 15-5-9.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit

class Alert:NSObject,UIAlertViewDelegate
{
    var showCloseHandler:((Int)->Void)?
    var inputCloseHandler:((Int, [String])->Void)?
    weak var view:UIAlertView?
    
    struct Alerts
    {
        static var alerts:[Alert] = []
    }
    
    
    class func show(_ title:String = "", message:String = "", buttons:[String] = [], closeHandler:((Int)->Void)? = nil)
    {
        let alertDelegate:Alert = Alert()
        Alerts.alerts.append(alertDelegate)
        alertDelegate.showCloseHandler = closeHandler
        
        let alertView:UIAlertView = UIAlertView()
        alertView.title = title
        alertView.message = message
        alertView.delegate = alertDelegate
        alertDelegate.view = alertView
        if buttons.count > 0
        {
            for i in 0..<buttons.count
            {
                alertView.addButton(withTitle: buttons[i])
            }
        }
        else
        {
            alertView.addButton(withTitle: "确定")
        }
        alertView.show()
    }
    
    //prompt为输入框的placeholder
    class func input(_ title:String = "", message:String = "", prompt:String = "", buttons:[String] = [], type:UIAlertViewStyle = UIAlertViewStyle.plainTextInput, closeHandler:((Int, [String])->Void)? = nil)
    {
        let alertDelegate:Alert = Alert()
        Alerts.alerts.append(alertDelegate)
        alertDelegate.inputCloseHandler = closeHandler
        
        let alertView:UIAlertView = UIAlertView()
        alertView.title = title
        alertView.message = message
        alertView.delegate = alertDelegate
        alertView.alertViewStyle = type
        alertDelegate.view = alertView
        if buttons.count > 0
        {
            for i in 0..<buttons.count
            {
                alertView.addButton(withTitle: buttons[i])
            }
        }
        else
        {
            alertView.addButton(withTitle: "确定")
        }
        
        if let textField = alertView.textField(at: 0)
        {
            textField.placeholder = prompt
        }
        
        alertView.show()
    }
    
    deinit
    {
        //println("Alert Deinit")
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int)
    {
        if let alert = view , alert.alertViewStyle != UIAlertViewStyle.default
        {
            let text:String? = alert.textField(at: 0)?.text ?? ""
            inputCloseHandler?(buttonIndex, [text!])
        }
        else
        {
            showCloseHandler?(buttonIndex)
        }
    }
    
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) // after animation
    {
        showCloseHandler = nil
        inputCloseHandler = nil
        view?.delegate = nil
        view = nil
        
        for i in (0..<Alerts.alerts.count).reversed()
        {
            if Alerts.alerts[i] == self
            {
                //移除
                Alerts.alerts.remove(at: i)
            }
        }
    }
    
}


class ActionSheet:NSObject,UIActionSheetDelegate
{
    var showCloseHandler:((Int)->Void)?
    weak var view:UIActionSheet?
    
    struct ActionSheets
    {
        static var actionSheets:[ActionSheet] = []
    }
    
    
    class func show(_ title:String, buttons:[String], closeHandler:@escaping ((Int)->Void), destructiveButtonIndex:Int = -1, cancelButtonIndex:Int = -1, container:UIView? = nil)
    {
        let delegate:ActionSheet = ActionSheet()
        ActionSheets.actionSheets.append(delegate)
        delegate.showCloseHandler = closeHandler
        
        let actionSheet:UIActionSheet = UIActionSheet()
        actionSheet.title = title
        actionSheet.delegate = delegate
        actionSheet.actionSheetStyle = UIActionSheetStyle.default;
        delegate.view = actionSheet
        if buttons.count > 0
        {
            for i in 0..<buttons.count
            {
                actionSheet.addButton(withTitle: buttons[i])
            }
        }
        else
        {
            actionSheet.addButton(withTitle: "确定")
        }
        
        if destructiveButtonIndex >= 0 && destructiveButtonIndex < buttons.count
        {
            actionSheet.destructiveButtonIndex = destructiveButtonIndex
        }
        if cancelButtonIndex >= 0 && cancelButtonIndex < buttons.count
        {
            actionSheet.cancelButtonIndex = cancelButtonIndex
        }
        
        if let container = container ?? UIApplication.shared.keyWindow
        {
            actionSheet.show(in: container)
        }
    }
    
    deinit
    {
        //println("ActionSheet Deinit")
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int)
    {
        //showCloseHandler?(buttonIndex)
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int)
    {
        showCloseHandler?(buttonIndex)
        
        showCloseHandler = nil
        view?.delegate = nil
        view = nil
        
        for i in (0..<ActionSheets.actionSheets.count).reversed()
        {
            if ActionSheets.actionSheets[i] == self
            {
                //移除
                ActionSheets.actionSheets.remove(at: i)
            }
        }
    }
    
}
