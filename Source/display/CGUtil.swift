//
//  CGUtil.swift
//  PhotoEditorFactory
//
//  Created by linhan on 16/8/29.
//  Copyright © 2016年 test. All rights reserved.
//

import Foundation
import UIKit

protocol CustomLayerDelegateWrapperDelegate:NSObjectProtocol
{
    func customDrawLayer(_ layer: CALayer, inContext ctx: CGContext)
}

//自定义图层绘制代理委托
class CustomLayerDelegateWrapper:NSObject
{
    weak var delegate:CustomLayerDelegateWrapperDelegate?
    
    func drawLayer(_ layer: CALayer, inContext ctx: CGContext)
    {
        delegate?.customDrawLayer(layer, inContext: ctx)
    }
    
}
