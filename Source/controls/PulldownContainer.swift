//
//  PopupContainer.swift
//  uicomponetTest3
//
//  Created by linhan on 15/8/20.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit

@objc protocol PulldownContainerDelegate:NSObjectProtocol
{
    // before animation and showing view
    optional func willPresentPulldownContainer()
    
    // after animation
    optional func didPresentPulldownContainer()
    
    // before animation and hiding view
    optional func willDismissPulldownContainer()
    
    // after animation
    optional func didDismissPulldownContainer()
}

class PulldownContainer:NSObject,SWPopupContainerDelegate
{
    weak var delegate:PulldownContainerDelegate?
    
    //var modelRect:CGRect = UIScreen.mainScreen().bounds
    var modelInsets:UIEdgeInsets = UIEdgeInsetsZero
    
    lazy private var _popupContainer:PopupContainer = PopupContainer()
    
    lazy private var _container:UIView = UIView()
    
    class func shared()->PulldownContainer
    {
        struct Static {
            static var instance : PulldownContainer? = nil
            static var token : dispatch_once_t = 0
        }
        dispatch_once(&Static.token)
            { Static.instance = PulldownContainer()}
        
        return Static.instance!
    }
    
    override init() {
        super.init()
        setup()
    }
    
    deinit
    {
        print("DEINIT PulldownContainer")
    }
    
    var state:SWPopupContainerState
    {
        return _popupContainer.state
    }
    
    
    
    var offset:CGPoint = CGPointZero
    {
        didSet
        {
            _container.frame = CGRectMake(offset.x, offset.y, _container.width, _container.height)
        }
    }
    
    
    weak var content:UIView?
    {
        didSet
        {
            if let content = content
            {
                //如果当前正开着，则替换当前显示的内容
                if state == .Opened || state == .Opening
                {
                    if content != oldValue
                    {
                        content.alpha = 0
                    }
                    _container.addSubview(content)
                    content.frame = CGRectMake(0, 0, content.width, content.height)
                    UIView.animateWithDuration(0.3, animations: {
                    
                        if content != oldValue
                        {
                            oldValue?.alpha = 0
                            content.alpha = 1
                        }
                        self._container.frame = CGRectMake(self.offset.x, self.offset.y, content.width, content.height)
                        
                        }, completion: {finish in
                    
                            oldValue?.alpha = 1
                            if content != oldValue
                            {
                                oldValue?.removeFromSuperview()
                            }
                    })
                }
                else
                {
                    _container.addSubview(content)
                    _container.frame = CGRectMake(offset.x, offset.y, content.width, content.height)
                    content.frame = CGRectMake(0, -content.height, content.width, content.height)
                }
            }//end if let content
        }//end didSet
    }
    
    func open()
    {
        if let _ = content
        {
            _popupContainer.show(_container, modelType: .Black, container: nil, interactionInsets: modelInsets, modelInsets: modelInsets)
        }
    }
    
    func close(animated:Bool = true)
    {
        _popupContainer.close(animated)
    }
    
    func willPresentPopupContainer()
    {
        UIView.animateWithDuration(0.3, animations: {
            self._container.alpha = 1
            self.content?.y = 0
        })
        delegate?.willPresentPulldownContainer?()
    }
    
    func didPresentPopupContainer()
    {
        delegate?.didPresentPulldownContainer?()
    }
    
    func willDismissPopupContainer()
    {
        UIView.animateWithDuration(0.3, animations: {
            self._container.alpha = 0
            if let content = self.content
            {
                content.y = -content.height
            }
        })
        delegate?.willDismissPulldownContainer?()
    }
    
    func didDismissPopupContainer()
    {
        delegate?.didDismissPulldownContainer?()
    }
    
    private func setup()
    {
        _container.alpha = 0
        _container.clipsToBounds = true
        
        _popupContainer.delegate = self
    }
    
    
    
    
    
    
    
    
}