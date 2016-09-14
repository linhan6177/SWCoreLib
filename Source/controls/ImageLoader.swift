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
    
    
    fileprivate let errorDomain:String = "com.sw.ImageLoader"
    
    
    fileprivate var _downloader:Downloader = Downloader()
    
    fileprivate var _cachePath:String = ""
    fileprivate var _url:String = ""
    fileprivate var _compressForCache:Bool = true
    
    //Memory
    
    //当前是否处于网络加载中
    fileprivate var _loading:Bool = false
    //图片是否正在处理中（从本地加载、圆角、裁剪等处理）
    fileprivate var _processing = false
    
    init()
    {
        super.init(frame: CGRect.zero)
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
        NotificationCenter.default.removeObserver(self)
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
    func load(_ url:String, compressForCache:Bool = true)
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
        if let memoryCacheImage = SWImageCacheManager.sharedManager().memoryCache.object(forKey: url) as? UIImage
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
        SWImageCacheManager.sharedManager().ioQueue.async(execute: {
                        let cachedURL = url
                        let orginPath = SWImageCacheManager.sharedManager().fetchOriginStorePath(url)
                        //先读取相关尺寸图片的缓存
                        if let cacheImage:UIImage = FileUtility.imageDataFromPath(self._cachePath)
                        {
                            if self._url == cachedURL
                            {
                                DispatchQueue.main.async {
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
                                    DispatchQueue.main.async {
                                        self.completeHandler(originImage, readCache:true)
                                    }
                                }
                            }
                        }
                            //什么都没有则网络加载
                        else
                        {
                            DispatchQueue.main.async {
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
    func load(_ url:String, placeholderImage:UIImage?, compressForCache:Bool = true)
    {
        self.placeholderImage = placeholderImage
        load(url, compressForCache:compressForCache)
    }
    
    //异步方式加载本地图片
    func load(contentsOfFile file:String)
    {
        _processing = true
        SWImageCacheManager.sharedManager().ioQueue.async(execute: {
                        if let data = try? Data(contentsOf: URL(fileURLWithPath: file)),
                            let image = UIImage(data: data, scale: UIScreen.main.scale)
                        {
                            DispatchQueue.main.async(execute: {
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
    
    fileprivate func setup()
    {
        _downloader.cachePolicy = .returnCacheDataElseLoad
        _downloader.timeoutInterval = 10
        _downloader.startCallback = {[weak self] in self?.startCallback?()}
        _downloader.failCallback = {[weak self] error in
            self?.loadFailCallback(error)
        }
        _downloader.progressCallback = {[weak self] current, total in
            self?.loadProgressCallback(current, totalBytes: total)
        }
        _downloader.completeCallback = {[weak self] data in
            self?.loadCompleteCallback(data as Data)
        }
    }
    
    fileprivate func loadFailCallback(_ error:NSError)
    {
        _loading = false
        failCallback?(error)
    }
    
    fileprivate func loadProgressCallback(_ loadedBytes:Int, totalBytes:Int)
    {
        progressCallback?(loadedBytes, totalBytes)
    }
    
    fileprivate func loadCompleteCallback(_ data:Data)
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
            if let cgImage = loadedImage.cgImage , !compress
            {
                let image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: loadedImage.imageOrientation)
                let path:String = _cachePath
                SWImageCacheManager.sharedManager().ioQueue.async {
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
    fileprivate func imageProcessHandler(_ loadedImage:UIImage, readCache:Bool = false) -> Bool
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
            if options.fitMode == .crop
            {
                scale = ViewUtil.getAdaptiveScale(loadedImage.size.width, targetH: loadedImage.size.height, containerW: ContainerWidth, containerH: ContainerHeight, inscribed: false)
                newSize = CGSize(width: loadedImage.size.width * scale, height: loadedImage.size.height * scale)
                needResize = true
            }
            else if options.fitMode == .clip
            {
                scale = ViewUtil.getAdaptiveScale(loadedImage.size.width, targetH: loadedImage.size.height, containerW: ContainerWidth, containerH: ContainerHeight, inscribed: true)
                newSize = CGSize(width: loadedImage.size.width * scale, height: loadedImage.size.height * scale)
                needResize = true
            }
            else
            {
                needResize = true
            }
            
            if needResize
            {
                compress = true
                
                SWImageCacheManager.sharedManager().processQueue.async(execute: {
                                let tag:String = self._url
                                let options = self.options
                                //保存时判断是否透明，以决定保存格式;imageResize 生成的图片带alpha通道(ARGB)，因此判断是否透明需要用原图
                                var transparent:Bool = false
                                if let cgImage = loadedImage.cgImage
                                {
                                    let alphaInfo:CGImageAlphaInfo = cgImage.alphaInfo
                                    if !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
                                    {
                                        transparent = true
                                    }
                                }
                                
                                var newImage:UIImage = Toucan.Resize.resizeImage(loadedImage, size: newSize, fitMode:.scale)
                                if options.fitMode == .crop
                                {
                                    let cropRect:CGRect = CGRect(x: floor((newImage.size.width - ContainerWidth) * 0.5), y: floor((newImage.size.height - ContainerHeight) * 0.5), width: ContainerWidth, height: ContainerHeight)
                                    newImage = Toucan.Util.croppedImageWithRect(newImage, rect: cropRect)
                                }
                                //print("loadedImage", loadedImage.scale, loadedImage.size, newImage.scale, newImage.size)
                                
                                //如果图片带圆角，而且为外切裁剪方式，则先把图片裁剪为容器大小，再进行圆角处理
                                if options.cornerRadius > 0 || options.borderWidth > 0
                                {
                                    transparent = true
                                    newImage = Toucan.Mask.maskImageWithRoundedRect(newImage, cornerRadius: options.cornerRadius, borderWidth: options.borderWidth, borderColor: options.borderColor)
                                }
                                var imageData:Data?
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
                                        SWImageCacheManager.sharedManager().ioQueue.async(execute: {
                                            FileUtility.saveImageCacheToPath(self._cachePath, image:imageData)
                                        })
                                    }
                                    DispatchQueue.main.async{
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
    
    fileprivate func completeHandler(_ aImage:UIImage, readCache:Bool)
    {
        let transition = options.transition
        // && transition != SWImageTransition.None
        if !readCache && transition.duration > 0
        {
            DispatchQueue.main.async(execute: {
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
                UIView.animate(withDuration: transition.duration, delay: 0, options: [.allowUserInteraction], animations: {
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
        if let image = image , frame.isEmpty
        {
            frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: image.size.width, height: image.size.height)
        }
    }
    
    
    
    
    
    
}

class ImageLoaderOptions:NSObject
{
    fileprivate let KeyQuality:String = "quality"
    fileprivate let KeyCornerRadius:String = "cornerRadius"
    fileprivate let KeyBorderWidth:String = "borderWidth"
    fileprivate let KeyBorderColor:String = "borderColor"
    fileprivate let KeyFitMode:String = "fitMode"
    fileprivate let KeyContainerSize:String = "containerSize"
    
    
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
    var borderColor:UIColor = UIColor.white {
        didSet {
            dictionary[KeyBorderColor] = borderColor
        }
    }
    
    //图片在图片容器内布局方式,默认为铺满裁剪方式
    var fitMode:ImageFitMode = .crop {
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
    
    var transition:SWImageTransition = SWImageTransition.none
    
    //缩放（裁剪）模式
    var contentMode:UIViewContentMode = .scaleAspectFill {
        didSet {
            if contentMode == .scaleAspectFill
            {
                fitMode = .crop
            }
            else if contentMode == .scaleAspectFit
            {
                fitMode = .clip
            }
            else
            {
                fitMode = .scale
            }
        }
    }
    
    //图片容器尺寸
    var containerSize:CGSize = CGSize.zero {
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
    case scale //强制拉伸到容器大小
    case clip  //容器内按比例居中缩放
    case crop  //铺满容器，并按比例居中缩放
}

enum SWImageTransition {
    case none
    case fade(TimeInterval)
    
    case flipFromLeft(TimeInterval)
    case flipFromRight(TimeInterval)
    case flipFromTop(TimeInterval)
    case flipFromBottom(TimeInterval)
    
    case custom(duration: TimeInterval,
        options: UIViewAnimationOptions,
        animations: ((UIImageView, UIImage) -> Void)?,
        completion: ((Bool) -> Void)?)
    
    var duration: TimeInterval {
        switch self {
        case .none:                          return 0
        case .fade(let duration):            return duration
            
        case .flipFromLeft(let duration):    return duration
        case .flipFromRight(let duration):   return duration
        case .flipFromTop(let duration):     return duration
        case .flipFromBottom(let duration):  return duration
            
        case .custom(let duration, _, _, _): return duration
        }
    }
    
    var animationOptions: UIViewAnimationOptions {
        switch self {
        case .none:                         return UIViewAnimationOptions()
        case .fade(_):                      return .transitionCrossDissolve
            
        case .flipFromLeft(_):              return .transitionFlipFromLeft
        case .flipFromRight(_):             return .transitionFlipFromRight
        case .flipFromTop(_):               return .transitionFlipFromTop
        case .flipFromBottom(_):            return .transitionFlipFromBottom
            
        case .custom(_, let options, _, _): return options
        }
    }
    
    var ready: ((UIImageView, UIImage) -> Void)? {
        switch self {
        case .fade(_): return {imageView,image in imageView.alpha = 0}
        default: return nil
        }
    }
    
    var animations: ((UIImageView, UIImage) -> Void)? {
        switch self {
        case .custom(_, _, let animations, _): return animations
        case .fade(_): return {imageView,image in imageView.alpha = 1}
        default: return {$0.image = $1}
        }
    }
    
    var completion: ((Bool) -> Void)? {
        switch self {
        case .custom(_, _, _, let completion): return completion
        default: return nil
        }
    }
}

extension Dictionary {
    func keysSortedByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sorted{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

