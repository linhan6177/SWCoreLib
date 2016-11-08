//
//  IncrementProgressView.swift
//  uicomponetTest3
//
//  Created by linhan on 15-2-3.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit
class IncrementProgressView: UIView
{
    private var _color:UIColor = UIColor()
    
    private var _running:Bool = false
    private var _finished:Bool = false
    private var _loaded:CGFloat = 0
    private var _increment:CGFloat = 0.1
    
    private var _progressView:UIView = UIView()
    
    var color:UIColor
    {
        get
        {
            return _color
        }
        set
        {
            _color = newValue
            _progressView.backgroundColor = _color
        }
    }
    
    var running:Bool
    {
        return _running
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        _progressView.frame = CGRect(x: 0, y: 0, width: 0, height: frame.height)
        self.addSubview(_progressView)
        color = UIColor.blue
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func start()
    {
        if !_running
        {
            _running = true
            _finished = false
            _loaded = 0.1
            _increment = 0.1
            _progressView.width = _loaded * self.width
            _progressView.alpha = 1
            run()
        }
    }
    
    func finish()
    {
        _finished = true
    }
    
    func reset()
    {
        _running = false
        _finished = false
        _loaded = 0
        _progressView.alpha = 0
    }
    
    func cancel()
    {
        
    }
    
    private func run()
    {
        UIView.animate(withDuration: 0.4, animations: {
            
                self._progressView.width = self._loaded * self.width
            
        
            }, completion: {(complete:Bool) in
        
                if self._finished
                {
                    self._running = false
                    UIView.animate(withDuration: 0.4, animations: {
                        
                        self._progressView.width = self.width
                        self._progressView.alpha = 0
                    })
                }
                else
                {
                    if self._loaded < 0.3
                    {
                        self._increment = 0.1
                    }
                    else if self._loaded < 0.6
                    {
                        self._increment = 0.02
                    }
                    else if self._loaded < 0.9
                    {
                        self._increment = 0.005
                    }
                    else
                    {
                        self._increment = 0.001
                    }
                    
                    
                    self._loaded += self._increment
                    if self._loaded >= 1
                    {
                        self._loaded = 1
                        self._finished = true
                    }
                    self.run()
                }
                
        })
    }
    
}
