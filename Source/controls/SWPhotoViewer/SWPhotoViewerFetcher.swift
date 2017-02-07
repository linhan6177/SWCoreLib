//
//  SWPhotoViewerFetcher.swift
//  UIcomnentTest2
//
//  Created by linhan on 2017/2/6.
//  Copyright © 2017年 test. All rights reserved.
//

import Foundation


protocol SWPhotoViewerFetcher:class {
    
    static func create() -> SWPhotoViewerFetcher
    
    weak var delegate:SWPhotoViewerFetcherDelegate?{get set}
    
    func fetch(photo:SWPVPhoto)
}

extension SWPhotoViewerFetcher where Self:NSObject
{
    static func create() -> SWPhotoViewerFetcher
    {
        return Self()
    }
}

protocol SWPhotoViewerFetcherDelegate:NSObjectProtocol
{
    func fetchStart()
    func fetchProgress(current:Int, total:Int)
    func fetchFailure(error:Error)
    func fetchSuccess(image:UIImage)
}

class SWPhotoViewerDefaultFetcher:NSObject, SWPhotoViewerFetcher
{
    weak var delegate:SWPhotoViewerFetcherDelegate?
    
    private let _downloader:Downloader = Downloader()
    
    override init() {
        super.init()
        
        _downloader.startCallback = {[weak self] in
            self?.delegate?.fetchStart()
        }
        _downloader.failCallback = {[weak self] error in
            self?.delegate?.fetchFailure(error: error)
        }
        _downloader.progressCallback = {[weak self] current, total in
            self?.delegate?.fetchProgress(current: current, total: total)
        }
        _downloader.completeCallback = {[weak self] data in
            self?.loadCompleteCallback(data)
        }
        
    }
    
    private func loadCompleteCallback(_ data:Data)
    {
        if let image = UIImage(data:data)
        {
            SWImageCacheManager.sharedManager().saveOriginImage(data, url: _downloader.url)
            delegate?.fetchSuccess(image: image)
        }
        else
        {
            delegate?.fetchFailure(error: NSError(domain: "sw", code: 404, userInfo: nil))
        }
    }
    
    func fetch(photo:SWPVPhoto)
    {
        if let url = photo.largeImageURL
        {
            _downloader.load(url)
        }
    }
}

