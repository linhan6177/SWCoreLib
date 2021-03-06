//
//  ScrollTabBar.swift
//  uicomponetTest3
//
//  Created by linhan on 14-12-3.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
import UIKit
@objc protocol ScrollTabBarDelegate:NSObjectProtocol
{
    func scrollTabBar(tabBar: ScrollTabBar, didSelectIndex index: Int)
}

class ScrollTabBar:UIView
{
    private var tabbar:UITabBar?
    
    var selectedColor:UIColor = UIColor.redColor()
    {
        didSet
        {
            _signView.backgroundColor = selectedColor
        }
    }
    
    var unselectedColor:UIColor = UIColor.darkGrayColor()
    
    //当内容宽度小于容器宽度的时候，内容是左对齐还是居中对齐
    var alignment:NSTextAlignment?
    
    var itemSpacing: CGFloat = 15
    
    var leftMargin:CGFloat = 10
    
    var rightMargin:CGFloat = 10
    
    weak var delegate:ScrollTabBarDelegate?
    
    private var _selectedIndex:Int = -1
    
    private var _overflow:Bool = false
    
    private var tab:UITabBar?
    
    private var _defaultFont:UIFont = UIFont.systemFontOfSize(14)
    var font:UIFont
    {
        get
        {
            return _defaultFont
        }
        set
        {
            _defaultFont = newValue
        }
    }
    
    private var _items:[String]?
    
    private var _buttons:[UILabel] = []
    
    private var _cacheButtons:[UILabel] = []
    
    private var _scrollView:UIScrollView
    
    private var _buttonContainer:UIView
    
    lazy private var _signView:UIView = UIView()
    
    override init(frame: CGRect)
    {
        _buttonContainer = UIView(frame: CGRectMake(0, 0, 0, frame.height))
        _scrollView = UIScrollView(frame: CGRectMake(0, 0, frame.width, frame.height))
        super.init(frame: frame)
        
        
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //是否显示下划线
    private var _underline:Bool = false
    var underline:Bool
    {
        get
        {
            return _underline
        }
        set
        {
            _underline = newValue
            _signView.hidden = !newValue
        }
    }
    
    var underlineBorderWidth:CGFloat = 0
    {
        didSet
        {
            _signView.frame = CGRectMake(0, 0, 0, underlineBorderWidth)
        }
    }
    
    var items:[String]?
    {
        get
        {
            return _items
        }
        set
        {
            _items = newValue
            
            //上一个按钮的右侧位置
            var lastRight:CGFloat = leftMargin
            var lastBottom:CGFloat = 0
            var button:UILabel
            //先移除全部
            for i in 0..<_buttons.count
            {
                button = _buttons.removeAtIndex(i)
                button.removeFromSuperview()
                
                _cacheButtons.append(button)
            }
            
            
            if let items = _items where items.count > 0
            {
                //不够用时进行创建
                var numNeedCreate:Int = items.count - _cacheButtons.count
                numNeedCreate = numNeedCreate >= 0 ? numNeedCreate : 0
                for i in 0..<numNeedCreate
                {
                    //button = UIButton.buttonWithType(UIButtonType.System) as UIButton
                    button = UILabel()
                    button.font = _defaultFont
                    button.textColor = unselectedColor
                    button.textAlignment = .Center
                    button.userInteractionEnabled = true
                    //button.addTarget(self, action: "buttonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
                    let gesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "buttonTaped:")
                    button.addGestureRecognizer(gesture)
                    _cacheButtons.append(button)
                }
                
                for i in 0..<items.count
                {
                    button = _cacheButtons[i]
                    button.tag = i
                    button.text = items[i]
                    button.sizeToFit()
                    let ButtonWidth:CGFloat = max(button.width, 44)
                    button.frame = CGRectMake(lastRight + (i > 0 ? itemSpacing : 0), 0, ButtonWidth, _buttonContainer.height)
                    lastRight = button.x + ButtonWidth
                    lastBottom = button.y + button.height
                    _buttons.append(button)
                    _buttonContainer.addSubview(button)
                }
                button = _cacheButtons[0]
                _signView.frame = CGRectMake(button.x, _buttonContainer.height - _signView.height, button.width, underlineBorderWidth)
            }
            let contentWidth:CGFloat = lastRight + rightMargin
            _overflow = contentWidth > self.width
            _scrollView.bounces = _overflow
            _buttonContainer.width = contentWidth
            var buttonContainerX:CGFloat = 0
            //当内容宽度小于容器宽度，可选择内容是居中对齐还是左对齐
            if !_overflow && alignment != nil && alignment == NSTextAlignment.Center
            {
                buttonContainerX = (self.width - contentWidth) * 0.5
            }
            _buttonContainer.x = buttonContainerX
            _scrollView.contentSize = CGSizeMake(contentWidth, self.height)
            selectedIndex = _selectedIndex
        }
    }
    
    var selectedIndex:Int
    {
        get
        {
            return _selectedIndex
        }
        set
        {
            var button:UILabel
            if let items = _items where items.count > 0 && _selectedIndex >= 0 && _selectedIndex < items.count
            {
                button = _buttons[_selectedIndex]
                button.textColor = unselectedColor
            }
            
            _selectedIndex = newValue
            
            if let items = _items where items.count > 0 && _selectedIndex >= 0 && _selectedIndex < items.count
            {
                if underline
                {
                    _signView.hidden = false
                }
                
                button = _buttons[_selectedIndex]
                //button.setTitleColor(UIColor.redColor(), forState: .Normal)
                button.textColor = selectedColor
                //_overflow
                let buttonRect:CGRect = button.frame
                
                if _overflow
                {
                    let offsetX:CGFloat = min(max(button.center.x -  width * 0.5, 0), _buttonContainer.width - width)
                    if offsetX != _scrollView.contentOffset.x
                    {
                        UIView.animateWithDuration(0.3, animations: {
                            self._scrollView.contentOffset = CGPointMake(offsetX, 0)
                        })
                    }
                }
                
                UIView.animateWithDuration(0.3, animations: {
                    self._signView.frame = CGRectMake(buttonRect.origin.x, self._signView.y, buttonRect.width, self.underlineBorderWidth)
                })
            }
            else
            {
                _signView.hidden = true
            }
            
            
        }//end of set
    }
    
    private func setup()
    {
        underlineBorderWidth = 1.5
        _signView.backgroundColor = UIColor.redColor()
        _signView.hidden = !underline
        _buttonContainer.addSubview(_signView)
        _scrollView.addSubview(_buttonContainer)
        _scrollView.showsHorizontalScrollIndicator = false
        self.addSubview(_scrollView)
    }
    
    //按钮
    @objc private func buttonTouched(button:UIButton)
    {
        let index:Int = button.tag
        selectedIndex = index
    }
    
    @objc private func buttonTaped(gesture:UITapGestureRecognizer)
    {
        if let label = gesture.view as? UILabel
        {
            let index:Int = label.tag
            let oldSelectedIndex:Int = _selectedIndex
            selectedIndex = index
            if let items = _items where items.count > 0 && _selectedIndex >= 0 && _selectedIndex < items.count
            {
                if oldSelectedIndex != index
                {
                    delegate?.scrollTabBar(self, didSelectIndex: index)
                }
            }
        }
    }
    
    
    
}//end class