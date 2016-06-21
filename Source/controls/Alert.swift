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
    
    
    class func show(title:String = "", message:String = "", buttons:[String] = [], closeHandler:((Int)->Void)? = nil)
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
                alertView.addButtonWithTitle(buttons[i])
            }
        }
        else
        {
            alertView.addButtonWithTitle("确定")
        }
        alertView.show()
    }
    
    //prompt为输入框的placeholder
    class func input(title:String = "", message:String = "", prompt:String = "", buttons:[String] = [], type:UIAlertViewStyle = UIAlertViewStyle.PlainTextInput, closeHandler:((Int, [String])->Void)? = nil)
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
                alertView.addButtonWithTitle(buttons[i])
            }
        }
        else
        {
            alertView.addButtonWithTitle("确定")
        }
        
        if let textField = alertView.textFieldAtIndex(0)
        {
            textField.placeholder = prompt
        }
        
        alertView.show()
    }
    
    deinit
    {
        //println("Alert Deinit")
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int)
    {
        if let alert = view where alert.alertViewStyle != UIAlertViewStyle.Default
        {
            let text:String? = alert.textFieldAtIndex(0)?.text ?? ""
            inputCloseHandler?(buttonIndex, [text!])
        }
        else
        {
            showCloseHandler?(buttonIndex)
        }
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) // after animation
    {
        showCloseHandler = nil
        inputCloseHandler = nil
        view?.delegate = nil
        view = nil
        
        for i in (0..<Alerts.alerts.count).reverse()
        {
            if Alerts.alerts[i] == self
            {
                //移除
                Alerts.alerts.removeAtIndex(i)
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
    
    
    class func show(title:String, buttons:[String], closeHandler:((Int)->Void), destructiveButtonIndex:Int = -1, cancelButtonIndex:Int = -1, container:UIView? = nil)
    {
        let delegate:ActionSheet = ActionSheet()
        ActionSheets.actionSheets.append(delegate)
        delegate.showCloseHandler = closeHandler
        
        let actionSheet:UIActionSheet = UIActionSheet()
        actionSheet.title = title
        actionSheet.delegate = delegate
        actionSheet.actionSheetStyle = UIActionSheetStyle.Default;
        delegate.view = actionSheet
        if buttons.count > 0
        {
            for i in 0..<buttons.count
            {
                actionSheet.addButtonWithTitle(buttons[i])
            }
        }
        else
        {
            actionSheet.addButtonWithTitle("确定")
        }
        
        if destructiveButtonIndex >= 0 && destructiveButtonIndex < buttons.count
        {
            actionSheet.destructiveButtonIndex = destructiveButtonIndex
        }
        if cancelButtonIndex >= 0 && cancelButtonIndex < buttons.count
        {
            actionSheet.cancelButtonIndex = cancelButtonIndex
        }
        
        if let container = container ?? UIApplication.sharedApplication().keyWindow
        {
            actionSheet.showInView(container)
        }
    }
    
    deinit
    {
        //println("ActionSheet Deinit")
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int)
    {
        //showCloseHandler?(buttonIndex)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int)
    {
        showCloseHandler?(buttonIndex)
        
        showCloseHandler = nil
        view?.delegate = nil
        view = nil
        
        for i in (0..<ActionSheets.actionSheets.count).reverse()
        {
            if ActionSheets.actionSheets[i] == self
            {
                //移除
                ActionSheets.actionSheets.removeAtIndex(i)
            }
        }
    }
    
}
