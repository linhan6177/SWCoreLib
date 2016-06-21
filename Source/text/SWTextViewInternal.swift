//
//  HPTextViewInternal.swift
//  uicomponetTest3
//
//  Created by linhan on 15-5-4.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit
class SWTextViewInternal:UITextView
{
    private var _placeholder:String = ""
    var displayPlaceHolder:Bool = false
    
    override var frame:CGRect
    {
        get
        {
            return super.frame
        }
        set
        {
            super.frame = newValue
        }
    }
    
    override var text:String!
    {
        get
        {
            return super.text
        }
        set
        {
            let originalValue:Bool = self.scrollEnabled
            scrollEnabled = true
            super.text = newValue
            scrollEnabled = originalValue
        }
    }
    
    var scrollable:Bool
    {
        get
        {
            return self.scrollEnabled
        }
        set
        {
            super.scrollEnabled = newValue
        }
    }
    
    override var contentOffset:CGPoint
    {
        get
        {
            return super.contentOffset
        }
        set
        {
            if self.tracking || self.decelerating
            {
                var insets:UIEdgeInsets = self.contentInset
                insets.bottom = 0
                insets.top = 0
                self.contentInset = insets
            }
            else
            {
                let bottomOffset:CGFloat = self.contentSize.height - self.frame.size.height + self.contentInset.bottom
                if newValue.y < bottomOffset && self.scrollEnabled
                {
                    var insets:UIEdgeInsets = self.contentInset
                    insets.bottom = 8
                    insets.top = 0
                    self.contentInset = insets
                }
            }
            
            // Fix "overscrolling" bug
            var offset:CGPoint = newValue
            if newValue.y > self.contentSize.height - self.frame.size.height && !self.decelerating && !self.tracking && !self.dragging
            {
                offset = CGPointMake(newValue.x, self.contentSize.height - self.frame.size.height);
            }
            super.contentOffset = offset
        }
    }
    
    override var contentInset:UIEdgeInsets
    {
        get
        {
            return super.contentInset
        }
        set
        {
            var insets:UIEdgeInsets = newValue
            if newValue.bottom > 8
            {
                insets.bottom = 0
                insets.top = 0
            }
            super.contentInset = insets
        }
    }
    
    override var contentSize:CGSize
    {
        get{
            return super.contentSize
        }
        set
        {
            if self.contentSize.height > newValue.height
            {
                var insets:UIEdgeInsets = self.contentInset
                insets.bottom = 0
                insets.top = 0
                self.contentInset = insets
            }
            super.contentSize = newValue
        }
    }
    
    
    var placeholderColor:UIColor = UIColor.lightGrayColor()
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    
    var placeholder:String
    {
        get
        {
            return _placeholder
        }
        set
        {
            _placeholder = newValue
            self.setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect)
    {
        super.drawRect(rect)
        if displayPlaceHolder
        {
            if self.respondsToSelector("snapshotViewAfterScreenUpdates:")
            {
                let paragraphStyle:NSMutableParagraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = self.textAlignment
                (placeholder as NSString).drawInRect(CGRectMake(5, 8 + self.contentInset.top, self.frame.size.width-self.contentInset.left, self.frame.size.height - self.contentInset.top), withAttributes: [NSFontAttributeName:self.font!, NSForegroundColorAttributeName:placeholderColor, NSParagraphStyleAttributeName:paragraphStyle])
            }
            else
            {
                placeholderColor.set()
                (placeholder as NSString).drawInRect(CGRectMake(8.0, 8.0, self.frame.size.width - 16.0, self.frame.size.height - 16.0), withAttributes: [NSFontAttributeName:self.font!])
                
            }
        }
        
    }
    
   
    
    
    
    
}