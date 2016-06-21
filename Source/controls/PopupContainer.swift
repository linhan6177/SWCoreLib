//
//  PopupContainer.swift
//  uicomponetTest3
//
//  Created by linhan on 15/6/16.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit

enum SWPopupContainerModelType:Int
{
    //无模态
    case None
    //透明模态(可点击)
    case Clear
    //灰色模态
    case Black
}

@objc protocol SWPopupContainerDelegate:NSObjectProtocol
{
    // before animation and showing view
    optional func willPresentPopupContainer()
    
    // after animation
    optional func didPresentPopupContainer()
    
    // before animation and hiding view
    optional func willDismissPopupContainer()
    
    // after animation
    optional func didDismissPopupContainer()
}

enum SWPopupContainerState:Int
{
    case Opened
    case Opening
    case Closed
    case Closing
}

class PopupContainer: UIView
{
    
    weak var delegate:SWPopupContainerDelegate?
    
    private var _state:SWPopupContainerState = .Closed
    private var _interactionInsets:UIEdgeInsets = UIEdgeInsetsZero
    private var _modelType:SWPopupContainerModelType = .Black
    
    private weak var _content:UIView?
    
    //灰色模态
    private var _modelView:UIView = UIView()
    
    //点击区域
    private var _interactionView:UIView = UIView()
    
    //返回当前打开关闭状态
    var state:SWPopupContainerState
    {
        return _state
    }
    
    init()
    {
        super.init(frame:CGRectZero)
        
        autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        
        addSubview(_modelView)
        
        //可点击区域跟模态区域不一定一样，所以专门放个可点击View
        let tapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "backgorundTapped")
        _interactionView.backgroundColor = UIColor(white: 0, alpha: 0)
        _interactionView.addGestureRecognizer(tapGestureRecognizer)
        addSubview(_interactionView)
    }
    
    deinit
    {
        //println("DEINIT PopupContainer")
    }

     required init(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool
    {
        if let content = _content where _modelType == .None
        {
            let globalRect = content.superview?.convertRect(content.frame, toView: self) ?? CGRectZero
            return globalRect.contains(point)
        }
        if !UIEdgeInsetsEqualToEdgeInsets(_interactionInsets, UIEdgeInsetsZero)
        {
            return _interactionView.frame.contains(point)
        }
        return true
    }
    
    func show(content:UIView, modelType:SWPopupContainerModelType = .Black, container:UIView? = nil, interactionInsets:UIEdgeInsets = UIEdgeInsetsZero, modelInsets:UIEdgeInsets = UIEdgeInsetsZero)
    {
        _modelType = modelType
        _interactionInsets = interactionInsets
        _modelView.backgroundColor = modelType == .Black ? UIColor(white: 0, alpha: 1) : UIColor(white: 0, alpha: 0)
        _modelView.alpha = 0
        
        if let contentContainer = container ?? UIApplication.sharedApplication().keyWindow
        {
            _content = content
            addSubview(content)
            frame = contentContainer.bounds
            
            _modelView.frame = CGRectMake(modelInsets.left, modelInsets.top, bounds.width - modelInsets.left - modelInsets.right, bounds.height - modelInsets.top - modelInsets.bottom)
            _modelView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth, .FlexibleBottomMargin, .FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
            
            _interactionView.frame = CGRectMake(_interactionInsets.left, _interactionInsets.top, bounds.width - _interactionInsets.left - _interactionInsets.right, bounds.height - _interactionInsets.top - _interactionInsets.bottom)
            _interactionView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth, .FlexibleBottomMargin, .FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
            
            contentContainer.addSubview(self)
            
            if _state == .Closed || _state == .Closing
            {
                _state = .Opening
                delegate?.willPresentPopupContainer?()
                
                UIView.animateWithDuration(0.3, animations: {
                    
                    self._modelView.alpha = 0.3
                    
                    }, completion: {(finish:Bool) in
                        
                        self._state = .Opened
                        self.delegate?.didPresentPopupContainer?()
                })
                
            }//end state
        }
        
    }
    
    
    
    //关闭
    func close(animated:Bool = true)
    {
        if _state == .Opened || _state == .Opening
        {
            _state = .Closing
            delegate?.willDismissPopupContainer?()
            if animated
            {
                UIView.animateWithDuration(0.3, animations: {
                    
                    self._modelView.alpha = 0
                    
                    }, completion: {(finish:Bool) in
                        self._state = .Closed
                        self._content?.removeFromSuperview()
                        self.removeFromSuperview()
                        self.delegate?.didDismissPopupContainer?()
                })
            }
            else
            {
                self._state = .Closed
                
                _content?.removeFromSuperview()
                self.removeFromSuperview()
                delegate?.didDismissPopupContainer?()
            }
            
        }//end state
        
    }
    
    @objc private func backgorundTapped()
    {
        close()
    }
    
    
    
    
}

