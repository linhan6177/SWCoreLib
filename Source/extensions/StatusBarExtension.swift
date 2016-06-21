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
    public override func childViewControllerForStatusBarStyle() -> UIViewController?
    {
        //print("UITabBarController childViewControllerForStatusBarStyle")
        return selectedViewController
    }
    
    public override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return selectedViewController?.preferredStatusBarStyle() ?? UIStatusBarStyle.Default
    }
    
    public override func prefersStatusBarHidden()->Bool
    {
        return selectedViewController?.prefersStatusBarHidden() ??  false
    }
    
    public override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation
    {
        return selectedViewController?.preferredStatusBarUpdateAnimation() ?? UIStatusBarAnimation.Fade
    }
}

extension UINavigationController
{
    
    //控制各子ViewController的状态栏 样式（白色、黑色）
    public override func childViewControllerForStatusBarStyle() -> UIViewController?
    {
        //print("UINavigationController childViewControllerForStatusBarStyle")
        return topViewController
    }
    
    public override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return topViewController?.preferredStatusBarStyle() ?? UIStatusBarStyle.Default
    }
    
    public override func prefersStatusBarHidden()->Bool
    {
        return topViewController?.prefersStatusBarHidden() ??  false
    }
    
    public override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation
    {
        return topViewController?.preferredStatusBarUpdateAnimation() ?? UIStatusBarAnimation.Fade
    }

}