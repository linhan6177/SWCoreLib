//
//  Downloader.swift
//  JokeSiJie
//
//  Created by linhan on 14-11-27.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
import UIKit

class ImageLoader: UIImageView
{
    var options:ImageLoaderOptions = ImageLoaderOptions() {
        didSet {
            options.containerSize = frame.size
            options.contentMode = contentMode
        }
    }
    
    var startCallback:(() -> Void)?
    var failCallback:((NSError) -> Void)?
    var progressCallback:((Int, Int) -> Void)?
    var completeCallback:((UIImageView, Bool) -> Void)?
    
    
    private let errorDomain:String = "com.sw.ImageLoader"
    
    
    private var _downloader:Downloader = Downloader()
    
    private var _cachePath:String = ""
    private var _url:String = ""
    private var _compressForCache:Bool = true
    
    //Memory
    
    //当前是否处于网络加载中
    private var _loading:Bool = false
    //图片是否正在处理中（从本地加载、圆角、裁剪等处理）
    private var _processing = false
    
    init()
    {
        super.init(frame: CGRectZero)
        setup()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        //print("DEINIT ImageLoader")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override var frame:CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            options.containerSize = frame.size
        }
    }
    
    override var contentMode:UIViewContentMode {
        get {
            return super.contentMode
        }
        set {
            super.contentMode = newValue
            options.contentMode = newValue
        }
    }
    
    //加载图片
    //url：图片地址
    //compressForCache:压缩图片以进行缓存
    func load(url:String, compressForCache:Bool = true)
    {
        if url == ""
        {
            //url为空，如果有默认图则显示默认图，如果没有，则显示空
            image = placeholderImage
            return
        }
        
        //避免重复加载造成界面频繁刷新
        if _url == url
        {
            //如果当前图片正在加载或者正常处理，跳过
            if image != nil || _processing || _loading
            {
                return
            }
        }
        _url = url
        
        if options.clearBefore
        {
            image = nil
        }
        
        //如果当前的图片还没加载完，马上又要加载新的图片，则先将当前的任务取消
        if _loading
        {
            cancel()
            _loading = false
        }
        _compressForCache = compressForCache
        _cachePath = SWImageCacheManager.sharedManager().fetchStorePath(url, options: options, compress: compressForCache && !frame.isEmpty)
        
        //如果当前内存中有原图，则用内存中的原图加工处理完各种所需的规格
        if let memoryCacheImage = SWImageCacheManager.sharedManager().memoryCache.objectForKey(url) as? UIImage
        {
            if imageProcessHandler(memoryCacheImage, readCache:true)
            {
                return
            }
            else
            {
                image = memoryCacheImage
            }
        }
        
        _processing = true
        dispatch_async(SWImageCacheManager.sharedManager().ioQueue,
                       {
                        let cachedURL = url
                        let orginPath = SWImageCacheManager.sharedManager().fetchOriginStorePath(url)
                        //先读取相关尺寸图片的缓存
                        if let cacheImage:UIImage = FileUtility.imageDataFromPath(self._cachePath)
                        {
                            if self._url == cachedURL
                            {
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.completeHandler(cacheImage, readCache:true)
                                }
                            }
                        }
                            //如果有原图缓存，则用原图进行处理成对应规格
                        else if let originImage = FileUtility.imageDataFromPath(orginPath)
                        {
                            if self.imageProcessHandler(originImage, readCache:true)
                            {
                                return
                            }
                            else
                            {
                                if self._url == cachedURL
                                {
                                    dispatch_async(dispatch_get_main_queue()) {
                                        self.completeHandler(originImage, readCache:true)
                                    }
                                }
                            }
                        }
                            //什么都没有则网络加载
                        else
                        {
                            dispatch_async(dispatch_get_main_queue()) {
                                if let placeholderImage = self.placeholderImage
                                {
                                    self.image = placeholderImage
                                }
                                self._loading = true
                                self._downloader.load(url)
                            }
                        }
                        
        })//end ioQueue
    }
    
    weak var placeholderImage:UIImage?
    //加载图片
    //url：图片地址
    //placeholderImage:图片还未加载完成时的占位图
    //compressForCache:压缩图片以进行缓存
    func load(url:String, placeholderImage:UIImage?, compressForCache:Bool = true)
    {
        self.placeholderImage = placeholderImage
        load(url, compressForCache:compressForCache)
    }
    
    //异步方式加载本地图片
    func load(contentsOfFile file:String)
    {
        _processing = true
        dispatch_async(SWImageCacheManager.sharedManager().ioQueue,
                       {
                        if let data = NSData(contentsOfFile: file),
                            let image = UIImage(data: data, scale: UIScreen.mainScreen().scale)
                        {
                            dispatch_async(dispatch_get_main_queue(),
                                {
                                    //self.image = image
                                    self.completeHandler(image, readCache:true)
                            })
                        }
        })
    }
    
    func cancel()
    {
        _loading = false
        _downloader.cancel()
        layer.removeAllAnimations()
    }
    
    private func setup()
    {
        _downloader.cachePolicy = .ReturnCacheDataElseLoad
        _downloader.timeoutInterval = 10
        _downloader.startCallback = {[weak self] in self?.startCallback?()}
        _downloader.failCallback = {[weak self] error in
            self?.loadFailCallback(error)
        }
        _downloader.progressCallback = {[weak self] current, total in
            self?.loadProgressCallback(current, totalBytes: total)
        }
        _downloader.completeCallback = {[weak self] data in
            self?.loadCompleteCallback(data)
        }
    }
    
    private func loadFailCallback(error:NSError)
    {
        _loading = false
        failCallback?(error)
    }
    
    private func loadProgressCallback(loadedBytes:Int, totalBytes:Int)
    {
        progressCallback?(loadedBytes, totalBytes)
    }
    
    private func loadCompleteCallback(data:NSData)
    {
        _loading = false
        if options.diskCacheForOrigin
        {
            SWImageCacheManager.sharedManager().saveOriginImage(data, url: _url)
        }
        
        if let loadedImage = UIImage(data: data)
        {
            let compress = imageProcessHandler(loadedImage)
            //如果图片未达到压缩的条件，则直接保存原图
            if let cgImage = loadedImage.CGImage where !compress
            {
                let image = UIImage(CGImage: cgImage, scale: UIScreen.mainScreen().scale, orientation: loadedImage.imageOrientation)
                let path:String = _cachePath
                dispatch_async(SWImageCacheManager.sharedManager().ioQueue) {
                    FileUtility.saveImageCacheToPath(path, image:data)
                }
                
                completeHandler(image, readCache:false)
            }
            
            if options.memoryCacheForOrigin && _url != ""
            {
                SWImageCacheManager.sharedManager().memoryCache.setObject(loadedImage, forKey: _url)
            }
        }
        else
        {
            loadFailCallback(NSError(domain: errorDomain, code: 0, userInfo: nil))
        }
    }
    
    //图片进行压缩、裁剪、圆角等处理(返回值为是否处理过)
    private func imageProcessHandler(loadedImage:UIImage, readCache:Bool = false) -> Bool
    {
        var compress:Bool = false
        if _compressForCache && !frame.isEmpty
        {
            var scale:CGFloat
            //分辨率越高的设备，需要更大的图片来满足清晰度，可视为容器的宽高更大
            let ContainerWidth:CGFloat = frame.width
            let ContainerHeight:CGFloat = frame.height
            
            //将下载下来的图片进行压缩
            var newSize:CGSize = frame.size
            var needResize:Bool = false
            if options.fitMode == .Crop
            {
                scale = ViewUtil.getAdaptiveScale(loadedImage.size.width, targetH: loadedImage.size.height, containerW: ContainerWidth, containerH: ContainerHeight, inscribed: false)
                newSize = CGSizeMake(loadedImage.size.width * scale, loadedImage.size.height * scale)
                needResize = true
            }
            else if options.fitMode == .Clip
            {
                scale = ViewUtil.getAdaptiveScale(loadedImage.size.width, targetH: loadedImage.size.height, containerW: ContainerWidth, containerH: ContainerHeight, inscribed: true)
                newSize = CGSizeMake(loadedImage.size.width * scale, loadedImage.size.height * scale)
                needResize = true
            }
            else
            {
                needResize = true
            }
            
            if needResize
            {
                compress = true
                
                dispatch_async(SWImageCacheManager.sharedManager().processQueue,
                               {
                                let tag:String = self._url
                                let options = self.options
                                //保存时判断是否透明，以决定保存格式;imageResize 生成的图片带alpha通道(ARGB)，因此判断是否透明需要用原图
                                var transparent:Bool = false
                                if let cgImage = loadedImage.CGImage
                                {
                                    let alphaInfo:CGImageAlphaInfo = CGImageGetAlphaInfo(cgImage)
                                    if !(alphaInfo == .None || alphaInfo == .NoneSkipFirst || alphaInfo == .NoneSkipLast)
                                    {
                                        transparent = true
                                    }
                                }
                                
                                var newImage:UIImage = Toucan.Resize.resizeImage(loadedImage, size: newSize, fitMode:.Scale)
                                if options.fitMode == .Crop
                                {
                                    let cropRect:CGRect = CGRectMake(floor((newImage.size.width - ContainerWidth) * 0.5), floor((newImage.size.height - ContainerHeight) * 0.5), ContainerWidth, ContainerHeight)
                                    newImage = Toucan.Util.croppedImageWithRect(newImage, rect: cropRect)
                                }
                                //print("loadedImage", loadedImage.scale, loadedImage.size, newImage.scale, newImage.size)
                                
                                //如果图片带圆角，而且为外切裁剪方式，则先把图片裁剪为容器大小，再进行圆角处理
                                if options.cornerRadius > 0 || options.borderWidth > 0
                                {
                                    transparent = true
                                    newImage = Toucan.Mask.maskImageWithRoundedRect(newImage, cornerRadius: options.cornerRadius, borderWidth: options.borderWidth, borderColor: options.borderColor)
                                }
                                var imageData:NSData?
                                if transparent
                                {
                                    imageData = UIImagePNGRepresentation(newImage)
                                }
                                else
                                {
                                    imageData = UIImageJPEGRepresentation(newImage, options.quality)
                                }
                                
                                //图片处理是异步进行，当处理完成时，如果当前要显示的图与当前处理完成的图是一样的，则进行显示
                                
                                if tag == self._url
                                {
                                    if let imageData = imageData
                                    {
                                        dispatch_async(SWImageCacheManager.sharedManager().ioQueue, {
                                            FileUtility.saveImageCacheToPath(self._cachePath, image:imageData)
                                        })
                                    }
                                    dispatch_async(dispatch_get_main_queue()){
                                        //print("处理后:", newImage.scale, newImage.size)
                                        //self.image = newImage
                                        self.completeHandler(newImage, readCache:readCache)
                                    }
                                }
                })
                
            }//end needResize
        }//_compressForCache
        
        return compress
    }
    
    private func completeHandler(aImage:UIImage, readCache:Bool)
    {
        let transition = options.transition
        // && transition != SWImageTransition.None
        if !readCache && transition.duration > 0
        {
            dispatch_async(dispatch_get_main_queue(), {
                //                UIView.transitionWithView(self, duration: transition.duration,
                //                    options: [transition.animationOptions, .AllowUserInteraction],
                //                    animations: {
                //                        transition.animations?(self, aImage)
                //                    },
                //                    completion: { finished in
                //                        transition.completion?(finished)
                //                        self._processing = false
                //                        self.completeCallback?(self, readCache)
                //                })
                self.image = aImage
                transition.ready?(self, aImage)
                UIView.animateWithDuration(transition.duration, delay: 0, options: [.AllowUserInteraction], animations: {
                    transition.animations?(self, aImage)
                    }, completion: { finished in
                        transition.completion?(finished)
                        self._processing = false
                        self.completeCallback?(self, readCache)
                })
                
            })
        }
        else
        {
            image = aImage
            _processing = false
            completeCallback?(self, readCache)
        }
        //图片加载完成时，如果imageView宽高为0，则呈现为图片的原始宽高
        if let image = image where frame.isEmpty
        {
            frame = CGRectMake(frame.origin.x, frame.origin.y, image.size.width, image.size.height)
        }
    }
    
    
    
    
    
    
}

class ImageLoaderOptions:NSObject
{
    private let KeyQuality:String = "quality"
    private let KeyCornerRadius:String = "cornerRadius"
    private let KeyBorderWidth:String = "borderWidth"
    private let KeyBorderColor:String = "borderColor"
    private let KeyFitMode:String = "fitMode"
    private let KeyContainerSize:String = "containerSize"
    
    
    //图片经过处理后重新保存的质量
    var quality:CGFloat = 0.9 {
        didSet {
            dictionary[KeyQuality] = quality
        }
    }
    
    //图片圆角
    var cornerRadius:CGFloat = 0 {
        didSet {
            dictionary[KeyCornerRadius] = cornerRadius
        }
    }
    
    //边框宽度
    var borderWidth:CGFloat = 0 {
        didSet {
            dictionary[KeyBorderWidth] = borderWidth
        }
    }
    
    //边框颜色
    var borderColor:UIColor = UIColor.whiteColor() {
        didSet {
            dictionary[KeyBorderColor] = borderColor
        }
    }
    
    //图片在图片容器内布局方式,默认为铺满裁剪方式
    var fitMode:ImageFitMode = .Crop {
        didSet {
            dictionary[KeyFitMode] = fitMode
        }
    }
    
    //是否将原图缓存在内存中，供其他规格使用(默认不缓存)
    var memoryCacheForOrigin:Bool = false
    //是否对原图进行缓存
    var diskCacheForOrigin:Bool = false
    
    //开始加载时清空当前图像
    var clearBefore:Bool = true
    
    var transition:SWImageTransition = SWImageTransition.None
    
    //缩放（裁剪）模式
    var contentMode:UIViewContentMode = .ScaleAspectFill {
        didSet {
            if contentMode == .ScaleAspectFill
            {
                fitMode = .Crop
            }
            else if contentMode == .ScaleAspectFit
            {
                fitMode = .Clip
            }
            else
            {
                fitMode = .Scale
            }
        }
    }
    
    //图片容器尺寸
    var containerSize:CGSize = CGSizeZero {
        didSet {
            dictionary[KeyContainerSize] = containerSize
        }
    }
    
    
    var dictionary:[String:Any] = [:]
    
    override init() {
        dictionary[KeyQuality] = quality
        dictionary[KeyCornerRadius] = cornerRadius
        dictionary[KeyBorderWidth] = borderWidth
        dictionary[KeyBorderColor] = borderColor
        dictionary[KeyFitMode] = fitMode
        dictionary[KeyContainerSize] = containerSize
    }
}

//图片在容器的
enum ImageFitMode:Int
{
    case Scale //强制拉伸到容器大小
    case Clip  //容器内按比例居中缩放
    case Crop  //铺满容器，并按比例居中缩放
}

enum SWImageTransition {
    case None
    case Fade(NSTimeInterval)
    
    case FlipFromLeft(NSTimeInterval)
    case FlipFromRight(NSTimeInterval)
    case FlipFromTop(NSTimeInterval)
    case FlipFromBottom(NSTimeInterval)
    
    case Custom(duration: NSTimeInterval,
        options: UIViewAnimationOptions,
        animations: ((UIImageView, UIImage) -> Void)?,
        completion: ((Bool) -> Void)?)
    
    var duration: NSTimeInterval {
        switch self {
        case .None:                          return 0
        case .Fade(let duration):            return duration
            
        case .FlipFromLeft(let duration):    return duration
        case .FlipFromRight(let duration):   return duration
        case .FlipFromTop(let duration):     return duration
        case .FlipFromBottom(let duration):  return duration
            
        case .Custom(let duration, _, _, _): return duration
        }
    }
    
    var animationOptions: UIViewAnimationOptions {
        switch self {
        case .None:                         return .TransitionNone
        case .Fade(_):                      return .TransitionCrossDissolve
            
        case .FlipFromLeft(_):              return .TransitionFlipFromLeft
        case .FlipFromRight(_):             return .TransitionFlipFromRight
        case .FlipFromTop(_):               return .TransitionFlipFromTop
        case .FlipFromBottom(_):            return .TransitionFlipFromBottom
            
        case .Custom(_, let options, _, _): return options
        }
    }
    
    var ready: ((UIImageView, UIImage) -> Void)? {
        switch self {
        case .Fade(_): return {imageView,image in imageView.alpha = 0}
        default: return nil
        }
    }
    
    var animations: ((UIImageView, UIImage) -> Void)? {
        switch self {
        case .Custom(_, _, let animations, _): return animations
        case .Fade(_): return {imageView,image in imageView.alpha = 1}
        default: return {$0.image = $1}
        }
    }
    
    var completion: ((Bool) -> Void)? {
        switch self {
        case .Custom(_, _, _, let completion): return completion
        default: return nil
        }
    }
}

extension Dictionary {
    func keysSortedByValue(isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sort{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

private let _cacheManager:SWImageCacheManager = SWImageCacheManager()
class SWImageCacheManager:NSObject
{
    //图片缓存所在目录
    private var cacheDirectory:String = ""
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
        let hash:String = MD5.md532BitUpper(url)
        let path:String = compress ? "\(cacheDirectory)/\(getStoreKey(url, options:options))" : fetchOriginStorePath(url)
        return path
    }
    
    //获取原图存储路径
    func fetchOriginStorePath(url:String) -> String
    {
        let hash:String = MD5.md532BitUpper(url)
        let path:String = "\(cacheDirectory)/\(hash)"
        return path
    }
    
    //根据图片的URL以及图片保存的相关参数，生成保存到本地的一个key
    func getStoreKey(URL:String, options:ImageLoaderOptions) -> String
    {
        var key:String = MD5.md532BitUpper(URL)
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
        //        let cacheFilenameHash:String = MD5.md532BitUpper(url)
        //        if let _ = NSCache().objectForKey(cacheFilenameHash) as? UIImage
        //        {
        //            return true
        //        }
        //let path = getStoreKey(url, )
        //return NSFileManager.defaultManager().fileExistsAtPath(path)
        return false
    }
    
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