//
//  UITextViewDelegateRepeater.swift
//  UIcomnentTest2
//  代理转发器
//  Created by linhan on 2016/12/26.
//  Copyright © 2016年 test. All rights reserved.
//

import Foundation

class UITextViewDelegateRepeater: NSObject,UITextViewDelegate
{
    weak var majorDelegate:UITextViewDelegate?
    private var _delegates:[UITextViewDelegate] = []
    
    deinit
    {
        //print("DEINIT UITextViewDelegateRepeater")
    }
    
    weak var textView:UITextView?
    {
        didSet{
            textView?.delegate = self
        }
    }
    
    func addDelegate(_ delegate:UITextViewDelegate)
    {
        //_delegates.addObject(delegate)
        _delegates.append(delegate)
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        var should:Bool = true
        if let delegate = majorDelegate, let handler = delegate.textViewShouldBeginEditing
        {
            should = handler(textView)
        }
        for delegate in _delegates
        {
            should = delegate.textViewShouldBeginEditing?(textView) ?? true
        }
        return should
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        var should:Bool = true
        for delegate in _delegates
        {
            should = delegate.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
        }
        
        if let delegate = majorDelegate, delegate.responds(to: #selector(textView(_:shouldChangeTextIn:replacementText:)))
        {
            should = delegate.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
        }
        return should
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        for delegate in _delegates
        {
            delegate.textViewDidChange?(textView)
        }
        if let delegate = majorDelegate, let handler = delegate.textViewDidChange
        {
            handler(textView)
        }
    }
    
    
}

class UITextViewPlaceholderHandler:NSObject,UITextViewDelegate
{
    private var _label:UILabel = UILabel()
    
    deinit
    {
        //print("DEINIT UITextViewPlaceholderHandler")
    }
    
    var placeholder:String{
        get{
            return _label.text ?? ""
        }
        set{
            _label.text = newValue
            let font = UIFont.systemFont(ofSize: 12)
            let height = StringUtil.getStringHeight(newValue, font: _label.font ?? font, width: _label.width)
            _label.height = height
        }
    }
    
    var placeholderColor:UIColor?{
        get{
            return _label.textColor
        }
        set{
            _label.textColor = newValue
        }
    }
    
    
    init(textView:UITextView)
    {
        super.init()
        var inset = textView.textContainerInset
        inset.left = 4
        inset.top = 4
        _label.frame = CGRectMake(inset.left, inset.top, textView.width - inset.left - inset.right, 1)
        _label.font = UIFont.systemFont(ofSize: 12)
        _label.numberOfLines = 0
        _label.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        textView.addSubview(_label)
        textChanged(text:textView.text ?? "")
    }
    
    private func textChanged(text:String)
    {
        _label.isHidden = !text.isEmpty
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        textChanged(text:textView.text ?? "")
    }
}

class UITextViewMaxCharHandler:NSObject,UITextViewDelegate
{
    var maxChar:Int = 0
    
    deinit
    {
        //print("DEINIT UITextViewMaxCharHandler")
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        let source:String = textView.text ?? ""
        let string:String = (source as NSString).replacingCharacters(in: range, with: text)
        if string.length > maxChar
        {
            let count:Int = max(maxChar - source.length + range.length,0)
            let insertString:String = text.substringWithRange(NSMakeRange(0, count))
            if count > 0
            {
                textView.text = (source as NSString).replacingCharacters(in: range, with: insertString)
            }
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        //如果在变化中是高亮部分在变，就不要计算字符了
        if let selectedRange:UITextRange = textView.markedTextRange,
            let _ = textView.position(from: selectedRange.start, offset: 0)
        {
            return
        }
        
        let source:String = textView.text ?? ""
        if source.length > maxChar
        {
            textView.text = source.substringWithRange(NSMakeRange(0, maxChar))
        }
    }
    
    
    
}
