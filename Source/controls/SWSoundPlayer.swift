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

class SWSoundPlayer:NSObject {
    
    static var filename : String?
    static var enabled : Bool = true
    
    private struct Internal {
        static var cache = [NSURL:SystemSoundID]()
    }
    
    static func playSound(soundFile: String) {
        
        if !enabled {
            return
        }
        
        if let url = NSBundle.mainBundle().URLForResource(soundFile, withExtension: nil) {
            
            var soundID : SystemSoundID = Internal.cache[url] ?? 0
            
            if soundID == 0 {
                AudioServicesCreateSystemSoundID(url, &soundID)
                Internal.cache[url] = soundID
            }
            
            AudioServicesPlaySystemSound(soundID)
            
        } else {
            print("Could not find sound file name `\(soundFile)`")
        }
    }
    
    static func play(fileName: String) {
        self.playSound(fileName)
    }
    
    //震动（静音状态才能震动）
    static func playVibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    
    
}