//
//  SWAssetsLibraryHelper.swift
//  uicomponetTest3
//
//  Created by linhan on 16/8/31.
//  Copyright © 2016年 linhan. All rights reserved.
//

import Foundation
import AssetsLibrary
import Photos

#if SWALUsePHKit
let SWALUsePHKit:Bool = true
#else
let SWALUsePHKit:Bool = true
#endif

//照片获取选项
struct SWALPhotoRequestOptions
{
    var requestImageData:Bool = false
}

//照片获取结果
struct SWALPhotoRequestResult
{
    var image:UIImage?
    var data:NSData?
    var creationDate:NSDate?
}

//相册
protocol SWALAlbumDelegate:NSObjectProtocol
{
    //相册封面的获取基于异步，所以获取完需要通知
    func albumCoverChanged(album:SWALAlbum, cover:UIImage)
}

class SWALAlbum:NSObject
{
    var name:String = ""
    
    weak var delegate:SWALAlbumDelegate?
    
    var thumbImage:UIImage? {
        didSet {
            if let thumbImage = thumbImage{
                delegate?.albumCoverChanged(self, cover: thumbImage)
            }
        }
    }
    
    var numberOfAssets:Int = 0
    var group:ALAssetsGroup?
    var id:String = ""
    
    private var _collection:AnyObject?
    @available(iOS 8.0, *)
    var collection:PHAssetCollection? {
        return _collection as? PHAssetCollection
    }
    
    @available(iOS 8.0, *)
    init(collection:PHAssetCollection)
    {
        _collection = collection
        name = collection.localizedTitle ?? ""
    }
    
    init(group:ALAssetsGroup)
    {
        self.group = group
    }
}


//图片
protocol SWALPhotoDelegate:NSObjectProtocol {
    
    func photoThumbChanged(photo:SWALPhoto, thumb:UIImage)
}

class SWALPhoto:NSObject
{
    typealias ImageCompleteCallback = (SWALPhotoRequestResult?)->Void
    var selected:Bool = false
    var image:UIImage?
    
    weak var delegate:SWALPhotoDelegate?
    
    private let PhotoCoverSize:CGSize = CGSizeMake(70, 70)
    private var _PHAsset:AnyObject?
    @available(iOS 8.0, *)
    var phAsset:PHAsset? {
        return _PHAsset as? PHAsset
    }
    
    var asset:ALAsset?
    
    var id:String
    var index:Int = 0
    var originImage:UIImage?
    var creationDate:NSDate?
    
    func fetchOriginImage(completeCallback:ImageCompleteCallback, options:SWALPhotoRequestOptions? = nil)
    {
        (iOS8Available && SWALUsePHKit) ? fetchOriginImageWithPHKit(completeCallback, options:options) : fetchOriginImageWithALKit(completeCallback)
    }
    
    var iOS8Available:Bool{
        if #available(iOS 8.0, *)
        {
            return true
        }
        return false
    }
    
    init(id:String, ALAsset asset:ALAsset)
    {
        self.id = SWMD5.md532BitUpper(id)
        self.asset = asset
    }
    
    @available(iOS 8.0, *)
    init(id:String, PHAsset asset:PHAsset)
    {
        self.id = SWMD5.md532BitUpper(id)
        self._PHAsset = asset
    }
    
    init(thumbnail:UIImage?) {
        id = ""
        self.thumbnail = thumbnail
        super.init()
    }
    
    var size:CGSize
    {
        if #available(iOS 8.0, *)
        {
            if let asset = _PHAsset
            {
                return CGSizeMake(CGFloat(asset.pixelWidth), CGFloat(asset.pixelHeight))
            }
        }
        return CGSizeZero
    }
    
    //缩略图
    var thumbnail:UIImage?
    
    //获取缩略图是异步的，需要回调
    func fetchThumbnail(size:CGSize? = nil)
    {
        if let thumbnail = thumbnail
        {
            delegate?.photoThumbChanged(self, thumb: thumbnail)
            return
        }
        
        let fetchThumbnailWithPHKit = {
            if #available(iOS 8.0, *)
            {
                if let asset = self.phAsset
                {
                    let ThumbnailSize = size ?? self.PhotoCoverSize
                    let scale = UIScreen.mainScreen().scale
                    PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSizeMake(ThumbnailSize.width * scale, ThumbnailSize.height * scale), contentMode: .AspectFit, options: nil, resultHandler: {image, info in
                        if let image = image
                        {
                            self.thumbnail = image
                            self.delegate?.photoThumbChanged(self, thumb: image)
                        }
                    })
                }
            }
        }
        
        let fetchThumbnailWithALKit = {
            if let cgImage = self.asset?.thumbnail()?.takeUnretainedValue()
            {
                let image = UIImage(CGImage: cgImage, scale: UIScreen.mainScreen().scale, orientation: .Up)
                self.thumbnail = image
                self.delegate?.photoThumbChanged(self, thumb: image)
            }
        }
        
        (iOS8Available && SWALUsePHKit) ? fetchThumbnailWithPHKit() : fetchThumbnailWithALKit()
    }
    
    //获取原图
    private func fetchOriginImageWithPHKit(completeCallback:ImageCompleteCallback, options:SWALPhotoRequestOptions? = nil)
    {
        if #available(iOS 8.0, *)
        {
            guard let asset = self.phAsset else{
                completeCallback(nil)
                return
            }
            let requestImageData:Bool = options?.requestImageData ?? false
            var dataReturned:Bool = false
            var imageReturned:Bool = false
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.FastFormat
            imageRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.Exact
            imageRequestOptions.synchronous = false
            
            var result:SWALPhotoRequestResult = SWALPhotoRequestResult()
            result.creationDate = creationDate
            
            PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: PHImageManagerMaximumSize, contentMode: .AspectFit, options: nil, resultHandler: {image, info in
                imageReturned = true
                self.originImage = image
                result.image = image
                if !requestImageData || (requestImageData && dataReturned)
                {
                    completeCallback(result)
                }
            })
            
            if requestImageData
            {
                PHImageManager.defaultManager().requestImageDataForAsset(asset, options: imageRequestOptions, resultHandler: {imageData, url, ori, info in
                    dataReturned = true
                    result.data = imageData
                    
                    if imageReturned
                    {
                        completeCallback(result)
                    }
                })
            }
            
        }
    }
    
    private func fetchOriginImageWithALKit(completeCallback:ImageCompleteCallback)
    {
        if let representation = asset?.defaultRepresentation(),
            let cgImage = representation.fullResolutionImage()?.takeUnretainedValue()
        {
            let scale:CGFloat = CGFloat(representation.scale())
            let imageOrientation:UIImageOrientation = UIImageOrientation(rawValue: representation.orientation().rawValue) ?? .Up
            let image = UIImage(CGImage: cgImage, scale: scale, orientation: imageOrientation)
            originImage = image
            var result:SWALPhotoRequestResult = SWALPhotoRequestResult()
            result.image = image
            completeCallback(result)
        }
        else
        {
            completeCallback(nil)
        }
    }
    
}

@objc protocol SWAssetsLibraryHelperDelegate:NSObjectProtocol
{
    //授权被拒绝
    optional func requestAuthorizationDenied()
    
    //授权通过
    optional func requestAuthorizationAuthorized()
    
    //相册获取完成
    optional func albumFetchComplete(album:[SWALAlbum], defaultAlbum:SWALAlbum?)
    
    //相册空
    optional func albumFetchEmpty()
    
    //相片获取完成
    optional func photosFetchComplete(photos:[SWALPhoto])
}

enum SWALAuthorizationStatus : Int {
    case NotDetermined
    case Restricted
    case Denied
    case Authorized
}

private var _manager:SWAssetsLibraryHelper?
class SWAssetsLibraryHelper: NSObject
{
    private var _iOS8Available:Bool = false
    
    private var _library:ALAssetsLibrary = ALAssetsLibrary()
    
    //相册封面尺寸
    private let AlbumCoverSize:CGSize = CGSizeMake(70, 70)
    
    
    class func shared() -> SWAssetsLibraryHelper
    {
        _manager = _manager ?? SWAssetsLibraryHelper()
        return _manager!
    }
    
    private var _delegates = WeakObjectSet<SWAssetsLibraryHelperDelegate>()
    
    //授权状态
    var authorizationStatus:SWALAuthorizationStatus{
        var status = SWALAuthorizationStatus.NotDetermined
        if #available(iOS 8.0, *)
        {
            status = SWALAuthorizationStatus(rawValue: PHPhotoLibrary.authorizationStatus().rawValue) ?? status
        }
        else
        {
            status = SWALAuthorizationStatus(rawValue: ALAssetsLibrary.authorizationStatus().rawValue) ?? status
        }
        return status
    }
    
    override init() {
        super.init()
        if #available(iOS 8.0, *)  {
            _iOS8Available = true
        }
    }
    
    func addDelegate(delegate:SWAssetsLibraryHelperDelegate)
    {
        _delegates.addObject(delegate)
    }
    
    func removeDelegate(delegate:SWAssetsLibraryHelperDelegate)
    {
        _delegates.removeObject(delegate)
    }
    
    func fetchAlbum()
    {
        let fetchAlbumWithPHKit = {
            if #available(iOS 8.0, *)
            {
                let status = PHPhotoLibrary.authorizationStatus()
                if status == .Authorized {
                    self.fetchCollections()
                }
                else if status == .NotDetermined{
                    PHPhotoLibrary.requestAuthorization({status in
                        dispatch_async(dispatch_get_main_queue(), {
                            if status == .Authorized {
                                self.fetchCollections()
                                self.notifyRequestAuthorizationAuthorized()
                            }
                            else {
                                self.notifyRequestAuthorizationDenied()
                            }
                        })
                    })//end requestAuthorization
                }
                else{
                    self.notifyRequestAuthorizationDenied()
                }
            }
        }
        
        let fetchAlbumWithALKit = {
            //ALAssetsLibrary没有授权请求接口，只有在具体访问资源时才会返回无权限错误
            let status = ALAssetsLibrary.authorizationStatus()
            if status == .Authorized || status == .NotDetermined {
                self.getGroupsList()
            }
            else {
                self.notifyRequestAuthorizationDenied()
            }
        }
        
        _iOS8Available && SWALUsePHKit ? fetchAlbumWithPHKit() : fetchAlbumWithALKit()
    }
    
    func fetchPhotoList(album:SWALAlbum)
    {
        if _iOS8Available && SWALUsePHKit
        {
            if #available(iOS 8.0, *)
            {
                if let collection = album.collection
                {
                    getPhotoList(collection: collection)
                }
            }
        }
        else
        {
            if let group = album.group
            {
                getPhotoList(group: group)
            }
        }
    }
    
    //获取照片原图
    func fetchOriginImage(photos:[SWALPhoto], completeCallback:([SWALPhotoRequestResult])->Void, options:SWALPhotoRequestOptions? = nil)
    {
        var count:Int = 0
        var images:[SWALPhotoRequestResult] = []
        for photo in photos
        {
            photo.fetchOriginImage({result in
                if let result = result
                {
                    images.append(result)
                }
                
                count += 1
                if count == photos.count
                {
                    //let images:[UIImage] = photos.flatMap({$0.originImage})
                    completeCallback(images)
                }
                
            }, options:options)//end callback
        }//end for
    }
    
    @available(iOS 8.0, *)
    private func fetchCollections()
    {
        var groups:[SWALAlbum] = []
        // 列出所有相册智能相册
        var collections:[PHAssetCollection] = []
        
        // 列出所有用户创建的相册
        let UserCollectionsResult = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
        UserCollectionsResult.enumerateObjectsUsingBlock{collection, index, stop in
            if let collection = collection as? PHAssetCollection {
                collections.append(collection)
            }
        }
        
        // 列出所有相册智能相册
        //let IgnoreSmartSubtype:[PHAssetCollectionSubtype] = [.SmartAlbumSlomoVideos]
        let SmartCollectionsResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.SmartAlbum, subtype: PHAssetCollectionSubtype.Any, options: nil)
        SmartCollectionsResult.enumerateObjectsUsingBlock{collection, index, stop in
            if let collection = collection as? PHAssetCollection {
                collections.append(collection)
            }
        }
        
        var cameraRollAlbum:SWALAlbum?
        for collection in collections
        {
            //按照时间排序获取第一张图作为封面
            let options:PHFetchOptions = PHFetchOptions()
            options.predicate = NSPredicate(format: "mediaType = %d", 1)
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate" , ascending: true)]
            let result = PHAsset.fetchAssetsInAssetCollection(collection, options: options)
            if result.count > 0
            {
                let album:SWALAlbum = SWALAlbum(collection: collection)
                album.name = collection.localizedTitle ?? "相册"
                album.numberOfAssets = result.count
                groups.append(album)
                
                if collection.assetCollectionSubtype == .SmartAlbumUserLibrary
                {
                    cameraRollAlbum = album
                }
                
                if let asset = result.lastObject as? PHAsset
                {
                    let scale = UIScreen.mainScreen().scale
                    let size = CGSizeMake(AlbumCoverSize.width * scale, AlbumCoverSize.height * scale)
                    PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: size, contentMode: .AspectFill, options: nil, resultHandler: {image, info in
                        if let image = image
                        {
                            album.thumbImage = image
                        }
                    })
                }
            }
        }
        
        notifyAlbumFetchComplete(groups, defaultAlbum: cameraRollAlbum)
    }
    
    //获取相册列表
    private func getGroupsList()
    {
        var groups:[SWALAlbum] = []
        var cameraRollAlbum:SWALAlbum?
        _library.enumerateGroupsWithTypes(ALAssetsGroupAll, usingBlock: { group, stop in
            if let group = group
            {
                if let name = group.valueForProperty(ALAssetsGroupPropertyName) as? String where group.numberOfAssets() > 0
                {
                    group.setAssetsFilter(ALAssetsFilter.allPhotos())
                    
                    let album:SWALAlbum = SWALAlbum(group: group)
                    album.name = name
                    album.numberOfAssets = group.numberOfAssets()
                    if let cgImage = group.posterImage()?.takeUnretainedValue()
                    {
                        album.thumbImage = UIImage(CGImage: cgImage, scale: UIScreen.mainScreen().scale, orientation: .Up)
                    }
                    
                    groups.append(album)
                    if let value = group.valueForProperty(ALAssetsGroupPropertyType) where value.integerValue == Int(ALAssetsGroupSavedPhotos)
                    {
                        cameraRollAlbum = album
                    }
                }
            }
            else
            {
                if groups.count > 0
                {
                    //默认进入的胶卷相册
                    let defaultAlbum = cameraRollAlbum ?? groups.valueAt(0)
                    self.notifyAlbumFetchComplete(groups, defaultAlbum: defaultAlbum)
                }
                else
                {
                    self.notifyAlbumFetchEmpty()
                }
            }
            
            }, failureBlock: {error in
                if error.code == ALAssetsLibraryAccessUserDeniedError || error.code == ALAssetsLibraryAccessGloballyDeniedError
                {
                    self.notifyRequestAuthorizationDenied()
                }
        })
    }
    
    //获取照片列表
    private func getPhotoList(group group:ALAssetsGroup)
    {
        //_photos.removeAll()
        var photos:[SWALPhoto] = []
        group.enumerateAssetsWithOptions(NSEnumerationOptions.Reverse, usingBlock: {asset,index,stop in
            if let asset = asset
            {
                if let representation = asset.defaultRepresentation()
                {
                    let id:String = representation.url()?.relativeString ?? ""
                    let photo:SWALPhoto = SWALPhoto(id:id, ALAsset: asset)
                    photo.index = index
                    photos.append(photo)
                }
            }
            else
            {
                if photos.count > 0
                {
                    self.notifyPhotosFetchComplete(photos)
                }
                else
                {
                    self.notifyAlbumFetchEmpty()
                }
            }
        })
        
    }
    
    @available(iOS 8.0, *)
    private func getPhotoList(collection collection:PHAssetCollection)
    {
        //_photos.removeAll()
        var photos:[SWALPhoto] = []
        //按照时间排序获取第一张图作为封面
        let options:PHFetchOptions = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", 1)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate" , ascending: false)]
        let result = PHAsset.fetchAssetsInAssetCollection(collection, options: options)
        let assets:[PHAsset] = result.objectsAtIndexes(NSIndexSet(indexesInRange: NSMakeRange(0, result.count))).flatMap({$0 as? PHAsset})
        for (index, asset) in assets.enumerate()
        {
            let photo:SWALPhoto = SWALPhoto(id:asset.localIdentifier, PHAsset: asset)
            photo.index = index
            photo.creationDate = asset.creationDate
            photos.append(photo)
        }
        
        if photos.count > 0
        {
            self.notifyPhotosFetchComplete(photos)
        }
        else
        {
            self.notifyAlbumFetchEmpty()
        }
    }
    
    //授权被拒绝
    private func notifyRequestAuthorizationDenied()
    {
        for wrapper in _delegates.objects
        {
            wrapper.object?.requestAuthorizationDenied?()
        }
    }
    
    //授权通过
    private func notifyRequestAuthorizationAuthorized()
    {
        for wrapper in _delegates.objects
        {
            wrapper.object?.requestAuthorizationAuthorized?()
        }
    }
    
    //相册获取完成
    private func notifyAlbumFetchComplete(album:[SWALAlbum], defaultAlbum:SWALAlbum?)
    {
        for wrapper in _delegates.objects
        {
            wrapper.object?.albumFetchComplete?(album, defaultAlbum:defaultAlbum)
        }
    }
    
    //相册空
    private func notifyAlbumFetchEmpty()
    {
        for wrapper in _delegates.objects
        {
            wrapper.object?.albumFetchEmpty?()
        }
    }
    
    //相片获取完成
    private func notifyPhotosFetchComplete(photos:[SWALPhoto])
    {
        for wrapper in _delegates.objects
        {
            wrapper.object?.photosFetchComplete?(photos)
        }
    }
    
    
    
}//end class
