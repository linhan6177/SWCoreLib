//
//  FileUtility.swift
//  JokeClient-Swift
//
//  Created by YANGReal on 14-6-7.
//  Copyright (c) 2014年 YANGReal. All rights reserved.
//

import UIKit

class FileUtility: NSObject {
   
    
    class func imageCachePath(_ fileName:String)->String
    {
      var arr =  NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
       let path = arr[0] 
        return "\(path)/\(fileName)"
    }
    
    class func documentPath(_ fileName:String)->String?
    {
        let array:[AnyObject]? = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [AnyObject]?
        if let array = array , array.count > 0,let basePath = array[0] as? String
        {
            return "\(basePath)/\(fileName)"
        }
        return nil
    }
    
    class func saveImageCacheToPath(_ path:String,image:Data)->Bool
    {
       return ((try? image.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil)
    }
    
    class func imageDataFromPath(_ path:String)->UIImage?
    {
        let exist = FileManager.default.fileExists(atPath: path)
        if exist
        {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),let image = UIImage(data: data, scale: UIScreen.main.scale)
            {
                return image
            }
        }
        return nil
    }
    
    //通过文件名获取文件缓存路径
    class func fileCachePath(_ name:String) -> String
    {
        var arr =  NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let path = arr[0] 
        return "\(path)/\(name)"
    }
    
    //通过文件名获取文件的hash缓存路径
    class func getHashPath(_ name:String) -> String
    {
        let hash:String = SWMD5.md532BitUpper(name)
        return fileCachePath(hash)
    }
    
    //通过文件路径获取文件内容
    class func getFileFromPath(_ path:String) -> Data?
    {
        let exist = FileManager.default.fileExists(atPath: path)
        var data:Data?
        if exist
        {
            data = try? Data(contentsOf: URL(fileURLWithPath: path))
        }
        return data
    }
    
    
    //容量字符化
    class func memoryFormatter(_ diskSpace:Double)->String
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
    class func fileSizeAtPath(_ path:String) -> Int
    {
        let manager:FileManager = FileManager.default
        if manager.fileExists(atPath: path)
        {
            var attributes:[AnyHashable: Any]?
            do
            {
                attributes = try manager.attributesOfItem(atPath: path)
            }
            catch {}
            if let attributes = attributes
            {
                return attributes[FileAttributeKey.size] as? Int ?? 0
            }
        }
        return 0
    }
    
    //获取某个文件夹下文件大小总和
    class func folderSizeAtPath(_ path:String)-> Int
    {
        let manager:FileManager = FileManager.default
        if !manager.fileExists(atPath: path)
        {
            return 0
        }
        
        var folderSize:Int = 0
        if let files = manager.subpaths(atPath: path) , files.count > 0
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
    class func removeAll(_ path:String)
    {
        let manager:FileManager = FileManager.default
        if let files = manager.subpaths(atPath: path) , files.count > 0
        {
            for i in 0..<files.count
            {
                let name = files[i]
                if name != ""
                {
                    let filePath:String = path + "/" + name
                    if manager.fileExists(atPath: filePath)
                    {
                        do
                        {
                            try manager.removeItem(atPath: filePath)
                        }
                        catch{}
                    }
                }
            }
        }
    }
    
    
}
