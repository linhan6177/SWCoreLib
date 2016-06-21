//
//  StrokeLabel.swift
//  uicomponetTest3
//
//  Created by linhan on 15-5-11.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit
class StrokeLabel: UILabel
{
    //继承UILabel以后重载drawTextInRect
    
    var strokeColor:UIColor?
    var strokeSize:CGFloat = 2
    {
        didSet
        {
            //setNeedsDisplay()
        }
    }
    
    override func drawTextInRect(rect: CGRect)
    {
        let TempTextColor:UIColor = textColor
        
        if let context = UIGraphicsGetCurrentContext()
        {
            CGContextSetLineWidth(context, strokeSize);
            CGContextSetLineJoin(context, CGLineJoin.Round);
            
            
            CGContextSetTextDrawingMode(context, CGTextDrawingMode.Stroke)
            if strokeColor != nil
            {
                textColor = strokeColor
                super.drawTextInRect(rect)
            }
            
            CGContextSetTextDrawingMode(context, CGTextDrawingMode.Fill)
            textColor = TempTextColor
            super.drawTextInRect(rect)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
}