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
    
    override func drawText(in rect: CGRect)
    {
        let TempTextColor:UIColor = textColor
        
        if let context = UIGraphicsGetCurrentContext()
        {
            context.setLineWidth(strokeSize);
            context.setLineJoin(CGLineJoin.round);
            
            
            context.setTextDrawingMode(CGTextDrawingMode.stroke)
            if strokeColor != nil
            {
                textColor = strokeColor
                super.drawText(in: rect)
            }
            
            context.setTextDrawingMode(CGTextDrawingMode.fill)
            textColor = TempTextColor
            super.drawText(in: rect)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
}
