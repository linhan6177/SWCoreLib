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
func CGRectDiagonalRect(_ point1:CGPoint, point2:CGPoint) -> CGRect
{
    return CGRect(x: min(point1.x, point2.x), y: min(point1.y, point2.y), width: abs(point2.x - point1.x), height: abs(point2.y - point1.y))
}

extension CGFloat
{
    var roundValue:CGFloat {
        //return round(self)
        return rounded()
    }
}


extension CGPoint
{
    //整数值
    var integral:CGPoint{
        return CGPoint(x: ceil(x), y: ceil(y))
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
        return CGPoint(x: midX, y: midY)
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
    func snapshotImage(_ scale:CGFloat = 1) -> UIImage?
    {
        let size = CGSize(width: frame.width * scale, height: frame.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, false,
            UIScreen.main.scale)
        var image:UIImage?
        if let context = UIGraphicsGetCurrentContext()
        {
            layer.render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image
    }
    
    //移除所有子视图
    func removeAllSubview()
    {
        for i in (0..<subviews.count).reversed()
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
    
    func setSize(_ width:CGFloat, height:CGFloat)
    {
        var rect:CGRect = self.frame
        rect.size = CGSize(width: width, height: height)
        self.frame = rect
    }
}

extension UIImage
{
    convenience init?(contentsOfURL:URL?)
    {
        guard let url = contentsOfURL,let data = try? Data(contentsOf: url) else
        {
            return nil
        }
        self.init(data:data)
    }
    
    //将另一张图片绘入自身并返回一张新图片
    func draw(_ image:UIImage, rect:CGRect, alpha: CGFloat = 1) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false,
            UIScreen.main.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        //image.drawInRect(rect)
        image.draw(in: rect, blendMode: .normal, alpha: alpha)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    func clone() -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false,
                                               UIScreen.main.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}

extension UIImage
{
    
    var retinaImage:UIImage?
    {
        guard let cgImage = cgImage else{
            return nil
        }
        
        if scale > 1{
            return self
        }
        
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: imageOrientation)
    }
    
    //视网膜屏下的尺寸
    var retinaSize:CGSize{
        let aSize = originSize
        let ScreenScale = UIScreen.main.scale
        return CGSize(width: aSize.width / ScreenScale, height: aSize.height / ScreenScale)
    }
    
    //1倍图的尺寸
    var originSize:CGSize{
        return CGSize(width: CGFloat(cgImage!.width), height: CGFloat(cgImage!.height))
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
        return isPortrait ? CGSize(width: minEdge, height: maxEdge) : CGSize(width: maxEdge, height: minEdge)
    }
    
    var viewFrame:CGRect
    {
        let size = viewSize
        return CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    var statusBarHeight:CGFloat {
        return 20
        //return UIApplication.sharedApplication.statusBarFrame.height
    }
    
    var navigationBarBottom:CGFloat {
        let navigationBarHeight:CGFloat = 44
        return statusBarHeight + navigationBarHeight
    }
    
    var tabBarHeight:CGFloat {
        return 49
    }
    
    func easyAddChildViewController(_ viewController:UIViewController, container:UIView? = nil)
    {
        viewController.willMove(toParentViewController: self)
        addChildViewController(viewController)
        (container ?? view).addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.didMove(toParentViewController: self)
    }
    
    func easyRemoveChildViewController(_ viewController:UIViewController)
    {
        viewController.willMove(toParentViewController: nil)
        viewController.removeFromParentViewController()
        viewController.view.removeFromSuperview()
        viewController.didMove(toParentViewController: nil)
    }
    
    //创建左侧 文字导航按钮
    func createNavigationLeftButton(_ title:String, target:AnyObject, action:Selector) -> UIBarButtonItem
    {
        let button:UIBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: target, action: action)
        navigationItem.leftBarButtonItem = button
        return button
    }
    
    //创建右侧 文字导航按钮
    func createNavigationRightButton(_ title:String, target:AnyObject, action:Selector) -> UIBarButtonItem
    {
        let button:UIBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: target, action: action)
        navigationItem.rightBarButtonItem = button
        return button
    }
    
    //创建一个自定义右侧导航按钮
    func createNavigationRightCustomButton(_ title:String?, image:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = createNavigationCustomButton(title, image: image, highlightedImage: nil, target: target, action: action)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        return button
    }
    
    //创建一个自定义右侧导航按钮
    func createNavigationRightCustomButton(_ title:String?, image:UIImage?, highlightedImage:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = createNavigationCustomButton(title, image: image, highlightedImage: highlightedImage, target: target, action: action)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        return button
    }
    
    //创建一个自定义左侧导航按钮
    func createNavigationLeftCustomButton(_ title:String?, image:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        return createNavigationLeftCustomButton(title, image:image, highlightedImage: nil, target: target, action: action)
    }
    
    //创建一个自定义左侧导航按钮
    func createNavigationLeftCustomButton(_ title:String?, image:UIImage?, highlightedImage:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = createNavigationCustomButton(title, image: image, highlightedImage: highlightedImage, target: target, action: action)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = barButton
        return button
    }
    
    private func createNavigationCustomButton(_ title:String?, image:UIImage?, highlightedImage:UIImage?, target:AnyObject, action:Selector) -> UIButton
    {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setBackgroundImage(image, for: .normal)
        button.setBackgroundImage(highlightedImage, for: .highlighted)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.sizeToFit()
        return button
    }
}

