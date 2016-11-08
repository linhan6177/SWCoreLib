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
    case none
    //透明模态(可点击)
    case clear
    //灰色模态
    case black
}

@objc protocol SWPopupContainerDelegate:NSObjectProtocol
{
    // before animation and showing view
    @objc optional func willPresentPopupContainer()
    
    // after animation
    @objc optional func didPresentPopupContainer()
    
    // before animation and hiding view
    @objc optional func willDismissPopupContainer()
    
    // after animation
    @objc optional func didDismissPopupContainer()
}

enum SWPopupContainerState:Int
{
    case opened
    case opening
    case closed
    case closing
}

class PopupContainer: UIView
{
    
    weak var delegate:SWPopupContainerDelegate?
    
    private var _state:SWPopupContainerState = .closed
    private var _interactionInsets:UIEdgeInsets = UIEdgeInsets.zero
    private var _modelType:SWPopupContainerModelType = .black
    
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
        super.init(frame:CGRect.zero)
        
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        addSubview(_modelView)
        
        //可点击区域跟模态区域不一定一样，所以专门放个可点击View
        let tapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PopupContainer.backgorundTapped))
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
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        if let content = _content , _modelType == .none
        {
            let globalRect = content.superview?.convert(content.frame, to: self) ?? CGRect.zero
            return globalRect.contains(point)
        }
        if !UIEdgeInsetsEqualToEdgeInsets(_interactionInsets, UIEdgeInsets.zero)
        {
            return _interactionView.frame.contains(point)
        }
        return true
    }
    
    func show(_ content:UIView, modelType:SWPopupContainerModelType = .black, container:UIView? = nil, interactionInsets:UIEdgeInsets = UIEdgeInsets.zero, modelInsets:UIEdgeInsets = UIEdgeInsets.zero)
    {
        _modelType = modelType
        _interactionInsets = interactionInsets
        _modelView.backgroundColor = modelType == .black ? UIColor(white: 0, alpha: 1) : UIColor(white: 0, alpha: 0)
        _modelView.alpha = 0
        
        if let contentContainer = container ?? UIApplication.shared.keyWindow
        {
            _content = content
            addSubview(content)
            frame = contentContainer.bounds
            
            _modelView.frame = CGRect(x: modelInsets.left, y: modelInsets.top, width: bounds.width - modelInsets.left - modelInsets.right, height: bounds.height - modelInsets.top - modelInsets.bottom)
            _modelView.autoresizingMask = [.flexibleHeight, .flexibleWidth, .flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
            
            _interactionView.frame = CGRect(x: _interactionInsets.left, y: _interactionInsets.top, width: bounds.width - _interactionInsets.left - _interactionInsets.right, height: bounds.height - _interactionInsets.top - _interactionInsets.bottom)
            _interactionView.autoresizingMask = [.flexibleHeight, .flexibleWidth, .flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
            
            contentContainer.addSubview(self)
            
            if _state == .closed || _state == .closing
            {
                _state = .opening
                delegate?.willPresentPopupContainer?()
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    self._modelView.alpha = 0.3
                    
                    }, completion: {(finish:Bool) in
                        
                        self._state = .opened
                        self.delegate?.didPresentPopupContainer?()
                })
                
            }//end state
        }
        
    }
    
    
    
    //关闭
    func close(_ animated:Bool = true)
    {
        if _state == .opened || _state == .opening
        {
            _state = .closing
            delegate?.willDismissPopupContainer?()
            if animated
            {
                UIView.animate(withDuration: 0.3, animations: {
                    
                    self._modelView.alpha = 0
                    
                    }, completion: {(finish:Bool) in
                        self._state = .closed
                        self._content?.removeFromSuperview()
                        self.removeFromSuperview()
                        self.delegate?.didDismissPopupContainer?()
                })
            }
            else
            {
                self._state = .closed
                
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

