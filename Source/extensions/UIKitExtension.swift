//
//  UIKitExtension.swift
//  uicomponetTest3
//
//  Created by linhan on 15/10/26.
//  Copyright © 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit

extension CGFloat
{
    var roundValue:CGFloat{
        return round(self)
    }
}

extension CGRect
{
    var x:CGFloat {
        return origin.x
    }
    
    var y:CGFloat {
        return origin.y
    }
    
    var right:CGFloat {
        return origin.x + size.width
    }
    
    var bottom:CGFloat {
        return origin.y + size.height
    }
    
    public var center:CGPoint
    {
        return CGPointMake(midX, midY)
    }
    
}

extension CGSize
{
    public var isEmpty:Bool
    {
        return width == 0 || height == 0
    }
}

extension UIView
{
    //进行快照并返回截图,scale:截图是原始对象的倍数
    func snapshotImage(scale:CGFloat = 1) -> UIImage?
    {
        let size = CGSizeMake(frame.width * scale, frame.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, false,
            UIScreen.mainScreen().scale)
        var image:UIImage?
        if let context = UIGraphicsGetCurrentContext()
        {
            layer.renderInContext(context)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image
    }
    
    //移除所有子视图
    func removeAllSubview()
    {
        for(var i = subviews.count - 1; i > -1; i -= 1)
        {
            subviews[i].removeFromSuperview()
        }
    }
}

extension UIView
{
    var x:CGFloat
        {
        get
        {
            return self.frame.origin.x
        }
        set
        {
            var rect:CGRect = self.frame
            rect.origin.x = newValue
            self.frame = rect
        }
    }
    
    var y:CGFloat
        {
        get
        {
            return self.frame.origin.y
        }
        set
        {
            var rect:CGRect = self.frame
            rect.origin.y = newValue
            self.frame = rect
        }
    }
    
    var width:CGFloat
        {
        get
        {
            return self.frame.width
        }
        set
        {
            var rect:CGRect = self.frame
            rect.size.width = newValue
            self.frame = rect
        }
    }
    
    var height:CGFloat
        {
        get
        {
            return self.frame.height
        }
        set
        {
            var rect:CGRect = self.frame
            rect.size.height = newValue
            self.frame = rect
        }
    }
    
    var right:CGFloat
    {
        return x + width
    }
    
    var bottom:CGFloat
    {
        return y + height
    }
    
    func setSize(width:CGFloat, height:CGFloat)
    {
        var rect:CGRect = self.frame
        rect.size = CGSizeMake(width, height)
        self.frame = rect
    }
}

extension UIImage
{
    convenience init?(contentsOfURL:NSURL?)
    {
        guard let url = contentsOfURL,let data = NSData(contentsOfURL:url) else
        {
            return nil
        }
        self.init(data:data)
    }
    
    //将另一张图片绘入自身并返回一张新图片
    func draw(image:UIImage, rect:CGRect) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false,
            UIScreen.mainScreen().scale)
        drawInRect(CGRectMake(0, 0, size.width, size.height))
        image.drawInRect(rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIViewController
{
    //控制器当前主视图的大小
    var viewSize:CGSize
    {
        // && UIDevice.currentDevice().orientation == .Portrait
        let isPortrait = UIInterfaceOrientationIsPortrait(interfaceOrientation)
        let minEdge:CGFloat = min(view.width, view.height)
        let maxEdge:CGFloat = max(view.width, view.height)
        return isPortrait ? CGSizeMake(minEdge, maxEdge) : CGSizeMake(maxEdge, minEdge)
    }
    
    var viewFrame:CGRect
    {
        let size = viewSize
        return CGRectMake(0, 0, size.width, size.height)
    }
    
    var statusBarHeight:CGFloat {
        return 20
        //return UIApplication.sharedApplication().statusBarFrame.height
    }
    
    var navigationBarBottom:CGFloat {
        let navigationBarHeight:CGFloat = 44
        return statusBarHeight + navigationBarHeight
    }
    
    var tabBarHeight:CGFloat {
        return 49
    }
    
    func easyAddChildViewController(viewController:UIViewController, container:UIView? = nil)
    {
        viewController.willMoveToParentViewController(self)
        addChildViewController(viewController)
        (container ?? view).addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.didMoveToParentViewController(self)
    }
    
    func easyRemoveChildViewController(viewController:UIViewController)
    {
        viewController.willMoveToParentViewController(nil)
        viewController.removeFromParentViewController()
        viewController.view.removeFromSuperview()
        viewController.didMoveToParentViewController(nil)
    }
    
    func createNavigationRightButton(title:String, target:AnyObject, action:Selector) -> UIBarButtonItem
    {
        let button:UIBarButtonItem = UIBarButtonItem(title: title, style: .Plain, target: target, action: action)
        navigationItem.rightBarButtonItem = button
        return button
    }
    
    func createNavigationRightCustomButton(title:String, target:AnyObject, action:Selector) -> UIButton
    {
        let button = createNavigationCustomButton(title, target: target, action: action)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        return button
    }
    
    func createNavigationLeftCustomButton(image:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        return createNavigationLeftCustomButton(image, highlightedImage: nil, target: target, action: action)
    }
    
    func createNavigationLeftCustomButton(image:UIImage?, highlightedImage:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = createNavigationCustomButton(image, highlightedImage: highlightedImage, target: target, action: action)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = barButton
        return button
    }
    
    private func createNavigationCustomButton(image:UIImage?, highlightedImage:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = UIButton(type: .System)
        button.setBackgroundImage(image, forState: .Normal)
        button.setBackgroundImage(highlightedImage, forState: .Highlighted)
        button.addTarget(target, action: action, forControlEvents: .TouchUpInside)
        button.sizeToFit()
        return button
    }
    
    private func createNavigationCustomButton(title:String, target:AnyObject, action:Selector) -> UIButton
    {
        let button = UIButton(type: .System)
        button.setTitle(title, forState: .Normal)
        button.addTarget(target, action: action, forControlEvents: .TouchUpInside)
        button.sizeToFit()
        return button
    }
}

