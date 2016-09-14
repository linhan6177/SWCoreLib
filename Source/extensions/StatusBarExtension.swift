//
//  StatusBarExtension.swift
//  BaseDemo
//
//  Created by linhan on 16/2/25.
//  Copyright © 2016年 me. All rights reserved.
//

import Foundation
import UIKit
extension UITabBarController
{
    
    //控制各子ViewController的状态栏 样式（白色、黑色）
    open override var childViewControllerForStatusBarStyle : UIViewController?
    {
        //print("UITabBarController childViewControllerForStatusBarStyle")
        return selectedViewController
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle
    {
        return selectedViewController?.preferredStatusBarStyle ?? UIStatusBarStyle.default
    }
    
    open override var prefersStatusBarHidden:Bool
    {
        return selectedViewController?.prefersStatusBarHidden ??  false
    }
    
    open override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation
    {
        return selectedViewController?.preferredStatusBarUpdateAnimation ?? UIStatusBarAnimation.fade
    }
}

extension UINavigationController
{
    
    //控制各子ViewController的状态栏 样式（白色、黑色）
    open override var childViewControllerForStatusBarStyle : UIViewController?
    {
        //print("UINavigationController childViewControllerForStatusBarStyle")
        return topViewController
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle
    {
        return topViewController?.preferredStatusBarStyle ?? UIStatusBarStyle.default
    }
    
    open override var prefersStatusBarHidden:Bool
    {
        return topViewController?.prefersStatusBarHidden ??  false
    }
    
    open override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation
    {
        return topViewController?.preferredStatusBarUpdateAnimation ?? UIStatusBarAnimation.fade
    }

}
