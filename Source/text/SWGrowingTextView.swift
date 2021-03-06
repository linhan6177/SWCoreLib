//
//  SWGrowingTextView.swift
//  uicomponetTest3
//
//  Created by linhan on 15-5-4.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit

@objc protocol SWGrowingTextViewDelegate:NSObjectProtocol
{
    optional func growingTextViewShouldBeginEditing(growingTextView:SWGrowingTextView) -> Bool
    optional func growingTextViewShouldEndEditing(growingTextView:SWGrowingTextView) -> Bool
    
    optional func growingTextViewDidBeginEditing(growingTextView:SWGrowingTextView)
    optional func growingTextViewDidEndEditing(growingTextView:SWGrowingTextView)
    
    optional func growingTextView(growingTextView: SWGrowingTextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    optional func growingTextViewDidChange(growingTextView:SWGrowingTextView)
    
    optional func growingTextView(growingTextView: SWGrowingTextView, willChangeHeight height: CGFloat)
    optional func growingTextView(growingTextView: SWGrowingTextView, didChangeHeight height: CGFloat)
    
    optional func growingTextViewDidChangeSelection(growingTextView:SWGrowingTextView)
    optional func growingTextViewShouldReturn(growingTextView:SWGrowingTextView) -> Bool
}




class SWGrowingTextView: UIView,UITextViewDelegate
{

    
    var internalTextView:SWTextViewInternal?
    weak var delegate:SWGrowingTextViewDelegate?
    var animateHeightChange:Bool = false
    var animationDuration:Double = 0.1
    private var _maxHeight:CGFloat = 0
    private var _minHeight:CGFloat = 0
    private var _maxNumberOfLines:Int = 0
    private var _minNumberOfLines:Int = 0
    private var _contentInset:UIEdgeInsets = UIEdgeInsetsZero
    
    //var placeholder
    
    
    init()
    {
        super.init(frame:CGRectZero)
        internalTextView = SWTextViewInternal(frame:CGRectZero)
        commonInitialiser()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        internalTextView = SWTextViewInternal(frame:frame)
        commonInitialiser()
    }
    
    init(frame:CGRect, textContainer:NSTextContainer)
    {
        super.init(frame: frame)
        internalTextView = SWTextViewInternal(frame:frame, textContainer:textContainer)
        commonInitialiser()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInitialiser()
    {
        internalTextView!.delegate = self
        internalTextView!.scrollEnabled = false
        internalTextView!.font = UIFont(name: "Helvetica", size: 13)
        internalTextView!.contentInset = UIEdgeInsetsZero
        internalTextView!.showsHorizontalScrollIndicator = false
        internalTextView!.text = "-";
        internalTextView!.contentMode = UIViewContentMode.Redraw
        internalTextView!.enablesReturnKeyAutomatically = true
        self.addSubview(internalTextView!)
        
        _minHeight = internalTextView!.frame.size.height
        _minNumberOfLines = 1
        
        animateHeightChange = true
        animationDuration = 0.1;
        
        internalTextView!.text = ""
        
        //todo
        maxNumberOfLines = 3
        
        internalTextView!.displayPlaceHolder = true
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize
    {
        var newSize:CGSize = size
        if text.length == 0
        {
            newSize.height = minHeight
        }
        return newSize
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        var r:CGRect = self.bounds
        r.origin.y = 0
        r.origin.x = contentInset.left
        r.size.width -= contentInset.left + contentInset.right
        internalTextView!.frame = r
    }
    
    override var frame:CGRect
    {
        get
        {
            return super.frame
        }
        set
        {
            super.frame = newValue
            internalTextView?.frame = newValue
        }
    }
    
    var contentInset:UIEdgeInsets
    {
        get
        {
            return _contentInset
        }
        set
        {
            let inset = newValue
            _contentInset = newValue
            var r:CGRect = self.frame
            r.origin.y = inset.top - inset.bottom
            r.origin.x = inset.left
            r.size.width -= inset.left + inset.right
            internalTextView!.frame = r;
            maxNumberOfLines = _maxNumberOfLines
            minNumberOfLines = _minNumberOfLines
        }
    }
    
    var maxNumberOfLines:Int
    {
        get
        {
            return _maxNumberOfLines
        }
        set
        {
            if newValue == 0 && maxHeight > 0
            {
                return
            }
            let saveText:String = internalTextView!.text
            var newText = "-"
            internalTextView!.delegate = nil
            internalTextView!.hidden = true
            for (var i:Int = 1;i < newValue;++i)
            {
                newText += "\n|W|"
            }
            internalTextView!.text = newText
            _maxHeight = self.measureHeight
            
            internalTextView!.text = saveText
            internalTextView!.hidden = false
            internalTextView!.delegate = self
            
            self.sizeToFit()
            
            _maxNumberOfLines = newValue;
        }
    }
    
    var maxHeight:CGFloat
    {
        get
        {
            return _maxHeight
        }
        set
        {
            _maxHeight = newValue
            _maxNumberOfLines = 0
        }
    }
    
    var minNumberOfLines:Int
    {
        get
        {
            return _minNumberOfLines
        }
        set
        {
            if newValue == 0 && minHeight > 0
            {
                return
            }
            let saveText:String = internalTextView!.text
            var newText = "-"
            internalTextView!.delegate = nil
            internalTextView!.hidden = true
            for (var i:Int = 1;i < newValue;++i)
            {
                newText += "\n|W|"
            }
            internalTextView!.text = newText
            
            _minHeight = self.measureHeight
            
            internalTextView!.text = saveText
            internalTextView!.hidden = false
            internalTextView!.delegate = self
            
            sizeToFit()
            
            _minNumberOfLines = newValue
        }
    }
    
    var minHeight:CGFloat
    {
        get
        {
            return _minHeight
        }
        set
        {
            _minHeight = newValue
            _minNumberOfLines = 0
        }
    }
    
    var measureHeight:CGFloat
    {
        get
        {
            var h:CGFloat = 0
            if self.respondsToSelector("snapshotViewAfterScreenUpdates:")
            {
                h = ceil(internalTextView!.sizeThatFits(self.internalTextView!.frame.size).height)
            }
            else
            {
                h = self.internalTextView!.contentSize.height
            }
            return h
        }
    }
    
    var placeholder:String
    {
        get
        {
            return internalTextView!.placeholder
        }
        set
        {
            internalTextView!.placeholder = newValue
        }
    }
    
    var placeholderColor:UIColor
    {
        get
        {
            return internalTextView!.placeholderColor
        }
        set
        {
            internalTextView!.placeholderColor = newValue
        }
    }
    
    func textViewDidChange(textView: UITextView)
    {
        self.refreshHeight()
    }
    
    private func refreshHeight()
    {
        var newSizeH:CGFloat = measureHeight
        if (newSizeH < minHeight || !internalTextView!.hasText())
        {
            newSizeH = minHeight
        }
        else if (maxHeight != 0 && newSizeH > maxHeight)
        {
            newSizeH = maxHeight
        }
        
        if (internalTextView!.frame.size.height != newSizeH)
        {
            // if our new height is greater than the maxHeight
            // sets not set the height or move things
            // around and enable scrolling
            if (newSizeH >= maxHeight)
            {
                if(!internalTextView!.scrollEnabled){
                    internalTextView!.scrollEnabled = true;
                    internalTextView!.flashScrollIndicators()
                }
                
            } else {
                internalTextView!.scrollEnabled = false
            }
            
            // [fixed] Pasting too much text into the view failed to fire the height change,
            // thanks to Gwynne <http://blog.darkrainfall.org/>
            if (newSizeH <= maxHeight)
            {
                if(animateHeightChange)
                {
                    //UIViewAnimationOptions(.BeginFromCurrentState.rawValue | .AllowUserInteraction.rawValue)
                    UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                    
                            self.resizeTextView(newSizeH)
                    
                        }, completion: {finish in
                    
                            if self.delegate != nil
                            {
                                self.delegate!.growingTextView?(self, didChangeHeight: newSizeH)
                            }
                            
                    })
                    
                    /**
                    UIView.beginAnimations("", context: nil)
                    UIView.setAnimationDuration(animationDuration)
                    UIView.setAnimationDelegate(self)
                    UIView.setAnimationDidStopSelector("growDidStop")
                    UIView.setAnimationBeginsFromCurrentState(true)
                    resizeTextView(newSizeH)
                    UIView.commitAnimations()
                    **/
                }
                else
                {
                    resizeTextView(newSizeH)
                    // [fixed] The growingTextView:didChangeHeight: delegate method was not called at all when not animating height changes.
                    // thanks to Gwynne <http://blog.darkrainfall.org/>
                    
                    delegate?.growingTextView?(self, didChangeHeight: newSizeH)
                    
                }
            }//end if newSizeH <= maxHeight
        }//end  != newSizeH
        
        // Display (or not) the placeholder string
        let wasDisplayingPlaceholder:Bool = internalTextView!.displayPlaceHolder
        internalTextView!.displayPlaceHolder = self.internalTextView!.text.length == 0
        if wasDisplayingPlaceholder != internalTextView!.displayPlaceHolder
        {
            internalTextView!.setNeedsDisplay()
        }
        
        // scroll to caret (needed on iOS7)
        if self.respondsToSelector("snapshotViewAfterScreenUpdates:")
        {
            resetScrollPositionForIOS7()
        }
        
        
        // Tell the delegate that the text view changed
        delegate?.growingTextViewDidChange?(self)
        
    }
    
    private func resetScrollPositionForIOS7()
    {
        let r:CGRect = internalTextView!.caretRectForPosition(internalTextView!.selectedTextRange!.end)
        let caretY:CGFloat = max(r.origin.y - internalTextView!.frame.size.height + r.size.height + 8, 0)
        if (internalTextView!.contentOffset.y < caretY && r.origin.y != CGFloat.max)
        {
            internalTextView!.contentOffset = CGPointMake(0, caretY)
        }
    }
    
    private func resizeTextView(newSizeH:CGFloat)
    {
        delegate?.growingTextView?(self, willChangeHeight: newSizeH)
        var internalTextViewFrame:CGRect = self.frame
        internalTextViewFrame.size.height = newSizeH; // + padding
        self.frame = internalTextViewFrame;
        
        internalTextViewFrame.origin.y = contentInset.top - contentInset.bottom;
        internalTextViewFrame.origin.x = contentInset.left;
        
        if(!CGRectEqualToRect(internalTextView!.frame, internalTextViewFrame))
        {
            internalTextView!.frame = internalTextViewFrame;
        }
    }
    
    @objc private func growDidStop()
    {
        resetScrollPositionForIOS7()
        delegate?.growingTextView?(self, didChangeHeight: self.frame.size.height)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        internalTextView?.becomeFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return internalTextView!.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return internalTextView!.resignFirstResponder()
    }
    
    override func isFirstResponder() -> Bool {
        return internalTextView!.isFirstResponder()
    }
    
    
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    //pragma mark UITextView properties
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    var text:String
    {
        get
        {
            return internalTextView?.text ?? ""
        }
        set
        {
            internalTextView?.text = newValue
            (self as UITextViewDelegate).textViewDidChange?(internalTextView!)
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var font:UIFont
    {
        get
        {
            return internalTextView!.font ?? UIFont.systemFontOfSize(14)
        }
        set
        {
            internalTextView!.font = newValue
            maxNumberOfLines = _maxNumberOfLines
            minNumberOfLines = _minNumberOfLines
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var textColor:UIColor
    {
        get
        {
            return internalTextView!.textColor ?? UIColor.blackColor()
        }
        set
        {
            internalTextView!.textColor = newValue
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    override var backgroundColor:UIColor?
    {
        get
        {
            return internalTextView!.backgroundColor
        }
        set
        {
            super.backgroundColor = newValue
            internalTextView!.backgroundColor = newValue
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var textAlignment:NSTextAlignment
    {
        get
        {
            return internalTextView!.textAlignment
        }
        set
        {
            internalTextView!.textAlignment = newValue
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var selectedRange:NSRange
    {
        get
        {
            return internalTextView!.selectedRange
        }
        set
        {
            internalTextView!.selectedRange = newValue
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var scrollable:Bool
    {
        get
        {
            return internalTextView!.scrollEnabled
        }
        set
        {
            internalTextView!.scrollEnabled = true
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var editable:Bool
    {
        get
        {
            return internalTextView!.editable
        }
        set
        {
            internalTextView!.editable = newValue
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var enablesReturnKeyAutomatically:Bool
    {
        get
        {
            return internalTextView?.enablesReturnKeyAutomatically ?? false
        }
        set
        {
            internalTextView?.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var returnKeyType:UIReturnKeyType
    {
        get
        {
            return internalTextView!.returnKeyType
        }
        set
        {
            internalTextView!.returnKeyType = newValue
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var keyboardType:UIKeyboardType
    {
        get
        {
            return internalTextView!.keyboardType
        }
        set
        {
            internalTextView!.keyboardType = newValue
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    var keyboardAppearance:UIKeyboardAppearance
    {
        get
        {
            return internalTextView!.keyboardAppearance
        }
        set
        {
            internalTextView!.keyboardAppearance = newValue
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    var dataDetectorTypes:UIDataDetectorTypes
    {
        get
        {
            return internalTextView!.dataDetectorTypes
        }
        set
        {
            internalTextView!.dataDetectorTypes = newValue
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    func hasText()->Bool
    {
        return internalTextView!.hasText()
    }
    
    func scrollRangeToVisible(range:NSRange)
    {
        internalTextView!.scrollRangeToVisible(range)
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    //#pragma mark UITextViewDelegate
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool
    {
        if delegate != nil && delegate!.growingTextViewShouldBeginEditing != nil
        {
            return delegate!.growingTextViewShouldBeginEditing!(self)
        }
        else
        {
            return true
        }
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool
    {
        if delegate != nil && delegate!.growingTextViewShouldEndEditing != nil
        {
            return delegate!.growingTextViewShouldEndEditing!(self)
        }
        else
        {
            return true
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView)
    {
        delegate?.growingTextViewDidBeginEditing?(self)
    }
    
    func textViewDidEndEditing(textView: UITextView)
    {
        delegate?.growingTextViewDidEndEditing?(self)
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if !textView.hasText() && text == ""
        {
            return false
        }
        if delegate != nil && delegate!.respondsToSelector("growingTextView:shouldChangeTextInRange:replacementText:")
        {
            return delegate!.growingTextView!(self, shouldChangeTextInRange: range, replacementText: text)
        }
        
        if text == "\n"
        {
            if delegate != nil && delegate!.growingTextViewShouldReturn != nil
            {
                if !delegate!.growingTextViewShouldReturn!(self)
                {
                    return true
                }
                else
                {
                    //textView.resignFirstResponder()
                    return false
                }
            }
            
        }
        
        return true
        
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    func textViewDidChangeSelection(textView: UITextView)
    {
        if delegate != nil && delegate!.growingTextViewDidChangeSelection != nil
        {
            delegate!.growingTextViewDidChangeSelection!(self)
        }
    }
    
    
    
    
}//end class