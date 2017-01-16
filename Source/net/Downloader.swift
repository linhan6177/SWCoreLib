



//
//  Downloader.swift
//  JokeSiJie
//
//  Created by linhan on 14-11-27.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
import UIKit
class Downloader: NSObject,NSURLConnectionDataDelegate
{
    //NSURLConnectionDownloadDelegate
    private var _request:NSMutableURLRequest = NSMutableURLRequest()
    
    private var _connection:NSURLConnection?
    
    private var _contentLength:Int = 0
    private var _responseData:NSMutableData = NSMutableData()
    
    var url:String = ""
    var startCallback:(() -> Void)?
    var failCallback:((NSError) -> Void)?
    var progressCallback:((Int,Int) -> Void)?
    var completeCallback:((Data) -> Void)?
    
    var timeoutInterval:Double
    {
        get
        {
            return _request.timeoutInterval
        }
        set
        {
            _request.timeoutInterval = newValue
        }
    }
    
    override init()
    {
        super.init()
        _request.timeoutInterval = 30
        _request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        _request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:40.0) Gecko/20100101 Firefox/40.0", forHTTPHeaderField: "User-Agent")
    }
    
    deinit
    {
        //print("DEINIT Downloader")
    }
    
    var cachePolicy:NSURLRequest.CachePolicy
    {
        get
        {
            return _request.cachePolicy
        }
        set
        {
            _request.cachePolicy = cachePolicy
        }
    }
    
    func load(_ url:String, data:AnyObject? = nil)
    {
        self.url = url
        _responseData = NSMutableData()
        _request.url = URL(string: url)
        if _connection != nil
        {
            _connection?.cancel()
            _connection = nil
        }
        //_connection = NSURLConnection(request: _request, delegate: self)
        _connection = NSURLConnection(request: _request as URLRequest, delegate: self, startImmediately: false)
        _connection?.schedule(in: RunLoop.current, forMode: RunLoopMode.commonModes)
        _connection?.start()
    }
    
    func cancel()
    {
        _connection?.cancel()
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error)
    {
        failCallback?(error as NSError)
    }
    
    //开始下载
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse)
    {
        _contentLength = Int(response.expectedContentLength)
        startCallback?()
    }
    
    
    func connection(_ connection: NSURLConnection, didReceive data: Data)
    {
        if data.count > 0
        {
            _responseData.append(data)
        }
        
        let current:Int = (_responseData.length)
        let total:Int = (_contentLength)
        progressCallback?(current, total)
    }
    
    //下载完成
    func connectionDidFinishLoading(_ connection: NSURLConnection)
    {
        completeCallback?(_responseData as Data)
    }
    
    
}
