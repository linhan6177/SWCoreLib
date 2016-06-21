//
//  Downloader.swift
//  JokeSiJie
//
//  Created by linhan on 14-11-27.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
import UIKit

//NSURLSession Delegate是强引用，因此中间加入一个弱引用层来打破引用循环
class URLSessionDelegateHandler: NSObject, NSURLSessionDataDelegate
{
    weak var delegate:NSURLSessionDataDelegate?
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)
    {
        delegate?.URLSession?(session, dataTask: dataTask, didReceiveData:data)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
    {
        delegate?.URLSession?(session, dataTask: dataTask, didReceiveResponse: response, completionHandler: completionHandler)
    }
    
    //加载完成
    func URLSession(
        session: NSURLSession,
        dataTask: NSURLSessionDataTask,
        willCacheResponse proposedResponse: NSCachedURLResponse,
        completionHandler: ((NSCachedURLResponse?) -> Void))
    {
        completionHandler(proposedResponse)
    }
    
    //加载失败
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        delegate?.URLSession?(session, task: task, didCompleteWithError: error)
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
    {
        delegate?.URLSession?(session, didReceiveChallenge: challenge, completionHandler: completionHandler)
    }
}


class Downloader: NSObject,NSURLSessionDataDelegate
{
    //NSURLConnectionDownloadDelegate
    private var _request:NSMutableURLRequest = NSMutableURLRequest()
    
    private var _session:NSURLSession?
    private var _task:NSURLSessionDataTask?
    private var _sessionHandler:URLSessionDelegateHandler?
    
    private var _contentLength:Int = 0
    private var _responseData:NSMutableData = NSMutableData()
    
    var url:String = ""
    var startCallback:(() -> Void)?
    var failCallback:((NSError) -> Void)?
    var progressCallback:((Int,Int) -> Void)?
    var completeCallback:((NSData) -> Void)?
    
    var requestModifier: (NSMutableURLRequest -> Void)?
    
    var timeoutInterval:Double
    {
        get {
            return _request.timeoutInterval
        }
        set {
            _request.timeoutInterval = newValue
        }
    }
    
    var cachePolicy:NSURLRequestCachePolicy
    {
        get {
            return _request.cachePolicy
        }
        set {
            _request.cachePolicy = newValue
        }
    }
    
    deinit
    {
        //print("DEINIT Downloader")
    }
    
    override init()
    {
        super.init()
        _request.timeoutInterval = 30
        _request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        _request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:40.0) Gecko/20100101 Firefox/40.0", forHTTPHeaderField: "User-Agent")
        
        _sessionHandler = URLSessionDelegateHandler()
        _sessionHandler?.delegate = self
        
        let queue = NSURLSession.sharedSession().delegateQueue
        //let queue = NSOperationQueue.mainQueue()
        _session = NSURLSession(configuration: sessionConfiguration, delegate: _sessionHandler, delegateQueue: queue)
    }
    
    var data:NSData{
        return _responseData
    }
    
    var sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration() {
        didSet {
            //session = NSURLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: NSOperationQueue.mainQueue())
        }
    }
    
    func load(url:String, data:AnyObject? = nil)
    {
        self.url = url
        _responseData = NSMutableData()
        _request.URL = NSURL(string: url)
        
        requestModifier?(_request)
        
        _task = _session?.dataTaskWithRequest(_request)
        _task?.resume()
    }
    
    func cancel()
    {
        _task?.cancel()
        _responseData = NSMutableData()
    }
    
    
    //MARK ============================================================================================
    //==============================     NSURLConnectionDataDelegate    ===============================
    //=================================================================================================
    
    //接收响应数据
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)
    {
        _responseData.appendData(data)
        let current:Int = _responseData.length
        let total:Int = _contentLength
        progressCallback?(current, total)
    }
    
    //加载失败
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        if let error = error {
            failCallback?(error)
        }
        else {
            completeCallback?(self._responseData)
        }
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
    {
        _contentLength = Int(response.expectedContentLength)
        startCallback?()
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    
}