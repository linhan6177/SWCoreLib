//
//  SWImageCacheManager.swift
//  ChildStory
//
//  Created by linhan on 16/8/24.
//  Copyright © 2016年 Aiya. All rights reserved.
//

import Foundation
import UIKit

private let _cacheManager:SWImageCacheManager = SWImageCacheManager()
class SWImageCacheManager:NSObject
{
    //图片缓存所在目录
    var cacheDirectory:String = ""
    let memoryCache = NSCache()
    
    private var _fileManager = NSFileManager.defaultManager()
    
    let ioQueue: dispatch_queue_t = dispatch_queue_create("com.sw.ImageLoader.ImageCache.ioQueue", DISPATCH_QUEUE_SERIAL)
    let processQueue: dispatch_queue_t = dispatch_queue_create("com.sw.ImageLoader.ImageCache.processQueue", DISPATCH_QUEUE_CONCURRENT)
    
    var maxMemoryCost: UInt = 0 {
        didSet {
            self.memoryCache.totalCostLimit = Int(maxMemoryCost)
        }
    }
    
    var maxDiskCacheSize: UInt = 0
    var maxCachePeriodInSecond: NSTimeInterval = 60 * 60 * 24 * 7 //Cache exists for 1 week
    
    
    class func sharedManager() -> SWImageCacheManager
    {
        return _cacheManager
    }
    
    override init() {
        super.init()
        
        cacheDirectory = (NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).valueAt(0) ?? "") + "/imageloader"
        //        var exists:Bool = false
        //        dispatch_sync(ioQueue) { () -> Void in
        //            exists = self._fileManager.fileExistsAtPath(self.cacheDirectory)
        //        }
        if !_fileManager.fileExistsAtPath(self.cacheDirectory)
        {
            try? _fileManager.createDirectoryAtPath(cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(clearMemoryCache), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(cleanExpiredDiskCache), name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(backgroundCleanExpiredDiskCache), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
    }
    
    //获取本地存储路径
    func fetchStorePath(url:String, options:ImageLoaderOptions, compress:Bool = true) -> String
    {
        let path:String = compress ? "\(cacheDirectory)/\(getStoreKey(url, options:options))" : fetchOriginStorePath(url)
        return path
    }
    
    //获取原图存储路径
    func fetchOriginStorePath(url:String) -> String
    {
        let URLHash:String = SWMD5.md532BitUpper(url)
        let path:String = "\(cacheDirectory)/\(URLHash)"
        return path
    }
    
    //根据图片的URL以及图片保存的相关参数，生成保存到本地的一个key
    func getStoreKey(URL:String, options:ImageLoaderOptions) -> String
    {
        var key:String = SWMD5.md532BitUpper(URL)
        var params:[[String:String]] = []
        for (key,value) in options.dictionary
        {
            params.append(["key":key, "value":valueToString(value)])
        }
        params.sortInPlace({lhs,rhs in lhs["key"] < rhs["key"]})
        for param in params
        {
            key += "_" + (param["key"] ?? "") + "=" + (param["value"] ?? "")
        }
        return key
    }
    
    //把值转化为字符型
    private func valueToString(value:Any) -> String
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
    func hasCache(url:String) -> Bool
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
    func getImage(URL:String, options:ImageLoaderOptions? = nil) -> UIImage?
    {
        if let memoryCacheImage = memoryCache.objectForKey(URL) as? UIImage
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
    
    func saveOriginImage(data:NSData, url:String)
    {
        let path:String = fetchOriginStorePath(url)
        dispatch_async(ioQueue) {
            FileUtility.saveImageCacheToPath(path, image:data)
        }
    }
    
    //清除内存中的缓存
    @objc func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    //清除磁盘中的缓存
    func clearDiskCache(completionHander: (()->())?)
    {
        dispatch_async(SWImageCacheManager.sharedManager().ioQueue, { () -> Void in
            
            do {
                try self._fileManager.removeItemAtPath(self.cacheDirectory)
                try self._fileManager.createDirectoryAtPath(self.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
            
            if let completionHander = completionHander {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
    func cleanExpiredDiskCacheWithCompletionHander(completionHandler: (()->())?) {
        
        // Do things in cocurrent io queue
        dispatch_async(ioQueue, { () -> Void in
            
            var (URLsToDelete, diskCacheSize, cachedFiles) = self.travelCachedFiles(onlyForCacheSize: false)
            
            for fileURL in URLsToDelete {
                do {
                    try self._fileManager.removeItemAtURL(fileURL)
                } catch _ {
                }
            }
            
            if self.maxDiskCacheSize > 0 && diskCacheSize > self.maxDiskCacheSize {
                let targetSize = self.maxDiskCacheSize / 2
                
                // Sort files by last modify date. We want to clean from the oldest files.
                let sortedFiles = cachedFiles.keysSortedByValue {
                    resourceValue1, resourceValue2 -> Bool in
                    
                    if let date1 = resourceValue1[NSURLContentModificationDateKey] as? NSDate,
                        date2 = resourceValue2[NSURLContentModificationDateKey] as? NSDate {
                        return date1.compare(date2) == .OrderedAscending
                    }
                    // Not valid date information. This should not happen. Just in case.
                    return true
                }
                
                for fileURL in sortedFiles {
                    
                    do {
                        try self._fileManager.removeItemAtURL(fileURL)
                    } catch {
                        
                    }
                    
                    URLsToDelete.append(fileURL)
                    
                    if let fileSize = cachedFiles[fileURL]?[NSURLTotalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize -= fileSize.unsignedLongValue
                    }
                    
                    if diskCacheSize < targetSize {
                        break
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if URLsToDelete.count != 0 {
                    let cleanedHashes = URLsToDelete.map({ (url) -> String in
                        return url.lastPathComponent!
                    })
                    
                    //NSNotificationCenter.defaultCenter().postNotificationName(KingfisherDidCleanDiskCacheNotification, object: self, userInfo: [KingfisherDiskCacheCleanedHashKey: cleanedHashes])
                }
                
                completionHandler?()
            })
        })
    }
    
    private func travelCachedFiles(onlyForCacheSize onlyForCacheSize: Bool) -> (URLsToDelete: [NSURL], diskCacheSize: UInt, cachedFiles: [NSURL: [NSObject: AnyObject]]) {
        
        let diskCacheURL = NSURL(fileURLWithPath: cacheDirectory)
        let resourceKeys = [NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey]
        let expiredDate = NSDate(timeIntervalSinceNow: -self.maxCachePeriodInSecond)
        
        var cachedFiles = [NSURL: [NSObject: AnyObject]]()
        var URLsToDelete = [NSURL]()
        var diskCacheSize: UInt = 0
        
        if let fileEnumerator = self._fileManager.enumeratorAtURL(diskCacheURL, includingPropertiesForKeys: resourceKeys, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil),
            urls = fileEnumerator.allObjects as? [NSURL] {
            for fileURL in urls {
                
                do {
                    let resourceValues = try fileURL.resourceValuesForKeys(resourceKeys)
                    // If it is a Directory. Continue to next file URL.
                    if let isDirectory = resourceValues[NSURLIsDirectoryKey] as? NSNumber {
                        if isDirectory.boolValue {
                            continue
                        }
                    }
                    
                    if !onlyForCacheSize {
                        // If this file is expired, add it to URLsToDelete
                        if let modificationDate = resourceValues[NSURLContentModificationDateKey] as? NSDate {
                            if modificationDate.laterDate(expiredDate) == expiredDate {
                                URLsToDelete.append(fileURL)
                                continue
                            }
                        }
                    }
                    
                    if let fileSize = resourceValues[NSURLTotalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize += fileSize.unsignedLongValue
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
        let sharedApplication = UIApplication.sharedApplication()
        
        func endBackgroundTask(inout task: UIBackgroundTaskIdentifier) {
            sharedApplication.endBackgroundTask(task)
            task = UIBackgroundTaskInvalid
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        
        backgroundTask = sharedApplication.beginBackgroundTaskWithExpirationHandler { () -> Void in
            endBackgroundTask(&backgroundTask!)
        }
        
        cleanExpiredDiskCacheWithCompletionHander { () -> () in
            endBackgroundTask(&backgroundTask!)
        }
    }
    
    
    
    
    
}