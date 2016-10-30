



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
    var completeCallback:((NSData) -> Void)?
    
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
        _request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        _request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:40.0) Gecko/20100101 Firefox/40.0", forHTTPHeaderField: "User-Agent")
    }
    
    deinit
    {
        print("DEINIT Downloader")
    }
    
    var cachePolicy:NSURLRequestCachePolicy
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
    
    func load(url:String, data:AnyObject? = nil)
    {
        self.url = url
        _responseData = NSMutableData()
        _request.URL = NSURL(string: url)
        if _connection != nil
        {
            _connection?.cancel()
            _connection = nil
        }
        //_connection = NSURLConnection(request: _request, delegate: self)
        _connection = NSURLConnection(request: _request, delegate: self, startImmediately: false)
        _connection?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        _connection?.start()
    }
    
    func cancel()
    {
        _connection?.cancel()
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError)
    {
        failCallback?(error)
    }
    
    //开始下载
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse)
    {
        _contentLength = Int(response.expectedContentLength)
        startCallback?()
    }
    
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData)
    {
        if data.length > 0
        {
            _responseData.appendData(data)
        }
        
        let current:Int = (_responseData.length)
        let total:Int = (_contentLength)
        progressCallback?(current, total)
    }
    
    //下载完成
    func connectionDidFinishLoading(connection: NSURLConnection)
    {
        completeCallback?(_responseData)
    }
    
    
}