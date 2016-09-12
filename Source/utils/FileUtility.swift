//
//  FileUtility.swift
//  JokeClient-Swift
//
//  Created by YANGReal on 14-6-7.
//  Copyright (c) 2014年 YANGReal. All rights reserved.
//

import UIKit

class FileUtility: NSObject {
   
    
    class func imageCachePath(fileName:String)->String
    {
      var arr =  NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
       let path = arr[0] 
        return "\(path)/\(fileName)"
    }
    
    class func documentPath(fileName:String)->String?
    {
        let array:[AnyObject]? = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        if let array = array where array.count > 0,let basePath = array[0] as? String
        {
            return "\(basePath)/\(fileName)"
        }
        return nil
    }
    
    class func saveImageCacheToPath(path:String,image:NSData)->Bool
    {
       return image.writeToFile(path, atomically: true)
    }
    
    class func imageDataFromPath(path:String)->UIImage?
    {
        let exist = NSFileManager.defaultManager().fileExistsAtPath(path)
        if exist
        {
            if let data = NSData(contentsOfFile: path),image = UIImage(data: data, scale: UIScreen.mainScreen().scale)
            {
                return image
            }
        }
        return nil
    }
    
    //通过文件名获取文件缓存路径
    class func fileCachePath(name:String) -> String
    {
        var arr =  NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        let path = arr[0] 
        return "\(path)/\(name)"
    }
    
    //通过文件名获取文件的hash缓存路径
    class func getHashPath(name:String) -> String
    {
        let hash:String = SWMD5.md532BitUpper(name)
        return fileCachePath(hash)
    }
    
    //通过文件路径获取文件内容
    class func getFileFromPath(path:String) -> NSData?
    {
        let exist = NSFileManager.defaultManager().fileExistsAtPath(path)
        var data:NSData?
        if exist
        {
            data = NSData(contentsOfFile: path)
        }
        return data
    }
    
    
    //容量字符化
    class func memoryFormatter(diskSpace:Double)->String
    {
        var formatted:String = ""
        let KB:Double = 1024
        let MB:Double = KB * 1024
        let GB:Double = MB * 1024
        let bytes:Double = diskSpace
        let kilobytes:Double = bytes / KB;
        let megabytes:Double = bytes / MB;
        let gigabytes:Double = bytes / GB;
        if gigabytes >= 1
        {
            formatted = String(format: "%.2f GB", gigabytes)
        }
        else if megabytes >= 1
        {
            formatted = String(format: "%.2f MB", megabytes)
        }
        else if kilobytes >= 1
        {
            formatted = String(format: "%.2f KB", kilobytes)
        }
        else
        {
            formatted = String(format: "%.2f B", bytes)
        }
        return formatted
    }
    
    //获取某个文件大小
    class func fileSizeAtPath(path:String) -> Int
    {
        let manager:NSFileManager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(path)
        {
            var attributes:[NSObject : AnyObject]?
            do
            {
                attributes = try manager.attributesOfItemAtPath(path)
            }
            catch {}
            if let attributes = attributes
            {
                return attributes[NSFileSize] as? Int ?? 0
            }
        }
        return 0
    }
    
    //获取某个文件夹下文件大小总和
    class func folderSizeAtPath(path:String)-> Int
    {
        let manager:NSFileManager = NSFileManager.defaultManager()
        if !manager.fileExistsAtPath(path)
        {
            return 0
        }
        
        var folderSize:Int = 0
        if let files = manager.subpathsAtPath(path) where files.count > 0
        {
            for file in files
            {
                let filePath:String = path + "/" + file
                folderSize += fileSizeAtPath(filePath)
            }
        }
        
        return folderSize
    }
    
    //清除缓存
    class func removeAll(path:String)
    {
        let manager:NSFileManager = NSFileManager.defaultManager()
        if let files = manager.subpathsAtPath(path) where files.count > 0
        {
            for i in 0..<files.count
            {
                let name = files[i]
                if name != ""
                {
                    let filePath:String = path + "/" + name
                    if manager.fileExistsAtPath(filePath)
                    {
                        do
                        {
                            try manager.removeItemAtPath(filePath)
                        }
                        catch{}
                    }
                }
            }
        }
    }
    
    
}
