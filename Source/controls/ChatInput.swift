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
    func chatInput(_ input:ChatInput, frameChange frame:CGRect)
    @objc optional func chatInput(_ input:ChatInput, send text:String)
    @objc optional func chatInputDidShow(_ input:ChatInput)
    @objc optional func chatInputDidHide(_ input:ChatInput)
    @objc optional func chatInputTypeChanged(_ input:ChatInput)
}

//停靠状态（屏幕下或者悬停）
enum DockType:Int
{
    case under
    case hover
}

enum InputType:Int
{
    case none
    case text
    case custom
}

class ChatInput:UIView,UITextViewDelegate,SWGrowingTextViewDelegate
{
    
    
    weak var delegate:ChatInputDelegate?
    
    
    private var _inited:Bool = false
    
    private var _rect:CGRect = CGRect.zero
    
    //当前正要切换但还未切换的输入方式
    private var _targetInputType:InputType = InputType.none
    
    private var _animationDuration:Double = 0.25
    
    private var _containerRect:CGRect = CGRect.zero
    
    private var _textWidth:CGFloat = 0
    
    private var _height:CGFloat = 43
    private var _width:CGFloat = 0
    
    private var _toolbar:UIView = UIView()
    
    
    //是否持续监听键盘(输入框所在页面被覆盖等原因暂时未使用，则不再监听键盘事件)
    var stillKeyboardListening:Bool = true
    
    //输入框区域(输入框 + （键盘、表情）)
    var rect:CGRect
        {
            return CGRect(x: 0, y: _dockY, width: _width, height: _height)
    }
    
    //系统键盘区域
    private var _systemKeyboardFrame:CGRect = CGRect.zero
    
    private var _font:UIFont = UIFont.systemFont(ofSize: 14)
    
    
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
        super.init(frame: CGRect(x: 0, y: 0, width: _width, height: _height))
        setup()
    }
    
    
    weak var customInputView:UIView?
        {
        didSet
        {
            //更换自定义输入内容
            if customInputView != nil && customInputView != oldValue && inputType == .custom
            {
                //先将上一个自定义面板隐藏
                var hideY:CGFloat = _containerRect.height
                if let lastCustomInputView = oldValue
                {
                    hideY = self._containerRect.height - self._dockY + lastCustomInputView.height
                    UIView.animate(withDuration: _animationDuration, animations: {
                        
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
                    let keyboardRect:CGRect = CGRect(x: 0, y: _toolbar.height, width: inputView.frame.width, height: inputView.frame.height)
                    showKeyboard(keyboardRect, duration: _animationDuration)
                    UIView.animate(withDuration: _animationDuration, animations: {
                        
                        inputView.y = keyboardRect.origin.y
                        
                    })
                }
                
            }
        }
    }
    
    //当然输入类型（键盘、表情、其他）
    private var _inputType:InputType = InputType.none
    var inputType:InputType
        {
            return _inputType
    }
    
    //回车键类型
    private var _returnKeyType:UIReturnKeyType = .default
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
            return _textField?.keyboardAppearance ?? UIKeyboardAppearance.default
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
            return _textField?.textColor ?? UIColor.darkGray
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
            return _textField?.placeholderColor ?? UIColor.lightGray
        }
        set
        {
            _textField?.placeholderColor = newValue
        }
    }
    
    //停靠方式(码头式或者沉底式)
    var dockType:DockType = .hover
        {
        didSet
        {
            var rect:CGRect = self.frame
            rect.origin.y = dockType == .hover ? _containerRect.height - _toolbar.height : _containerRect.height
            self.frame = rect
        }
    }
    
    //输入框停留位置
    private var _dockY:CGFloat
        {
            return dockType == .hover ? _containerRect.height - _toolbar.height : _containerRect.height
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
                    view.frame = CGRect(x: leftViewEdgeInsets.left, y: leftViewEdgeInsets.top, width: view.width, height: view.height)
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
                _leftView!.frame = CGRect(x: leftViewEdgeInsets.left, y: leftViewEdgeInsets.top, width: _leftView!.width, height: _leftView!.height)
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
                    view.frame = CGRect(x: _width - view.width - rightViewEdgeInsets.right, y: rightViewEdgeInsets.top, width: view.width, height: view.height)
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
                _rightView!.frame = CGRect(x: _width - _rightView!.width - rightViewEdgeInsets.right, y: rightViewEdgeInsets.top, width: _rightView!.width, height: _rightView!.height)
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
        NotificationCenter.default.removeObserver(self)
    }
    
    @discardableResult
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
    
    override var isFirstResponder : Bool
    {
        return _textField?.isFirstResponder ?? false
    }
    
    private func setup()
    {
        _toolbar.frame = CGRect(x: 0, y: 0, width: _containerRect.width, height: _height)
        addSubview(_toolbar)
        
        
        _textField = SWGrowingTextView()
        _textField?.delegate = self
        _textField?.scrollable = true
        _textField?.contentInset = UIEdgeInsetsMake(0, 5, 0, 5)
        _textField?.font = _font
        _textField?.minNumberOfLines = 1
        _textField?.maxNumberOfLines = 3
        _textField?.returnKeyType = _returnKeyType
        _textField?.backgroundColor = UIColor.white
        _textField?.placeholder = "请输入文字"
        _textField?.animateHeightChange = false
        
        textFieldResize()
        
        
        _toolbar.addSubview(_textField!)
        
        dockType = .hover
        
        let notification:NotificationCenter = NotificationCenter.default
        notification.addObserver(self, selector: #selector(ChatInput.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notification.addObserver(self, selector: #selector(ChatInput.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        notification.addObserver(self, selector: #selector(ChatInput.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        notification.addObserver(self, selector: #selector(ChatInput.keyboardDidHide(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
        _inited = true
    }
    
    //隐藏键盘
    func hideAllKeyboard()
    {
        if _inputType != .none
        {
            if let textField = _textField , textField.isFirstResponder
            {
                textField.resignFirstResponder()
            }
            
            UIView.animate(withDuration: _animationDuration, animations: {
                self.y = self._dockY
                self.customInputView?.y = self._containerRect.height - self._dockY
                }, completion: {finish in
                    self.customInputView?.removeFromSuperview()
            })
            _height = _toolbar.height
            notifyInputFrameChange(CGRect(x: 0, y: _dockY, width: _width, height: _height))
            _inputType = .none
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
            guard let keyWindow:UIView = UIApplication.shared.keyWindow else
            {
                return false
            }
        
            let gloablFrame:CGRect = superview.convert(frame, toView: keyWindow)
            return !gloablFrame.intersection(keyWindow.frame).isEmpty
    }
    
    //文本框大小变化
    private func textFieldResize()
    {
        let TextFieldHeight:CGFloat = _textField?.height ?? 0
        let textFieldX = _leftView != nil ? leftViewEdgeInsets.left + _leftView!.frame.width + leftViewEdgeInsets.right : textFieldEdgeInsets.left
        _textWidth = (_rightView != nil ? _rightView!.x : _width) - textFieldX - textFieldEdgeInsets.right
        let textFrame:CGRect = CGRect(x: textFieldX, y: textFieldEdgeInsets.top, width: _textWidth, height: TextFieldHeight)
        _textField?.frame = textFrame
        chatInputResize()
    }
    
    //整个输入组件大小变化
    private func chatInputResize()
    {
        let keyboardHeight:CGFloat = _inputType == .text ? _systemKeyboardFrame.height : (customInputView?.height ?? 0)
        let TextFieldHeight:CGFloat = _textField?.height ?? 0
        let toolbarHeight:CGFloat = TextFieldHeight + textFieldEdgeInsets.top + textFieldEdgeInsets.bottom
        _toolbar.height = toolbarHeight
        _height = toolbarHeight
        customInputView?.y = toolbarHeight
        _height = _inputType == .text ? toolbarHeight : (keyboardHeight + toolbarHeight)
        frame = CGRect(x: 0, y: _containerRect.height - keyboardHeight - toolbarHeight, width: _width, height: _height)
    }
    
    private func notifyInputFrameChange(_ targetRect:CGRect)
    {
        if !targetRect.equalTo(_rect)
        {
            _rect = targetRect
            delegate?.chatInput(self, frameChange: targetRect)
        }
    }
    
    func changeInputType(_ type:InputType)
    {
        _targetInputType = type
        //各种键盘先收起
        if _inputType == .text && type != .text
        {
            if _textField!.isFirstResponder
            {
                _textField?.resignFirstResponder()
            }
        }
        else if _inputType == .custom && type != .custom
        {
            UIView.animate(withDuration: _animationDuration, animations:{
                
                self.customInputView?.y = self._containerRect.height - self._dockY + (self.customInputView?.height ?? 0)
                
                }, completion: {(finish:Bool) in
                    self.customInputView?.removeFromSuperview()
            })
        }
        
        //再显示出对应的键盘
        if type == .text
        {
            if let textField = _textField, !textField.isFirstResponder
            {
                textField.becomeFirstResponder()
            }
        }
        else if type == .custom
        {
            //显示其他输入面板(表情)
            if let inputView = self.customInputView
            {
                if inputView.superview == nil
                {
                    addSubview(inputView)
                }
                let keyboardRect:CGRect = CGRect(x: 0, y: _toolbar.height, width: inputView.frame.width, height: inputView.frame.height)
                showKeyboard(keyboardRect, duration: _animationDuration)
                UIView.animate(withDuration: _animationDuration, animations: {
                    
                    inputView.frame = keyboardRect
                    
                    }, completion: {(finish:Bool) in
                        
                        self._inputType = .custom
                        self.delegate?.chatInputDidShow?(self)
                        self.delegate?.chatInputTypeChanged?(self)
                })
            }
        }
        
    }
    
    private func showKeyboard(_ keyboardRect:CGRect, duration:Double = 0.25)
    {
        var keyboardHeight = keyboardRect.height
        //横屏状态下，返回的键盘宽高是对调的
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        if (statusBarOrientation == UIInterfaceOrientation.landscapeLeft || statusBarOrientation == UIInterfaceOrientation.landscapeRight) && keyboardRect.height > keyboardRect.width
        {
            keyboardHeight = keyboardRect.width
        }
        
        var inputFrame:CGRect
        if _targetInputType == .text
        {
            _height = _toolbar.height
            inputFrame = CGRect(x: 0, y: self._containerRect.height - keyboardHeight - self._height, width: self._width, height: self._height)
        }
        else
        {
            _height = keyboardHeight + _toolbar.height
            inputFrame = CGRect(x: 0, y: self._containerRect.height - _height, width: self._width, height: self._height)
        }
        
        
        UIView.animate(withDuration: duration, animations:{
            
            self.frame = inputFrame
            
            }, completion:{(finish:Bool) in
                
                self._targetInputType = .none
                
        })
        notifyInputFrameChange(inputFrame)
    }
    
    func growingTextView(_ growingTextView: SWGrowingTextView, didChangeHeight height: CGFloat)
    {
        chatInputResize()
        notifyInputFrameChange(self.frame)
    }
    
    func growingTextViewShouldReturn(_ growingTextView:SWGrowingTextView) -> Bool
    {
        send()
        return true
    }
    
    //发送
    func send()
    {
        if let textField = _textField , textField.text != ""
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
    @objc private func keyboardWillShow(_ notification:Notification)
    {
        if !onStage && dockType == .hover
        {
            return
        }
        
        if !stillKeyboardListening
        {
            return
        }
        
        if let userInfo = (notification as NSNotification).userInfo
        {
            if let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            {
                _systemKeyboardFrame = keyboardSize
            }
            
            if let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double
            {
                _animationDuration = duration
            }
            changeInputType(.text)
            showKeyboard(_systemKeyboardFrame, duration:_animationDuration)
        }
    }
    
    //键盘已浮出
    @objc private func keyboardDidShow(_ notification:Notification)
    {
        if !onStage && dockType == .hover
        {
            return
        }
        
        
        if !stillKeyboardListening
        {
            return
        }
        
        _inputType = .text
        delegate?.chatInputDidShow?(self)
        delegate?.chatInputTypeChanged?(self)
    }
    
    //键盘即将隐藏
    @objc private func keyboardWillHide(_ notification:Notification)
    {
        if !onStage && dockType == .hover
        {
            return
        }
        
        
        if !stillKeyboardListening
        {
            return
        }
        
        //当不是切换到表情等原因引起的键盘隐藏事件，则进行全部收起
        if _targetInputType == .none
        {
            hideAllKeyboard()
        }
    }
    
    @objc private func keyboardDidHide(_ notification:Notification)
    {
        if !onStage && dockType == .hover
        {
            return
        }
        
        
        if !stillKeyboardListening
        {
            return
        }
        
        if _targetInputType == .none
        {
            delegate?.chatInputDidHide?(self)
        }
    }
    
}
