//
//  OrientationsExtension.swift
//  当设备旋转时，AppDelegate会询问window的rootViewController(根视图),根视图视具体情况而定去询问当前呈现的视图
//  APP -> UITabBarController -> UINavigationController -> UIViewController 询问UITabBarController
//  APP -> UINavigationController -> UITabBarController -> UIViewController 询问UINavigationController
//
//  Created by linhan on 16/1/20.
//  Copyright © 2016年 me. All rights reserved.
//

import Foundation
import UIKit


//在询问UITabBarController，将转向控制权交由当前选中的ViewController自行处理
extension UITabBarController
{
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask
    {
        return selectedViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }
    
    override open var shouldAutorotate:Bool
    {
        return selectedViewController?.shouldAutorotate ?? true
    }
    
    override open var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation
    {
        return selectedViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
    }
}


//在询问UINavigationController，将转向控制权交由最顶层（当前在显示）的ViewController自行处理
//注意：AppDelegate 中需加上 supportedInterfaceOrientationsForWindow
extension UINavigationController
{
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask
    {
        return topViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }
    
    override open var shouldAutorotate:Bool
    {
        return topViewController?.shouldAutorotate ?? true
    }
    
    override open var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation
    {
        return topViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
    }
}


