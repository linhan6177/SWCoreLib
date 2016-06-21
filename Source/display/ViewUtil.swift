//
//  Base64.swift
//  iosapphello
//
//  Created by linhan on 14-8-7.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
#if os(iOS)
   import UIKit 
#endif

public class ViewUtil:NSObject
{
    
    /**
    * 获取一个显示对象基于容器的自适应缩放比例
    * @param	targetW			显示对象宽度
    * @param	targetH			显示对象高度
    * @param	containerW		容器宽度
    * @param	containerH		容器高度
    * @param	inscribed		是否是内切缩放(分为最大内切跟最小外切两种方法)
    * @return	自适应缩放比例
    */
    class func getAdaptiveScale(targetW:CGFloat, targetH:CGFloat, containerW:CGFloat, containerH:CGFloat, inscribed:Bool = true)->CGFloat
    {
        let widthRate:CGFloat = targetW / containerW;
        let heightRate:CGFloat = targetH / containerH;
        let rate:CGFloat = inscribed ? max(widthRate, heightRate, 1): min(widthRate, heightRate);
        let adaptiveScale:CGFloat = 1 / rate;
        return adaptiveScale;
    }
    
}





