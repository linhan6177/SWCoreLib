//
//  Base64.swift
//  iosapphello
//
//  Created by linhan on 14-8-7.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
import UIKit
public class ImageUtil:NSObject
{
    //强制拉伸到指定大小（可能变形）
    public class func resize(image:UIImage, size:CGSize) -> UIImage
    {
        // Create a graphics image size
        //UIGraphicsBeginImageContext(size)
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.mainScreen().scale)
        
        // Tell the old image to draw in this new context, with the desired new size
        let rect:CGRect = CGRectMake(0, 0, size.width, size.height)
        image.drawInRect(rect)
        
        // Get the new image from the context
        
        //UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        // End the context
        UIGraphicsEndImageContext()
        
        // Return the new image.
        return newImage
    }
    
    
    public class func crop(image:UIImage, rect:CGRect) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.mainScreen().scale)
        let context = UIGraphicsGetCurrentContext()
        let drawRect = CGRectMake(-rect.origin.x, -rect.origin.y, image.size.width, image.size.height)
        CGContextClipToRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height))
        image.drawInRect(drawRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    //水平翻转
    public class func flipHorizontal(image:UIImage) -> UIImage
    {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        CGContextScaleCTM(context, -1, 1)
        CGContextTranslateCTM(context, -size.width, 0)
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        CGContextRestoreGState(context)
        let flipImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flipImage
    }
    
    //垂直翻转
    public class func flipVertical(image:UIImage) -> UIImage
    {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        CGContextScaleCTM(context, 1, -1)
        CGContextTranslateCTM(context, 0, -size.height)
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        CGContextRestoreGState(context)
        let flipImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flipImage
    }
    
    //图片旋转(仅限90°为单位的旋转, -90 90)
    public class func rotate(image:UIImage, angle:Int) -> UIImage
    {
        let angle180:Bool = abs(angle) % 180 == 0
        let size = angle180 ? image.size : CGSizeMake(image.size.height, image.size.width)
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        
        if abs(angle) % 90 == 0
        {
            if angle / 90 == 1
            {
                CGContextTranslateCTM(context, size.width, 0)
            }
            else if angle / 90 == -1
            {
                CGContextTranslateCTM(context, 0, size.height)
            }
            else if angle / 180 == 1
            {
                CGContextTranslateCTM(context, size.width, size.height);
            }
            CGContextRotateCTM(context, CGFloat(angle) * CGFloat(M_PI) / 180.0)
        }
        
        image.drawInRect(CGRectMake(0, 0, image.size.width, image.size.height))
        CGContextRestoreGState(context)
        let flipImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flipImage
    }
    
    //取得某个大小的图片
    public class func getImageWithinByteLimit(image:UIImage, size:CGSize, limit:Int) -> UIImage
    {
        let resizeImage:UIImage = Toucan.Resize.resizeImage(image, size: size, fitMode:.Clip)
        if let data:NSData = UIImageJPEGRepresentation(resizeImage, 0.9)
        {
            if data.length < limit
            {
                //trace("最终大小:", data.length)
                return resizeImage
            }
            else
            {
                let increment:CGFloat = 50
                let newSize:CGSize = CGSizeMake(max(size.width - increment, 1), max(size.height - increment, 1))
                //trace("下次压缩尺寸:", data.length, newSize)
                if newSize.width <= 1 || newSize.height <= 1
                {
                    return image
                }
                else
                {
                    return getImageWithinByteLimit(resizeImage, size:newSize, limit:limit)
                }
            }
        }
        else
        {
            return image
        }
    }
    
    
    
    
    
    
    
}