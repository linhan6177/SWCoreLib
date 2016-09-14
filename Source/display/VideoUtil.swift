//
//  VideoUtil.swift
//  NicePlayer
//
//  Created by linhan on 15/6/2.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import AVFoundation

open class VideoUtil:NSObject
{
    //获取已缓冲完成的可播放时长(以秒为单位)
    class func getAvailableDuration(_ playerItem:AVPlayerItem) -> Double
    {
        var duration:Double = 0
        var loadedTimeRanges = playerItem.loadedTimeRanges
        if loadedTimeRanges.count > 0
        {
            let timeRange:CMTimeRange = loadedTimeRanges[0].timeRangeValue
            let startSeconds:Double = CMTimeGetSeconds(timeRange.start)
            let durationSeconds:Double = CMTimeGetSeconds(timeRange.duration)
            duration = startSeconds + durationSeconds
        }
        return duration
    }
    
    
    
}
