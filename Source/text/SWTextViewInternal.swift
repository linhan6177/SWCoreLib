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
            let originalValue:Bool = self.isScrollEnabled
            isScrollEnabled = true
            super.text = newValue
            isScrollEnabled = originalValue
        }
    }
    
    var scrollable:Bool
    {
        get
        {
            return self.isScrollEnabled
        }
        set
        {
            super.isScrollEnabled = newValue
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
            if self.isTracking || self.isDecelerating
            {
                var insets:UIEdgeInsets = self.contentInset
                insets.bottom = 0
                insets.top = 0
                self.contentInset = insets
            }
            else
            {
                let bottomOffset:CGFloat = self.contentSize.height - self.frame.size.height + self.contentInset.bottom
                if newValue.y < bottomOffset && self.isScrollEnabled
                {
                    var insets:UIEdgeInsets = self.contentInset
                    insets.bottom = 8
                    insets.top = 0
                    self.contentInset = insets
                }
            }
            
            // Fix "overscrolling" bug
            var offset:CGPoint = newValue
            if newValue.y > self.contentSize.height - self.frame.size.height && !self.isDecelerating && !self.isTracking && !self.isDragging
            {
                offset = CGPoint(x: newValue.x, y: self.contentSize.height - self.frame.size.height);
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
    
    
    var placeholderColor:UIColor = UIColor.lightGray
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
    
    override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        if displayPlaceHolder
        {
            if self.responds(to: #selector(UIView.snapshotView(afterScreenUpdates:)))
            {
                let paragraphStyle:NSMutableParagraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = self.textAlignment
                (placeholder as NSString).draw(in: CGRect(x: 5, y: 8 + self.contentInset.top, width: self.frame.size.width-self.contentInset.left, height: self.frame.size.height - self.contentInset.top), withAttributes: [NSFontAttributeName:self.font!, NSForegroundColorAttributeName:placeholderColor, NSParagraphStyleAttributeName:paragraphStyle])
            }
            else
            {
                placeholderColor.set()
                (placeholder as NSString).draw(in: CGRect(x: 8.0, y: 8.0, width: self.frame.size.width - 16.0, height: self.frame.size.height - 16.0), withAttributes: [NSFontAttributeName:self.font!])
                
            }
        }
        
    }
    
   
    
    
    
    
}
