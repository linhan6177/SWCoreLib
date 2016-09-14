//
//  Base64.swift
//  iosapphello
//
//  Created by linhan on 14-8-7.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
import UIKit
open class ImageUtil:NSObject
{
    //强制拉伸到指定大小（可能变形）
    open class func resize(_ image:UIImage, size:CGSize) -> UIImage
    {
        // Create a graphics image size
        //UIGraphicsBeginImageContext(size)
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)
        
        // Tell the old image to draw in this new context, with the desired new size
        let rect:CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        image.draw(in: rect)
        
        // Get the new image from the context
        
        //UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        // End the context
        UIGraphicsEndImageContext()
        
        // Return the new image.
        return newImage!
    }
    
    
    open class func crop(_ image:UIImage, rect:CGRect) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        let drawRect = CGRect(x: -rect.origin.x, y: -rect.origin.y, width: image.size.width, height: image.size.height)
        context?.clip(to: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
        image.draw(in: drawRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    //取得某个大小的图片
    open class func getImageWithinByteLimit(_ image:UIImage, size:CGSize, limit:Int) -> UIImage
    {
        let resizeImage:UIImage = Toucan.Resize.resizeImage(image, size: size, fitMode:.clip)
        if let data:Data = UIImageJPEGRepresentation(resizeImage, 0.9)
        {
            if data.count < limit
            {
                //trace("最终大小:", data.length)
                return resizeImage
            }
            else
            {
                let increment:CGFloat = 50
                let newSize:CGSize = CGSize(width: max(size.width - increment, 1), height: max(size.height - increment, 1))
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
