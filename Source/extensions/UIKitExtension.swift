//
//  UIKitExtension.swift
//  uicomponetTest3
//
//  Created by linhan on 15/10/26.
//  Copyright © 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit


//获取对角线两点所构成的区域
func CGRectDiagonalRect(point1:CGPoint, point2:CGPoint) -> CGRect
{
    return CGRectMake(min(point1.x, point2.x), min(point1.y, point2.y), abs(point2.x - point1.x), abs(point2.y - point1.y))
}

extension CGFloat
{
    var roundValue:CGFloat{
        return round(self)
    }
}


extension CGPoint
{
    //整数值
    var integral:CGPoint{
        return CGPointMake(ceil(x), ceil(y))
    }
    
    //计算两点的距离
    static func distance(point1:CGPoint, point2:CGPoint) -> CGFloat
    {
        let xDistance:CGFloat = point2.x - point1.x
        let yDistance:CGFloat = point2.y - point1.y
        return sqrt(pow(abs(xDistance), 2) + pow(abs(yDistance), 2))
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
    
    //最短边
    public var minEdge:CGFloat{
        return min(width, height)
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
        for i in (0..<subviews.count).reverse()
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
    func draw(image:UIImage, rect:CGRect, alpha: CGFloat = 1) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false,
            UIScreen.mainScreen().scale)
        drawInRect(CGRectMake(0, 0, size.width, size.height))
        //image.drawInRect(rect)
        image.drawInRect(rect, blendMode: CGBlendMode.Normal, alpha: alpha)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    func clone() -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false,
                                               UIScreen.mainScreen().scale)
        drawInRect(CGRectMake(0, 0, size.width, size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

extension UIImage
{
    
    var retinaImage:UIImage?
    {
        guard let cgImage = CGImage else{
            return nil
        }
        
        if scale == UIScreen.mainScreen().scale{
            return self
        }
        return UIImage(CGImage: cgImage, scale: UIScreen.mainScreen().scale, orientation: imageOrientation)
    }
    
    //视网膜屏下的尺寸
    var retinaSize:CGSize{
        let aSize = originSize
        let ScreenScale = UIScreen.mainScreen().scale
        return CGSizeMake(aSize.width / ScreenScale, aSize.height / ScreenScale)
    }
    
    //1倍图的尺寸
    var originSize:CGSize{
        return CGSizeMake(CGFloat(CGImageGetWidth(CGImage)), CGFloat(CGImageGetHeight(CGImage)))
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
    
    //创建左侧 文字导航按钮
    func createNavigationLeftButton(title:String, target:AnyObject, action:Selector) -> UIBarButtonItem
    {
        let button:UIBarButtonItem = UIBarButtonItem(title: title, style: .Plain, target: target, action: action)
        navigationItem.leftBarButtonItem = button
        return button
    }
    
    //创建右侧 文字导航按钮
    func createNavigationRightButton(title:String, target:AnyObject, action:Selector) -> UIBarButtonItem
    {
        let button:UIBarButtonItem = UIBarButtonItem(title: title, style: .Plain, target: target, action: action)
        navigationItem.rightBarButtonItem = button
        return button
    }
    
    //创建一个自定义右侧导航按钮
    func createNavigationRightCustomButton(title:String?, image:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = createNavigationCustomButton(title, image: image, highlightedImage: nil, target: target, action: action)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        return button
    }
    
    //创建一个自定义右侧导航按钮
    func createNavigationRightCustomButton(title:String?, image:UIImage?, highlightedImage:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = createNavigationCustomButton(title, image: image, highlightedImage: highlightedImage, target: target, action: action)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        return button
    }
    
    //创建一个自定义左侧导航按钮
    func createNavigationLeftCustomButton(title:String?, image:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        return createNavigationLeftCustomButton(title, image:image, highlightedImage: nil, target: target, action: action)
    }
    
    //创建一个自定义左侧导航按钮
    func createNavigationLeftCustomButton(title:String?, image:UIImage?, highlightedImage:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = createNavigationCustomButton(title, image: image, highlightedImage: highlightedImage, target: target, action: action)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = barButton
        return button
    }
    
    private func createNavigationCustomButton(title:String?, image:UIImage?, highlightedImage:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = UIButton(type: .System)
        button.setTitle(title, forState: .Normal)
        button.setBackgroundImage(image, forState: .Normal)
        button.setBackgroundImage(highlightedImage, forState: .Highlighted)
        button.addTarget(target, action: action, forControlEvents: .TouchUpInside)
        button.sizeToFit()
        return button
    }
}

