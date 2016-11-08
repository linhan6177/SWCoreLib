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
    @objc optional func willPresentPulldownContainer()
    
    // after animation
    @objc optional func didPresentPulldownContainer()
    
    // before animation and hiding view
    @objc optional func willDismissPulldownContainer()
    
    // after animation
    @objc optional func didDismissPulldownContainer()
}

private var _instance:PulldownContainer = PulldownContainer()
class PulldownContainer:NSObject,SWPopupContainerDelegate
{
    weak var delegate:PulldownContainerDelegate?
    
    //var modelRect:CGRect = UIScreen.mainScreen().bounds
    var modelInsets:UIEdgeInsets = UIEdgeInsets.zero
    
    lazy private var _popupContainer:PopupContainer = PopupContainer()
    
    lazy private var _container:UIView = UIView()
    
    class func shared()->PulldownContainer
    {
        return _instance
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
    
    
    
    var offset:CGPoint = CGPoint.zero
    {
        didSet
        {
            _container.frame = CGRect(x: offset.x, y: offset.y, width: _container.width, height: _container.height)
        }
    }
    
    
    weak var content:UIView?
    {
        didSet
        {
            if let content = content
            {
                //如果当前正开着，则替换当前显示的内容
                if state == .opened || state == .opening
                {
                    if content != oldValue
                    {
                        content.alpha = 0
                    }
                    _container.addSubview(content)
                    content.frame = CGRect(x: 0, y: 0, width: content.width, height: content.height)
                    UIView.animate(withDuration: 0.3, animations: {
                    
                        if content != oldValue
                        {
                            oldValue?.alpha = 0
                            content.alpha = 1
                        }
                        self._container.frame = CGRect(x: self.offset.x, y: self.offset.y, width: content.width, height: content.height)
                        
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
                    _container.frame = CGRect(x: offset.x, y: offset.y, width: content.width, height: content.height)
                    content.frame = CGRect(x: 0, y: -content.height, width: content.width, height: content.height)
                }
            }//end if let content
        }//end didSet
    }
    
    func open()
    {
        if let _ = content
        {
            _popupContainer.show(_container, modelType: .black, container: nil, interactionInsets: modelInsets, modelInsets: modelInsets)
        }
    }
    
    func close(_ animated:Bool = true)
    {
        _popupContainer.close(animated)
    }
    
    func willPresentPopupContainer()
    {
        UIView.animate(withDuration: 0.3, animations: {
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
        UIView.animate(withDuration: 0.3, animations: {
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
