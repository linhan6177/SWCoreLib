//
//  ImageHelper.swift
//  KanHigh
//
//  Created by linhan on 15/9/29.
//  Copyright (c) 2015年 KanHigh. All rights reserved.
//

import Foundation
import UIKit

class ImageHelper: NSObject
{
    static func getThumbFromCenter(image:UIImage, size:CGSize) -> UIImage
    {
        var newImage:UIImage = image
        //如果图片方向不是向上，则进行旋转
        if image.imageOrientation != .Up
        {
            //UIGraphicsBeginImageContext(image.size)
            UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.mainScreen().scale)
            image.drawInRect(CGRectMake(0, 0, image.size.width, image.size.height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        
        let minEdge:CGFloat = min(newImage.size.width, newImage.size.height)
        let cropRect:CGRect = CGRectMake((newImage.size.width - minEdge) * 0.5, (newImage.size.height - minEdge) * 0.5, minEdge, minEdge)
        let cropImage:UIImage = ImageUtil.crop(newImage, rect: cropRect)
        let resizedImge:UIImage = ImageUtil.resize(cropImage, size: size)
        return resizedImge
    }
}