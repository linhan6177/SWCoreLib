//
//  ChatInput.swift
//  uicomponetTest3
//
//  Created by linhan on 15-2-2.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit

@objc protocol ChatInputDelegate:NSObjectProtocol
{
    func chatInput(input:ChatInput, frameChange frame:CGRect)
    optional func chatInput(input:ChatInput, send text:String)
    optional func chatInputDidShow(input:ChatInput)
    optional func chatInputDidHide(input:ChatInput)
    optional func chatInputTypeChanged(input:ChatInput)
}

//停靠状态（屏幕下或者悬停）
enum DockType:Int
{
    case Under
    case Hover
}

enum InputType:Int
{
    case None
    case Text
    case Custom
}

class ChatInput:UIView,UITextViewDelegate,SWGrowingTextViewDelegate
{
    
    
    weak var delegate:ChatInputDelegate?
    
    
    private var _inited:Bool = false
    
    private var _rect:CGRect = CGRectZero
    
    //当前正要切换但还未切换的输入方式
    private var _targetInputType:InputType = InputType.None
    
    private var _animationDuration:Double = 0.25
    
    private var _containerRect:CGRect = CGRectZero
    
    private var _textWidth:CGFloat = 0
    
    private var _height:CGFloat = 43
    private var _width:CGFloat = 0
    
    private var _toolbar:UIView = UIView()
    
    
    //是否持续监听键盘(输入框所在页面被覆盖等原因暂时未使用，则不再监听键盘事件)
    var stillKeyboardListening:Bool = true
    
    //输入框区域(输入框 + （键盘、表情）)
    var rect:CGRect
        {
            return CGRectMake(0, _dockY, _width, _height)
    }
    
    //系统键盘区域
    private var _systemKeyboardFrame:CGRect = CGRectZero
    
    private var _font:UIFont = UIFont.systemFontOfSize(14)
    
    
    private var _textField:SWGrowingTextView?
    var textField:UIView?
        {
            return _textField
    }
    
    
    
    init(containerRect:CGRect)
    {
        _containerRect = containerRect
        _width = containerRect.width
        //let rect:CGRect =
        super.init(frame: CGRectMake(0, 0, _width, _height))
        setup()
    }
    
    
    weak var customInputView:UIView?
        {
        didSet
        {
            //更换自定义输入内容
            if customInputView != nil && customInputView != oldValue && inputType == .Custom
            {
                //先将上一个自定义面板隐藏
                var hideY:CGFloat = _containerRect.height
                if let lastCustomInputView = oldValue
                {
                    hideY = self._containerRect.height - self._dockY + lastCustomInputView.height
                    UIView.animateWithDuration(_animationDuration, animations: {
                        
                        lastCustomInputView.y = hideY
                        
                        }, completion: {(finish:Bool) in
                            lastCustomInputView.removeFromSuperview()
                    })
                }
                
                //再显示出新的自定义面板
                if let inputView = customInputView
                {
                    if inputView.superview == nil
                    {
                        addSubview(inputView)
                    }
                    inputView.y = hideY
                    let keyboardRect:CGRect = CGRectMake(0, _toolbar.height, inputView.frame.width, inputView.frame.height)
                    showKeyboard(keyboardRect, duration: _animationDuration)
                    UIView.animateWithDuration(_animationDuration, animations: {
                        
                        inputView.y = keyboardRect.origin.y
                        
                    })
                }
                
            }
        }
    }
    
    //当然输入类型（键盘、表情、其他）
    private var _inputType:InputType = InputType.None
    var inputType:InputType
        {
            return _inputType
    }
    
    //回车键类型
    private var _returnKeyType:UIReturnKeyType = .Default
    var returnKeyType:UIReturnKeyType
        {
        get
        {
            return _returnKeyType
        }
        set
        {
            _returnKeyType = newValue
            _textField?.returnKeyType = newValue
        }
    }
    
    //键盘风格(Light 为系统默认，Dark为黑色)
    var keyboardAppearance:UIKeyboardAppearance
        {
        get
        {
            return _textField?.keyboardAppearance ?? UIKeyboardAppearance.Default
        }
        set
        {
            _textField?.keyboardAppearance = newValue
        }
    }
    
    var enablesReturnKeyAutomatically:Bool
        {
        get
        {
            return _textField?.enablesReturnKeyAutomatically ?? false
        }
        set
        {
            _textField?.enablesReturnKeyAutomatically = newValue
        }
    }
    
    var text:String
        {
        get
        {
            return _textField?.text ?? ""
        }
        set
        {
            _textField?.text = newValue
        }
    }
    
    //文本颜色
    var textColor:UIColor
        {
        get
        {
            return _textField?.textColor ?? UIColor.darkGrayColor()
        }
        set
        {
            _textField?.textColor = newValue
        }
    }
    
    var placeholder:String
        {
        get
        {
            return _textField?.placeholder ?? ""
        }
        set
        {
            _textField?.placeholder = newValue
        }
    }
    
    //默认文本颜色
    var placeholderColor:UIColor
        {
        get
        {
            return _textField?.placeholderColor ?? UIColor.lightGrayColor()
        }
        set
        {
            _textField?.placeholderColor = newValue
        }
    }
    
    //停靠方式(码头式或者沉底式)
    var dockType:DockType = .Hover
        {
        didSet
        {
            var rect:CGRect = self.frame
            rect.origin.y = dockType == .Hover ? _containerRect.height - _toolbar.height : _containerRect.height
            self.frame = rect
        }
    }
    
    //输入框停留位置
    private var _dockY:CGFloat
        {
            return dockType == .Hover ? _containerRect.height - _toolbar.height : _containerRect.height
    }
    
    //文本框与周边间距（整个输入组件的大小取决于文本框本身大小以及周边间距）
    var textFieldEdgeInsets:UIEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        {
        didSet
        {
            if _inited
            {
                textFieldResize()
            }
        }
    }
    
    var leftViewEdgeInsets:UIEdgeInsets = UIEdgeInsetsMake(8, 8, 0, 8)
        {
        didSet
        {
            if let view = _leftView
            {
                if _inited
                {
                    view.frame = CGRectMake(leftViewEdgeInsets.left, leftViewEdgeInsets.top, view.width, view.height)
                    textFieldResize()
                }
            }
        }
    }
    
    private var _leftView:UIView?
    weak var leftView:UIView?
        {
        get
        {
            return _leftView
        }
        set
        {
            _leftView = newValue
            if _leftView != nil
            {
                _leftView!.frame = CGRectMake(leftViewEdgeInsets.left, leftViewEdgeInsets.top, _leftView!.width, _leftView!.height)
                _toolbar.addSubview(_leftView!)
            }
            if _inited
            {
                textFieldResize()
            }
        }
    }
    
    //输入框右侧视图边缘间距
    var rightViewEdgeInsets:UIEdgeInsets = UIEdgeInsetsMake(8, 0, 0, 8)
        {
        didSet
        {
            if let view = _rightView
            {
                if _inited
                {
                    view.frame = CGRectMake(_width - view.width - rightViewEdgeInsets.right, rightViewEdgeInsets.top, view.width, view.height)
                    textFieldResize()
                }
            }
        }
    }
    
    private var _rightView:UIView?
    weak var rightView:UIView?
        {
        get
        {
            return _rightView
        }
        set
        {
            _rightView = newValue
            if _rightView != nil
            {
                _rightView!.frame = CGRectMake(_width - _rightView!.width - rightViewEdgeInsets.right, rightViewEdgeInsets.top, _rightView!.width, _rightView!.height)
                _toolbar.addSubview(_rightView!)
            }
            if _inited
            {
                textFieldResize()
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func becomeFirstResponder() -> Bool
    {
        let superValue:Bool = super.becomeFirstResponder()
        return _textField?.becomeFirstResponder() ?? superValue
    }
    
    override func resignFirstResponder() -> Bool
    {
        let superValue = super.resignFirstResponder()
        return _textField?.resignFirstResponder() ?? superValue
    }
    
    override func isFirstResponder() -> Bool
    {
        return _textField?.isFirstResponder() ?? false
    }
    
    private func setup()
    {
        _toolbar.frame = CGRectMake(0, 0, _containerRect.width, _height)
        addSubview(_toolbar)
        
        
        _textField = SWGrowingTextView()
        _textField?.delegate = self
        _textField?.scrollable = true
        _textField?.contentInset = UIEdgeInsetsMake(0, 5, 0, 5)
        _textField?.font = _font
        _textField?.minNumberOfLines = 1
        _textField?.maxNumberOfLines = 3
        _textField?.returnKeyType = _returnKeyType
        _textField?.backgroundColor = UIColor.whiteColor()
        _textField?.placeholder = "请输入文字"
        _textField?.animateHeightChange = false
        
        textFieldResize()
        
        
        _toolbar.addSubview(_textField!)
        
        dockType = .Hover
        
        let notification:NSNotificationCenter = NSNotificationCenter.defaultCenter()
        notification.addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        notification.addObserver(self, selector: Selector("keyboardDidShow:"), name: UIKeyboardDidShowNotification, object: nil)
        notification.addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        notification.addObserver(self, selector: Selector("keyboardDidHide:"), name: UIKeyboardDidHideNotification, object: nil)
        
        _inited = true
    }
    
    //隐藏键盘
    func hideAllKeyboard()
    {
        if _inputType != .None
        {
            if let textField = _textField where textField.isFirstResponder()
            {
                textField.resignFirstResponder()
            }
            
            UIView.animateWithDuration(_animationDuration, animations: {
                self.y = self._dockY
                self.customInputView?.y = self._containerRect.height - self._dockY
                }, completion: {finish in
                    self.customInputView?.removeFromSuperview()
            })
            _height = _toolbar.height
            notifyInputFrameChange(CGRectMake(0, _dockY, _width, _height))
            _inputType = .None
        }
    }
    
    //当前是否在舞台有效范围内，只有在有效范围内才需要响应键盘事件
    private var onStage:Bool
        {
            guard let _ = window else
            {
                return false
            }
            guard let superview = superview else
            {
                return false
            }
            guard let keyWindow = UIApplication.sharedApplication().keyWindow else
            {
                return false
            }
            let gloablFrame = superview.convertRect(frame, toView: keyWindow)
            return !CGRectIntersection(gloablFrame, keyWindow.frame).isEmpty
    }
    
    //文本框大小变化
    private func textFieldResize()
    {
        let TextFieldHeight:CGFloat = _textField?.height ?? 0
        let textFieldX = _leftView != nil ? leftViewEdgeInsets.left + _leftView!.frame.width + leftViewEdgeInsets.right : textFieldEdgeInsets.left
        _textWidth = (_rightView != nil ? _rightView!.x : _width) - textFieldX - textFieldEdgeInsets.right
        let textFrame:CGRect = CGRectMake(textFieldX, textFieldEdgeInsets.top, _textWidth, TextFieldHeight)
        _textField?.frame = textFrame
        chatInputResize()
    }
    
    //整个输入组件大小变化
    private func chatInputResize()
    {
        let keyboardHeight:CGFloat = _inputType == .Text ? _systemKeyboardFrame.height : (customInputView?.height ?? 0)
        let TextFieldHeight:CGFloat = _textField?.height ?? 0
        let toolbarHeight:CGFloat = TextFieldHeight + textFieldEdgeInsets.top + textFieldEdgeInsets.bottom
        _toolbar.height = toolbarHeight
        _height = toolbarHeight
        customInputView?.y = toolbarHeight
        _height = _inputType == .Text ? toolbarHeight : (keyboardHeight + toolbarHeight)
        frame = CGRectMake(0, _containerRect.height - keyboardHeight - toolbarHeight, _width, _height)
    }
    
    private func notifyInputFrameChange(targetRect:CGRect)
    {
        if !CGRectEqualToRect(targetRect, _rect)
        {
            _rect = targetRect
            delegate?.chatInput(self, frameChange: targetRect)
        }
    }
    
    func changeInputType(type:InputType)
    {
        _targetInputType = type
        //各种键盘先收起
        if _inputType == .Text && type != .Text
        {
            if _textField!.isFirstResponder()
            {
                _textField!.resignFirstResponder()
            }
        }
        else if _inputType == .Custom && type != .Custom
        {
            UIView.animateWithDuration(_animationDuration, animations:{
                
                self.customInputView?.y = self._containerRect.height - self._dockY + (self.customInputView?.height ?? 0)
                
                }, completion: {(finish:Bool) in
                    self.customInputView?.removeFromSuperview()
            })
        }
        
        //再显示出对应的键盘
        if type == .Text
        {
            if let textField = _textField where !textField.isFirstResponder()
            {
                textField.becomeFirstResponder()
            }
        }
        else if type == .Custom
        {
            //显示其他输入面板(表情)
            if let inputView = self.customInputView
            {
                if inputView.superview == nil
                {
                    addSubview(inputView)
                }
                let keyboardRect:CGRect = CGRectMake(0, _toolbar.height, inputView.frame.width, inputView.frame.height)
                showKeyboard(keyboardRect, duration: _animationDuration)
                UIView.animateWithDuration(_animationDuration, animations: {
                    
                    inputView.frame = keyboardRect
                    
                    }, completion: {(finish:Bool) in
                        
                        self._inputType = .Custom
                        self.delegate?.chatInputDidShow?(self)
                        self.delegate?.chatInputTypeChanged?(self)
                })
            }
        }
        
    }
    
    private func showKeyboard(keyboardRect:CGRect, duration:Double = 0.25)
    {
        var keyboardHeight = keyboardRect.height
        //横屏状态下，返回的键盘宽高是对调的
        let statusBarOrientation = UIApplication.sharedApplication().statusBarOrientation
        if (statusBarOrientation == UIInterfaceOrientation.LandscapeLeft || statusBarOrientation == UIInterfaceOrientation.LandscapeRight) && keyboardRect.height > keyboardRect.width
        {
            keyboardHeight = keyboardRect.width
        }
        
        var inputFrame:CGRect
        if _targetInputType == .Text
        {
            _height = _toolbar.height
            inputFrame = CGRectMake(0, self._containerRect.height - keyboardHeight - self._height, self._width, self._height)
        }
        else
        {
            _height = keyboardHeight + _toolbar.height
            inputFrame = CGRectMake(0, self._containerRect.height - _height, self._width, self._height)
        }
        
        
        UIView.animateWithDuration(duration, animations:{
            
            self.frame = inputFrame
            
            }, completion:{(finish:Bool) in
                
                self._targetInputType = .None
                
        })
        notifyInputFrameChange(inputFrame)
    }
    
    func growingTextView(growingTextView: SWGrowingTextView, didChangeHeight height: CGFloat)
    {
        chatInputResize()
        notifyInputFrameChange(self.frame)
    }
    
    func growingTextViewShouldReturn(growingTextView:SWGrowingTextView) -> Bool
    {
        send()
        return true
    }
    
    //发送
    func send()
    {
        if let textField = _textField where textField.text != ""
        {
            delegate?.chatInput?(self, send: textField.text)
            textField.text = ""
        }
    }
    
    /**
     func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
     {
     if _textField!.returnKeyType != .Default
     {
     for scalar in text.unicodeScalars
     {
     if scalar.value == 10
     {
     send()
     return false
     }
     }
     }
     return true
     }
     **/
     
     //键盘即将浮出
    @objc private func keyboardWillShow(notification:NSNotification)
    {
        if !onStage && dockType == .Hover
        {
            return
        }
        
        if !stillKeyboardListening
        {
            return
        }
        
        if let userInfo = notification.userInfo
        {
            if let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
            {
                _systemKeyboardFrame = keyboardSize
            }
            
            if let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double
            {
                _animationDuration = duration
            }
            changeInputType(.Text)
            showKeyboard(_systemKeyboardFrame, duration:_animationDuration)
        }
    }
    
    //键盘已浮出
    @objc private func keyboardDidShow(notification:NSNotification)
    {
        if !onStage && dockType == .Hover
        {
            return
        }
        
        
        if !stillKeyboardListening
        {
            return
        }
        
        _inputType = .Text
        delegate?.chatInputDidShow?(self)
        delegate?.chatInputTypeChanged?(self)
    }
    
    //键盘即将隐藏
    @objc private func keyboardWillHide(notification:NSNotification)
    {
        if !onStage && dockType == .Hover
        {
            return
        }
        
        
        if !stillKeyboardListening
        {
            return
        }
        
        //当不是切换到表情等原因引起的键盘隐藏事件，则进行全部收起
        if _targetInputType == .None
        {
            hideAllKeyboard()
        }
    }
    
    @objc private func keyboardDidHide(notification:NSNotification)
    {
        if !onStage && dockType == .Hover
        {
            return
        }
        
        
        if !stillKeyboardListening
        {
            return
        }
        
        if _targetInputType == .None
        {
            delegate?.chatInputDidHide?(self)
        }
    }
    
}