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
    func scrollTabBar(_ tabBar: ScrollTabBar, didSelectIndex index: Int)
}

struct SWScrollTabBarItem
{
    var title:String
    var image:UIImage?
    
    init(title:String, image:UIImage? = nil)
    {
        self.title = title
        self.image = image
    }
}

fileprivate class ItemView: UIView
{
    var titleLeftMargin:CGFloat = 0
    var selectedColor:UIColor = UIColor.darkGray
    var unselectedColor:UIColor = UIColor.darkGray
    var font:UIFont = UIFont.systemFont(ofSize: 14)
    
    var item:SWScrollTabBarItem?
    
    var isSelected:Bool = false{
        didSet{
            _label.textColor = isSelected ? selectedColor : unselectedColor
        }
    }
    
    override var frame: CGRect{
        get{
            return super.frame
        }
        set{
            super.frame = newValue
            _contentView.center = bounds.center
        }
    }
    
    private var _contentView:UIView = UIView()
    private var _label:UILabel = UILabel()
    private var _imageView:UIImageView = UIImageView()
    
    init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeToFit()
    {
        updateView()
    }
    
    private func setup()
    {
        _contentView.addSubview(_label)
        _contentView.addSubview(_imageView)
        addSubview(_contentView)
    }
    
    private func updateView()
    {
        if let item = item
        {
            var titleLeft:CGFloat = 0
            var containerHeight:CGFloat = 0
            if let image = item.image
            {
                titleLeft = image.size.width + titleLeftMargin
                containerHeight = image.size.height
                _imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                _imageView.image = image
            }
            
            _label.font = font
            _label.text = item.title
            _label.sizeToFit()
            
            containerHeight = max(containerHeight, _label.height)
            _imageView.y = (containerHeight - _imageView.height) * 0.5
            _label.frame = CGRectMake(titleLeft, (containerHeight - _label.height) * 0.5, _label.width, _label.height)
            _contentView.frame = CGRectMake(0, 0, _label.right, containerHeight)
            frame = _contentView.frame
        }
    }
    
    
    
}

class ScrollTabBar:UIView
{
    var selectedColor:UIColor = UIColor.red {
        didSet {
            _signView.backgroundColor = selectedColor
        }
    }
    
    var unselectedColor:UIColor = UIColor.darkGray
    
    //当内容宽度小于容器宽度的时候，内容是左对齐还是居中对齐
    var alignment:NSTextAlignment?
    
    //项与项的间隔
    var itemSpacing: CGFloat = 15
    
    var itemTitleLeftMargin: CGFloat = 4
    
    var underlineTopGrid:CGFloat = 3
    
    var leftMargin:CGFloat = 10
    
    var rightMargin:CGFloat = 10
    
    var font:UIFont = UIFont.systemFont(ofSize: 14)
    
    weak var delegate:ScrollTabBarDelegate?
    
    private var _selectedIndex:Int = -1
    
    private var _overflow:Bool = false
    
    private var _items:[SWScrollTabBarItem]?
    
    private var _buttons:[ItemView] = []
    
    private var _cacheButtons:[ItemView] = []
    
    lazy private var _scrollView:UIScrollView = UIScrollView()
    
    lazy private var _buttonContainer:UIView = UIView()
    
    lazy private var _signView:UIView = UIView()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        _buttonContainer.frame = CGRect(x: 0, y: 0, width: 0, height: frame.height)
        _scrollView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        
        setup()
    }
    
    init()
    {
        super.init(frame: CGRect.zero)
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //是否显示下划线
    var underline:Bool = false
    {
        didSet{
            _signView.isHidden = !underline
        }
    }
    
    //下划线宽度
    var underlineBorderWidth:CGFloat = 0
    {
        didSet
        {
            _signView.height = underlineBorderWidth
        }
    }
    
    var titleItems:[String]{
        get{
            return items?.map({$0.title}) ?? []
        }
        set{
            items = newValue.map({SWScrollTabBarItem(title: $0)})
        }
    }
    
    var items:[SWScrollTabBarItem]?
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
            var button:ItemView
            //先移除全部
            for i in 0..<_buttons.count
            {
                button = _buttons.remove(at: i)
                button.removeFromSuperview()
                
                _cacheButtons.append(button)
            }
            
            
            if let items = _items , items.count > 0
            {
                //不够用时进行创建
                var numNeedCreate:Int = items.count - _cacheButtons.count
                numNeedCreate = numNeedCreate >= 0 ? numNeedCreate : 0
                for _ in 0..<numNeedCreate
                {
                    button = ItemView()
                    let gesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(buttonTaped(_:)))
                    button.addGestureRecognizer(gesture)
                    _cacheButtons.append(button)
                }
                
                
                for (i,item) in items.enumerated()
                {
                    button = _cacheButtons[i]
                    button.font = font
                    button.unselectedColor = unselectedColor
                    button.selectedColor = selectedColor
                    button.titleLeftMargin = itemTitleLeftMargin
                    button.tag = i
                    button.item = item
                    button.isSelected = false
                    button.sizeToFit()
                    let ButtonWidth:CGFloat = max(button.width, 44)
                    //let ButtonHeight:CGFloat = max(_buttonContainer.height, button.height)
                    let ButtonHeight:CGFloat = button.height
                    let ButtonY:CGFloat = max((_buttonContainer.height - button.height) * 0.5, 0)
                    button.frame = CGRect(x: lastRight + (i > 0 ? itemSpacing : 0), y: ButtonY, width: ButtonWidth, height: ButtonHeight)
                    lastRight = button.x + ButtonWidth
                    lastBottom = button.y + button.height
                    _buttons.append(button)
                    _buttonContainer.addSubview(button)
                }
                button = _cacheButtons[0]
                _signView.frame = CGRect(x: button.x, y: lastBottom + underlineTopGrid, width: button.width, height: underlineBorderWidth)
            }
            let contentWidth:CGFloat = lastRight + rightMargin
            _overflow = contentWidth > self.width
            _scrollView.bounces = _overflow
            _buttonContainer.width = contentWidth
            var buttonContainerX:CGFloat = 0
            //当内容宽度小于容器宽度，可选择内容是居中对齐还是左对齐
            if !_overflow && alignment != nil && alignment == NSTextAlignment.center
            {
                buttonContainerX = (self.width - contentWidth) * 0.5
            }
            _buttonContainer.x = buttonContainerX
            _scrollView.contentSize = CGSize(width: contentWidth, height: self.height)
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
            var button:ItemView
            if let items = _items , items.count > 0 && _selectedIndex >= 0 && _selectedIndex < items.count
            {
                button = _buttons[_selectedIndex]
                button.isSelected = false
            }
            
            _selectedIndex = newValue
            
            if let items = _items , items.count > 0 && _selectedIndex >= 0 && _selectedIndex < items.count
            {
                if underline
                {
                    _signView.isHidden = false
                }
                
                button = _buttons[_selectedIndex]
                button.isSelected = true
                
                //_overflow
                let buttonRect:CGRect = button.frame
                
                if _overflow
                {
                    let offsetX:CGFloat = min(max(button.center.x -  width * 0.5, 0), _buttonContainer.width - width)
                    if offsetX != _scrollView.contentOffset.x
                    {
                        UIView.animate(withDuration: 0.3, animations: {
                            self._scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
                        })
                    }
                }
                
                UIView.animate(withDuration: 0.3, animations: {
                    self._signView.x = buttonRect.origin.x
                })
            }
            else
            {
                _signView.isHidden = true
            }
            
            
        }//end of set
    }
    
    //在items设置后自动测算宽高
    override func sizeToFit()
    {
        if let items = items,items.count > 0
        {
            let contentWidth:CGFloat = _scrollView.contentSize.width
            var contentHeight:CGFloat = (_buttons.valueAt(0)?.height ?? 0)
            if underline
            {
                contentHeight += (underlineTopGrid + underlineBorderWidth)
            }
            let rect = CGRectMake(0, 0, contentWidth, contentHeight)
            _buttonContainer.frame = rect
            _scrollView.frame = rect
            frame = CGRectMake(frame.origin.x, frame.origin.y, contentWidth, contentHeight)
        }
    }
    
    private func setup()
    {
        underlineBorderWidth = 1.5
        _signView.backgroundColor = UIColor.red
        _signView.isHidden = !underline
        _buttonContainer.addSubview(_signView)
        _scrollView.addSubview(_buttonContainer)
        _scrollView.showsHorizontalScrollIndicator = false
        addSubview(_scrollView)
    }
    
    //按钮
    @objc private func buttonTouched(_ button:UIButton)
    {
        let index:Int = button.tag
        selectedIndex = index
    }
    
    @objc private func buttonTaped(_ gesture:UITapGestureRecognizer)
    {
        if let label = gesture.view as? ItemView
        {
            let index:Int = label.tag
            let oldSelectedIndex:Int = _selectedIndex
            selectedIndex = index
            if let items = _items , items.count > 0 && _selectedIndex >= 0 && _selectedIndex < items.count
            {
                if oldSelectedIndex != index
                {
                    delegate?.scrollTabBar(self, didSelectIndex: index)
                }
            }
        }
    }
    
    
    
}//end class
