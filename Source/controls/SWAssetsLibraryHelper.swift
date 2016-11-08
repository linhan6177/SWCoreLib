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

//相册
protocol SWALAlbumDelegate:NSObjectProtocol {
    
    func albumCoverChanged(_ album:SWALAlbum, cover:UIImage)
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
    
    func photoThumbChanged(_ photo:SWALPhoto, thumb:UIImage)
}

class SWALPhoto:NSObject
{
    typealias ImageCompleteCallback = (UIImage?)->Void
    var selected:Bool = false
    var image:UIImage?
    
    weak var delegate:SWALPhotoDelegate?
    
    private let PhotoCoverSize:CGSize = CGSize(width: 70, height: 70)
    private var _PHAsset:AnyObject?
    @available(iOS 8.0, *)
    var phAsset:PHAsset? {
        return _PHAsset as? PHAsset
    }
    
    var asset:ALAsset?
    
    var id:String
    var index:Int = 0
    var originImage:UIImage?
    
    func fetchOriginImage(_ completeCallback:@escaping ImageCompleteCallback)
    {
        (iOS8Available && SWALUsePHKit) ? fetchOriginImageWithPHKit(completeCallback) : fetchOriginImageWithALKit(completeCallback)
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
        self.id = id
        self.asset = asset
    }
    
    @available(iOS 8.0, *)
    init(id:String, PHAsset asset:PHAsset)
    {
        self.id = id
        self._PHAsset = asset
    }
    
    init(thumbnail:UIImage?) {
        id = ""
        self.thumbnail = thumbnail
        super.init()
    }
    
    //缩略图
    var thumbnail:UIImage?
    //获取缩略图是异步的，需要回调
    func fetchThumbnail(_ size:CGSize? = nil)
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
                    let scale = UIScreen.main.scale
                    PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: ThumbnailSize.width * scale, height: ThumbnailSize.height * scale), contentMode: .aspectFit, options: nil, resultHandler: {image, info in
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
                let image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
                self.thumbnail = image
                self.delegate?.photoThumbChanged(self, thumb: image)
            }
        }
        
        (iOS8Available && SWALUsePHKit) ? fetchThumbnailWithPHKit() : fetchThumbnailWithALKit()
    }
    
    //获取原图
    private func fetchOriginImageWithPHKit(_ completeCallback:@escaping ImageCompleteCallback)
    {
        if #available(iOS 8.0, *)
        {
            guard let asset = self.phAsset else{
                completeCallback(nil)
                return
            }
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
            imageRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
            imageRequestOptions.isSynchronous = false
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil, resultHandler: {image, info in
                self.originImage = image
                completeCallback(image)
            })
        }
    }
    
    private func fetchOriginImageWithALKit(_ completeCallback:ImageCompleteCallback)
    {
        if let representation = asset?.defaultRepresentation(),
            let cgImage = representation.fullResolutionImage()?.takeUnretainedValue()
        {
            let scale:CGFloat = CGFloat(representation.scale())
            let imageOrientation:UIImageOrientation = UIImageOrientation(rawValue: representation.orientation().rawValue) ?? .up
            let image = UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
            originImage = image
            completeCallback(image)
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
    @objc optional func requestAuthorizationDenied()
    
    //授权通过
    @objc optional func requestAuthorizationAuthorized()
    
    //相册获取完成
    @objc optional func albumFetchComplete(_ album:[SWALAlbum], defaultAlbum:SWALAlbum?)
    
    //相册空
    @objc optional func albumFetchEmpty()
    
    //相片获取完成
    @objc optional func photosFetchComplete(_ photos:[SWALPhoto])
}

enum SWALAuthorizationStatus : Int {
    case notDetermined
    case restricted
    case denied
    case authorized
}

private var _manager:SWAssetsLibraryHelper?
class SWAssetsLibraryHelper: NSObject
{
    private var _iOS8Available:Bool = false
    
    private var _library:ALAssetsLibrary = ALAssetsLibrary()
    //private var _groups:[SWALAlbum] = []
    //private var _photos:[SWALPhoto] = []
    //相册封面尺寸
    private let AlbumCoverSize:CGSize = CGSize(width: 70, height: 70)
    
    
    class func shared() -> SWAssetsLibraryHelper
    {
        _manager = _manager ?? SWAssetsLibraryHelper()
        return _manager!
    }
    
    private var _delegates = WeakObjectSet<SWAssetsLibraryHelperDelegate>()
    
    //授权状态
    var authorizationStatus:SWALAuthorizationStatus{
        var status = SWALAuthorizationStatus.notDetermined
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
    
    func addDelegate(_ delegate:SWAssetsLibraryHelperDelegate)
    {
        _delegates.addObject(delegate)
    }
    
    func removeDelegate(_ delegate:SWAssetsLibraryHelperDelegate)
    {
        _delegates.removeObject(delegate)
    }
    
    func fetchAlbum()
    {
        let fetchAlbumWithPHKit = {
            if #available(iOS 8.0, *)
            {
                let status = PHPhotoLibrary.authorizationStatus()
                if status == .authorized {
                    self.fetchCollections()
                }
                else if status == .notDetermined{
                    PHPhotoLibrary.requestAuthorization({status in
                        if status == .authorized {
                            self.fetchCollections()
                            self.notifyRequestAuthorizationAuthorized()
                        }
                        else {
                            self.notifyRequestAuthorizationDenied()
                        }
                    })
                }
                else{
                    self.notifyRequestAuthorizationDenied()
                }
            }
        }
        
        let fetchAlbumWithALKit = {
            //ALAssetsLibrary没有授权请求接口，只有在具体访问资源时才会返回无权限错误
            let status = ALAssetsLibrary.authorizationStatus()
            if status == .authorized || status == .notDetermined {
                self.getGroupsList()
            }
            else {
                self.notifyRequestAuthorizationDenied()
            }
        }
        
        _iOS8Available && SWALUsePHKit ? fetchAlbumWithPHKit() : fetchAlbumWithALKit()
    }
    
    func fetchPhotoList(_ album:SWALAlbum)
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
    func fetchOriginImage(_ photos:[SWALPhoto], completeCallback:@escaping ([UIImage])->Void)
    {
        var count:Int = 0
        for photo in photos
        {
            photo.fetchOriginImage{image in
                count += 1
                if count == photos.count
                {
                    let images:[UIImage] = photos.flatMap({$0.originImage})
                    completeCallback(images)
                }
            }//end callback
        }//end for
    }
    
    @available(iOS 8.0, *)
    private func fetchCollections()
    {
        var groups:[SWALAlbum] = []
        // 列出所有相册智能相册
        var collections:[PHAssetCollection] = []
        
        // 列出所有用户创建的相册
        let UserCollectionsResult = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        UserCollectionsResult.enumerateObjects{collection, index, stop in
            if let collection = collection as? PHAssetCollection {
                collections.append(collection)
            }
        }
        
        // 列出所有相册智能相册
        let IgnoreSmartSubtype:[PHAssetCollectionSubtype] = [.smartAlbumSlomoVideos]
        let SmartCollectionsResult = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.any, options: nil)
        SmartCollectionsResult.enumerateObjects{collection, index, stop in
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
            let result = PHAsset.fetchAssets(in: collection, options: options)
            if result.count > 0
            {
                let album:SWALAlbum = SWALAlbum(collection: collection)
                album.name = collection.localizedTitle ?? "相册"
                album.numberOfAssets = result.count
                groups.append(album)
                
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary
                {
                    cameraRollAlbum = album
                }
                
                if let asset = result.lastObject as? PHAsset
                {
                    let scale = UIScreen.main.scale
                    let size = CGSize(width: AlbumCoverSize.width * scale, height: AlbumCoverSize.height * scale)
                    PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil, resultHandler: {image, info in
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
                if let name = group.value(forProperty: ALAssetsGroupPropertyName) as? String , group.numberOfAssets() > 0
                {
                    group.setAssetsFilter(ALAssetsFilter.allPhotos())
                    
                    let album:SWALAlbum = SWALAlbum(group: group)
                    album.name = name
                    album.numberOfAssets = group.numberOfAssets()
                    if let cgImage = group.posterImage()?.takeUnretainedValue()
                    {
                        album.thumbImage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
                    }
                    
                    groups.append(album)
                    if let value = group.value(forProperty: ALAssetsGroupPropertyType) , (value as AnyObject).intValue == Int(ALAssetsGroupSavedPhotos)
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
    private func getPhotoList(group:ALAssetsGroup)
    {
        //_photos.removeAll()
        var photos:[SWALPhoto] = []
        group.enumerateAssets(options: NSEnumerationOptions.reverse, using: {asset,index,stop in
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
    private func getPhotoList(collection:PHAssetCollection)
    {
        //_photos.removeAll()
        var photos:[SWALPhoto] = []
        //按照时间排序获取第一张图作为封面
        let options:PHFetchOptions = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", 1)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate" , ascending: true)]
        let result = PHAsset.fetchAssets(in: collection, options: options)
        let assets:[PHAsset] = result.objects(at: IndexSet(integersIn: NSMakeRange(0, result.count).toRange()!)).flatMap({$0 as? PHAsset})
        for (index, asset) in assets.enumerated()
        {
            let photo:SWALPhoto = SWALPhoto(id:asset.localIdentifier, PHAsset: asset)
            photo.index = index
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
    private func notifyAlbumFetchComplete(_ album:[SWALAlbum], defaultAlbum:SWALAlbum?)
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
    private func notifyPhotosFetchComplete(_ photos:[SWALPhoto])
    {
        for wrapper in _delegates.objects
        {
            wrapper.object?.photosFetchComplete?(photos)
        }
    }
    
    
    
}//end class
