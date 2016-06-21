//
//  BannerTips.swift
//  uicomponetTest3
//
//  Created by linhan on 14-12-19.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
import UIKit

//浮出方向
public enum SurfaceDirection
{
    case Up
    case Down
}

public class BannerTips: UIView
{
    
    //对齐方式（左对齐居中对齐）
    public var alignment:NSTextAlignment = .Center
    
    
    //多久后自动关闭(单位秒)
    public var autoCloseDuration:Double = 2
    
    private let PresetHeight:CGFloat = 40
    
    //是否自定关闭
    private var _inited:Bool = false
    
    private var _state:SWPopupContainerState = .Closed
    
    private var _autoCloseIntervalID:String = ""
    
    //文字
    private var _label:UILabel = UILabel()
    
    //主体内容，包含背景、文字、图标
    private var _contentView:UIView = UIView()
    
    init()
    {
        super.init(frame:CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, PresetHeight))
        setup()
    }
    
    
    override init(frame:CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    deinit
    {
        //println("DEINIT BannerTips")
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //图标
    weak var iconView:UIView?
    {
        didSet
        {
            if let icon = iconView
            {
                _contentView.addSubview(icon)
            }
        }
    }
    
    
    var titleEdgeInsets:UIEdgeInsets = UIEdgeInsetsZero
    
    var iconEdgeInsets:UIEdgeInsets = UIEdgeInsetsZero
    
    //文字颜色
    var textColor:UIColor {
        get {
            return _label.textColor
        }
        set {
            _label.textColor = newValue
        }
    }
    
    var font:UIFont!
    {
        get
        {
            return _label.font
        }
        set
        {
            _label.font = newValue
        }
    }
    
    override public var frame:CGRect
    {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            var contentViewY:CGFloat = direction == .Down ? -newValue.height : newValue.height
            contentViewY = (_state == .Opened || _state == .Opening) ? 0 : contentViewY
            _contentView.frame = CGRectMake(0, contentViewY, newValue.width, newValue.height)
            updateViews()
        }
    }
    
    override public var backgroundColor:UIColor? {
        get {
            return _contentView.backgroundColor
        }
        set {
            _contentView.backgroundColor = newValue
        }
    }
    
    //
    
    //弹出方向
    public var direction:SurfaceDirection = .Down {
        didSet {
            _contentView.y = direction == .Down ? -_contentView.height : _contentView.height
        }
    }
    
    //显示
    public func show(msg:String, autoClose:Bool = true)
    {
        _label.text = msg
        _label.sizeToFit()
        
        updateViews()
        
        if _state == .Closed || _state == .Closing
        {
            //根据方向决定起始位置
            _contentView.y = (direction == .Down ? -_contentView.height : _contentView.height)
            _state = .Opening
            UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                    self._contentView.y = 0
                }, completion: {finish in
                    self._state = .Opened
            })
        }
        
        if superview == nil
        {
            UIApplication.sharedApplication().keyWindow?.addSubview(self)
        }
        
        clearTimeout(_autoCloseIntervalID)
        if autoClose
        {
            _autoCloseIntervalID = setTimeout(autoCloseDuration, closure:{
                self.dismiss()
            })
        }
        
    }
    
    //隐藏
    public func dismiss()
    {
        if _state == .Opened || _state == .Opening
        {
            _state = .Closing
            UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                self._contentView.y = (self.direction == .Down ? -self._contentView.height : self._contentView.height)
                }, completion: {finish in
                    if self._state == .Closing
                    {
                        self._state = .Closed
                        //self.removeFromSuperview()
                    }
                    
            })
        }
    }
    
    public func dispose()
    {
        dismiss()
        clearTimeout(_autoCloseIntervalID)
        removeFromSuperview()
    }
    
    private func setup()
    {
        clipsToBounds = true
        autoresizingMask = [UIViewAutoresizing.FlexibleWidth]
        //userInteractionEnabled = false
        
        
        _contentView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(_contentView)
        
        
        _label.font = UIFont.systemFontOfSize(14)
        _label.textColor = UIColor.whiteColor()
        _contentView.addSubview(_label)
        
        
        _inited = true
    }
    
    
    private func updateViews()
    {
        var iconX:CGFloat = 0
        var iconY:CGFloat = 0
        var iconWidth:CGFloat = 0
        var iconHeight:CGFloat = 0
        let labelY:CGFloat = titleEdgeInsets.top + (height - titleEdgeInsets.top - _label.height) * 0.5
        var labelX:CGFloat = 0
        
        if let icon = iconView
        {
            let iconRect:CGRect = icon.bounds
            let scale:CGFloat = min((height - iconEdgeInsets.top - iconEdgeInsets.bottom) / iconRect.height, 1)
            if scale < 1
            {
                icon.transform = CGAffineTransformMakeScale(scale, scale)
            }
            iconY = (height - icon.height) * 0.5
            iconWidth = icon.width
            iconHeight = icon.height
        }
        
        if alignment == .Left
        {
            iconX = iconEdgeInsets.left
            labelX = (iconView == nil ? 0 : iconX + iconWidth + iconEdgeInsets.right) + titleEdgeInsets.left
            iconView?.frame = CGRectMake(iconEdgeInsets.left, iconY, iconWidth, iconHeight)
            _label.frame = CGRectMake(labelX, labelY, _label.width, _label.height)
        }
        else
        {
            var contentWidth:CGFloat = iconView == nil ? 0 : iconEdgeInsets.left + iconWidth + iconEdgeInsets.right
            contentWidth += (titleEdgeInsets.left + _label.width + titleEdgeInsets.right)
            let contentX = (width - contentWidth) * 0.5
            labelX = (iconView == nil ? contentX : contentX + iconEdgeInsets.left + iconWidth + iconEdgeInsets.right) + titleEdgeInsets.left
            iconView?.frame = CGRectMake(iconX, iconY, iconWidth, iconHeight)
            _label.frame = CGRectMake(labelX, labelY, _label.width, _label.height)
        }
        
        
    }//end updateView
    
    
    
    
}


