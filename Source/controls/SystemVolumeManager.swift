//
//  SystemVolumeManager.swift
//  SimplePlayer
//
//  Created by linhan on 15-5-18.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer

private let _sharedManager:SystemVolumeManager = SystemVolumeManager()

class SystemVolumeManager: NSObject
{
    class var SystemVolumeDidChangeNotificationName:String
    {
        return "SystemVolumeManager_SystemVolumeDidChangeNotification"
    }
    
    //获取\设置系统音量，值从0到1
    private var _volume:Float = 0
    
    //音量调节浮层是否隐藏(默认为不隐藏)
    private var _volumeViewHidden:Bool = false
    
    private var _volumeViewSlider:UISlider?
    private var _volumeView:MPVolumeView
    
    class var sharedManager:SystemVolumeManager
    {
        return _sharedManager
    }
    
    override init()
    {
        _volumeView = MPVolumeView(frame: CGRectMake(-2000, -2000, 100, 100))
        super.init()
        
        _volume = AVAudioSession.sharedInstance().outputVolume
        
        _volumeView.hidden = false
        
        for subview in _volumeView.subviews
        {
            if subview is UISlider
            {
                _volumeViewSlider = subview as? UISlider
                break
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(volumeChanged(_:)), name: "AVSystemController_SystemVolumeDidChangeNotification", object: nil)
    }
    
    
    
    //音量调节浮层是否隐藏(默认为不隐藏)
    ////MPVolumeView只有被添加到视图上，才能进行隐藏
    var volumeViewHidden:Bool = false
    {
        didSet
        {
            if volumeViewHidden != oldValue
            {
                if volumeViewHidden
                {
                    //_volumeView.frame = CGRectMake(_volumeViewHidden ? -2000 : 100, -2000, 100, 100)
                    UIApplication.sharedApplication().keyWindow?.addSubview(_volumeView)
                    //print("otherAudioPlaying:", AVAudioSession.sharedInstance().otherAudioPlaying)
//                    if AVAudioSession.sharedInstance().otherAudioPlaying {
//                        // 场景1
//                        try? AVAudioSession.sharedInstance().setActive(true)
//                    } else {
//                        // 场景2
//                        try? AVAudioSession.sharedInstance().setActive(true)
//                    }
                }
                else
                {
                    _volumeView.removeFromSuperview()
                    //try? AVAudioSession.sharedInstance().setActive(false)
                }
                
            }
        }
    }
    
    //获取\设置系统音量，值从0到1
    var volume:Float
    {
        get
        {
            return _volume
        }
        set
        {
            let newVolume = min(max(newValue, 0),1)
            if let slider = _volumeViewSlider where _volume != newVolume
            {
                slider.value = newVolume
                slider.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                //_volume = newVolume
            }
        }
    }
    
    //监听系统音量变化
    @objc private func volumeChanged(notification:NSNotification)
    {
        if var volume = notification.userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as? Float
        {
            volume = min(max(volume, 0),1)
            if volume != _volume
            {
                _volume = volume
                NSNotificationCenter.defaultCenter().postNotificationName(SystemVolumeManager.SystemVolumeDidChangeNotificationName, object: nil)
            }
        }
    }
    
}//end class

