//
//  SWImageCacheManager.swift
//  ChildStory
//
//  Created by linhan on 16/8/24.
//  Copyright © 2016年 Aiya. All rights reserved.
//

import Foundation
import UIKit
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


private let _cacheManager:SWImageCacheManager = SWImageCacheManager()
class SWImageCacheManager:NSObject
{
    //图片缓存所在目录
    var cacheDirectory:String = ""
    let memoryCache = NSCache<NSString, AnyObject>()
    
    private var _fileManager = FileManager.default
    
    let ioQueue: DispatchQueue = DispatchQueue(label: "com.sw.ImageLoader.ImageCache.ioQueue", attributes: [])
    let processQueue: DispatchQueue = DispatchQueue(label: "com.sw.ImageLoader.ImageCache.processQueue", attributes: DispatchQueue.Attributes.concurrent)
    
    var maxMemoryCost: UInt = 0 {
        didSet {
            self.memoryCache.totalCostLimit = Int(maxMemoryCost)
        }
    }
    
    var maxDiskCacheSize: UInt = 0
    var maxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7 //Cache exists for 1 week
    
    
    class func sharedManager() -> SWImageCacheManager
    {
        return _cacheManager
    }
    
    override init() {
        super.init()
        
        cacheDirectory = (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).valueAt(0) ?? "") + "/imageloader"
        //        var exists:Bool = false
        //        dispatch_sync(ioQueue) { () -> Void in
        //            exists = self._fileManager.fileExistsAtPath(self.cacheDirectory)
        //        }
        if !_fileManager.fileExists(atPath: self.cacheDirectory)
        {
            try? _fileManager.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(clearMemoryCache), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cleanExpiredDiskCache), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundCleanExpiredDiskCache), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
    }
    
    //获取本地存储路径
    func fetchStorePath(_ url:String, options:ImageLoaderOptions, compress:Bool = true) -> String
    {
        let path:String = compress ? "\(cacheDirectory)/\(getStoreKey(url, options:options))" : fetchOriginStorePath(url)
        return path
    }
    
    //获取原图存储路径
    func fetchOriginStorePath(_ url:String) -> String
    {
        let URLHash:String = SWMD5.md532BitUpper(url)
        let path:String = "\(cacheDirectory)/\(URLHash)"
        return path
    }
    
    //根据图片的URL以及图片保存的相关参数，生成保存到本地的一个key
    func getStoreKey(_ URL:String, options:ImageLoaderOptions) -> String
    {
        var key:String = SWMD5.md532BitUpper(URL)
        var params:[[String:String]] = []
        for (key,value) in options.dictionary
        {
            params.append(["key":key, "value":valueToString(value)])
        }
        params.sort(by: {lhs,rhs in lhs["key"] < rhs["key"]})
        for param in params
        {
            key += "_" + (param["key"] ?? "") + "=" + (param["value"] ?? "")
        }
        return key
    }
    
    //把值转化为字符型
    private func valueToString(_ value:Any) -> String
    {
        var sting:String
        if let size = value as? CGSize
        {
            sting = "\(Int(size.width))x\(Int(size.height))"
        }
        else if let color = value as? UIColor
        {
            sting = "\(color.hexValue)"
        }
        else
        {
            sting = "\(value)"
        }
        return sting
    }
    
    //是否有某图片的缓存
    func hasCache(_ url:String) -> Bool
    {
        //        let cacheFilenameHash:String = SWMD5.md532BitUpper(url)
        //        if let _ = NSCache().objectForKey(cacheFilenameHash) as? UIImage
        //        {
        //            return true
        //        }
        //let path = getStoreKey(url, )
        //return NSFileManager.defaultManager().fileExistsAtPath(path)
        return false
    }
    
    //通过图片URL以及相关存储参数获取本地缓存图片，如无参数，则返回原图
    func getImage(_ URL:String, options:ImageLoaderOptions? = nil) -> UIImage?
    {
        if let memoryCacheImage = memoryCache.object(forKey: URL as NSString) as? UIImage
        {
            return memoryCacheImage
        }
        if let options = options
        {
            let cachePath:String = "\(cacheDirectory)/\(getStoreKey(URL, options:options))"
            return FileUtility.imageDataFromPath(cachePath)
        }
        else
        {
            return FileUtility.imageDataFromPath(fetchOriginStorePath(URL))
        }
        return nil
    }
    
    func saveOriginImage(_ data:Data, url:String)
    {
        let path:String = fetchOriginStorePath(url)
        ioQueue.async {
            FileUtility.saveImageCacheToPath(path, image:data)
        }
    }
    
    //清除内存中的缓存
    @objc func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    //清除磁盘中的缓存
    func clearDiskCache(_ completionHander: (()->())?)
    {
        SWImageCacheManager.sharedManager().ioQueue.async(execute: { () -> Void in
            
            do {
                try self._fileManager.removeItem(atPath: self.cacheDirectory)
                try self._fileManager.createDirectory(atPath: self.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
            
            if let completionHander = completionHander {
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHander()
                })
            }
        })
    }
    
    /**
     Clean expired disk cache. This is an async operation.
     */
    @objc func cleanExpiredDiskCache() {
        cleanExpiredDiskCacheWithCompletionHander(nil)
    }
    
    /**
     Clean expired disk cache. This is an async operation.
     
     - parameter completionHandler: Called after the operation completes.
     */
    func cleanExpiredDiskCacheWithCompletionHander(_ completionHandler: (()->())?) {
        
        // Do things in cocurrent io queue
        ioQueue.async(execute: { () -> Void in
            
            var (URLsToDelete, diskCacheSize, cachedFiles) = self.travelCachedFiles(onlyForCacheSize: false)
            
            for fileURL in URLsToDelete {
                do {
                    try self._fileManager.removeItem(at: fileURL)
                } catch _ {
                }
            }
            
            if self.maxDiskCacheSize > 0 && diskCacheSize > self.maxDiskCacheSize {
                let targetSize = self.maxDiskCacheSize / 2
                
                // Sort files by last modify date. We want to clean from the oldest files.
                let sortedFiles = cachedFiles.keysSortedByValue {
                    resourceValue1, resourceValue2 -> Bool in
                    
                    if let date1 = resourceValue1[URLResourceKey.contentModificationDateKey] as? Date,
                        let date2 = resourceValue2[URLResourceKey.contentModificationDateKey] as? Date {
                        return date1.compare(date2) == .orderedAscending
                    }
                    // Not valid date information. This should not happen. Just in case.
                    return true
                }
                
                for fileURL in sortedFiles {
                    
                    do {
                        try self._fileManager.removeItem(at: fileURL)
                    } catch {
                        
                    }
                    
                    URLsToDelete.append(fileURL)
                    
                    if let fileSize = cachedFiles[fileURL]?[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize -= fileSize.uintValue
                    }
                    
                    if diskCacheSize < targetSize {
                        break
                    }
                }
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                if URLsToDelete.count != 0 {
                    let cleanedHashes = URLsToDelete.map({ (url) -> String in
                        return url.lastPathComponent
                    })
                    
                    //NotificationCenter.default.post(name:KingfisherDidCleanDiskCacheNotification, object: self, userInfo: [KingfisherDiskCacheCleanedHashKey: cleanedHashes])
                }
                
                completionHandler?()
            })
        })
    }
    
    private func travelCachedFiles(onlyForCacheSize: Bool) -> (URLsToDelete: [URL], diskCacheSize: UInt, cachedFiles: [URL: [AnyHashable: Any]]) {
        
        let diskCacheURL = URL(fileURLWithPath: cacheDirectory)
        let resourceKeys = [URLResourceKey.isDirectoryKey, URLResourceKey.contentModificationDateKey, URLResourceKey.totalFileAllocatedSizeKey]
        let expiredDate = Date(timeIntervalSinceNow: -self.maxCachePeriodInSecond)
        
        var cachedFiles = [URL: [AnyHashable: Any]]()
        var URLsToDelete = [URL]()
        var diskCacheSize: UInt = 0
        
        if let fileEnumerator = self._fileManager.enumerator(at: diskCacheURL, includingPropertiesForKeys: resourceKeys, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, errorHandler: nil),
            let urls = fileEnumerator.allObjects as? [URL] {
            for fileURL in urls {
                
                do {
                    let resourceValues = try (fileURL as NSURL).resourceValues(forKeys: resourceKeys)
                    // If it is a Directory. Continue to next file URL.
                    if let isDirectory = resourceValues[URLResourceKey.isDirectoryKey] as? NSNumber {
                        if isDirectory.boolValue {
                            continue
                        }
                    }
                    
                    if !onlyForCacheSize {
                        // If this file is expired, add it to URLsToDelete
                        if let modificationDate = resourceValues[URLResourceKey.contentModificationDateKey] as? Date {
                            if (modificationDate as NSDate).laterDate(expiredDate) == expiredDate {
                                URLsToDelete.append(fileURL)
                                continue
                            }
                        }
                    }
                    
                    if let fileSize = resourceValues[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize += fileSize.uintValue
                        if !onlyForCacheSize {
                            cachedFiles[fileURL] = resourceValues
                        }
                    }
                } catch _ {
                }
            }
        }
        
        return (URLsToDelete, diskCacheSize, cachedFiles)
    }
    
    @objc func backgroundCleanExpiredDiskCache() {
        // if 'sharedApplication()' is unavailable, then return
        let sharedApplication = UIApplication.shared
        
        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            sharedApplication.endBackgroundTask(task)
            task = UIBackgroundTaskInvalid
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        
        backgroundTask = sharedApplication.beginBackgroundTask (expirationHandler: { () -> Void in
            endBackgroundTask(&backgroundTask!)
        })
        
        cleanExpiredDiskCacheWithCompletionHander { () -> () in
            endBackgroundTask(&backgroundTask!)
        }
    }
    
    
    
    
    
}
