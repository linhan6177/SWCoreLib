//
//  SWSoundPlayer.swift
//  SimplePlayer
//
//  Created by linhan on 16/9/9.
//  Copyright © 2016年 linhan. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox
import MediaPlayer

class SWSoundPlayer:NSObject {
    
    static var filename : String?
    static var enabled : Bool = true
    private static var _player:AVAudioPlayer?
    
    private class PlayRecord{
        var maxTimes:Int = 1
        var times:Int = 0
    }
    
    private class Internal:NSObject,AVAudioPlayerDelegate {
        static var cache:[URL:PlayRecord] = [:]
        
        static var instance = Internal()
        
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
        {
            if let url = player.url,
               let record = Internal.cache[url]
            {
                record.times += 1
                if record.maxTimes == 0 || record.times < record.maxTimes
                {
                    print("Replay")
                    player.play()
                    //player.play(atTime: 0)
                }
            }
        }
    }
    
    static func playSound(_ soundFile:String, times:Int = 1)
    {
        if !enabled {
            return
        }
        
        stopAll()
        
        if let url = Bundle.main.url(forResource: soundFile, withExtension: nil) {
            
            /**
            var soundID : SystemSoundID = Internal.cache[url] ?? 0
            
            if soundID == 0 {
                AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
                Internal.cache[url] = soundID
            }
            filename = soundFile
            AudioServicesPlaySystemSound(soundID)
            **/
            
            if let record = Internal.cache[url]
            {
                record.maxTimes = times
                record.times = 0
            }
            else
            {
                let record = PlayRecord()
                record.maxTimes = times
                Internal.cache[url] = record
            }
            
            try? _player = AVAudioPlayer(contentsOf: url)
            _player?.delegate = Internal.instance
            _player?.prepareToPlay()
            _player?.play()
            
        } else {
            print("Could not find sound file name `\(soundFile)`")
        }
    }
    
    
    
//    static func play(_ fileName: String) {
//        self.playSound(fileName)
//    }
    
    static func stop() {
        _player?.stop()
    }
    
    /**
    static func stopSound(soundFile: String)
    {
        
        
        if let url = Bundle.main.url(forResource: soundFile, withExtension: nil),
           let soundID = Internal.cache[url]
        {
            //AudioServicesRemoveSystemSoundCompletion(soundID)
            //Internal.cache.removeValue(forKey: url)
        }
    }**/
 
    
    static func stopAll()
    {
        _player?.stop()
    }
    
    //震动（静音状态才能震动）
    static func playVibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    
    
}
