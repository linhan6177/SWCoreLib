//
//  SWSequenceAnimation.swift
//  图片系列动画
//
//  Created by linhan on 16/9/12.
//  Copyright © 2016年 test. All rights reserved.
//

import Foundation
import UIKit
class SWSequenceAnimation: UIImageView
{
    var imagesLoadedCompleteCallback:(([UIImage])->Void)?
    var animateCompleteCallback:((UIView)->Void)?
    
    //private var _images:[UIImage] = []
    fileprivate var _totalFrames:Int = 0
    
    //帧频
    fileprivate var _frameRate:Int = 1
    var frameRate:Int{
        get{
            return _frameRate
        }
        set{
            _frameRate = newValue
            animationDuration = (1 / Double(newValue)) * Double(totalFrames)
        }
    }
    
    var totalFrames:Int {
        return _totalFrames
    }
    
    //循环播放
    var loop:Bool = false
    
    init(images:[UIImage], frameRate:Int = 12)
    {
        super.init(frame:CGRect.zero)
        _totalFrames = images.count
        self.frameRate = frameRate
        setAnimationImages(images)
        setup()
    }
    
    init(paths:[String], frameRate:Int = 12)
    {
        super.init(frame:CGRect.zero)
        _frameRate = frameRate
        loadImages(paths)
        setup()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setup()
    {
        //animationRepeatCount = 100000
        //animationRepeatCount = 0
    }
    
    fileprivate func setAnimationImages(_ images:[UIImage])
    {
        animationImages = images
        if images.count > 0
        {
            //如果未设置宽高，则imageView的宽高按第一张算
            if frame.size.isEmpty{
                frame = CGRect(origin: frame.origin, size: images[0].retinaSize)
            }
            startAnimating()
            
            //如果不进行循环播放,则停留在最后一帧
            if !loop
            {
                let duration = animationDuration - (1 / Double(_frameRate))
                let nanoSeconds = Int64((duration) * Double(NSEC_PER_SEC))
                let time = DispatchTime.now() + Double(nanoSeconds) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    
                    if let image = self.animationImages?.last
                    {
                        self.stopAnimating()
                        self.image = image
                    }
                    
                    self.animateCompleteCallback?(self)
                })//end dispatch_after
            }//end loop
        }
        else
        {
            stopAnimating()
        }
    }
    
    fileprivate func loadImages(_ paths:[String])
    {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            var images:[UIImage] = []
            for path in paths{
                if let image:UIImage = UIImage(contentsOfFile: path)
                {
                    images.append(image)
                }
            }
            self._totalFrames = images.count
            self.frameRate = self._frameRate
            DispatchQueue.main.async{
                
                self.setAnimationImages(images)
                self.imagesLoadedCompleteCallback?(images)
            }
            
        }//end global queue
    }
    
    
    
    
}
