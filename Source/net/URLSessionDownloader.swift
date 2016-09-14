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
class URLSessionDelegateHandler: NSObject, URLSessionDataDelegate
{
    weak var delegate:URLSessionDataDelegate?
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        delegate?.urlSession?(session, dataTask: dataTask, didReceive:data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        delegate?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }
    
    //加载完成
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        willCacheResponse proposedResponse: CachedURLResponse,
        completionHandler: (@escaping (CachedURLResponse?) -> Void))
    {
        completionHandler(proposedResponse)
    }
    
    //加载失败
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        delegate?.urlSession?(session, task: task, didCompleteWithError: error)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        delegate?.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
    }
}


class URLSessionDownloader: NSObject,URLSessionDataDelegate
{
    //NSURLConnectionDownloadDelegate
    fileprivate var _request:NSMutableURLRequest = NSMutableURLRequest()
    
    fileprivate var _session:Foundation.URLSession?
    fileprivate var _task:URLSessionDataTask?
    fileprivate var _sessionHandler:URLSessionDelegateHandler?
    
    fileprivate var _contentLength:Int = 0
    fileprivate var _responseData:NSMutableData = NSMutableData()
    
    var url:String = ""
    var startCallback:(() -> Void)?
    var failCallback:((NSError) -> Void)?
    var progressCallback:((Int,Int) -> Void)?
    var completeCallback:((Data) -> Void)?
    
    var requestModifier: ((NSMutableURLRequest) -> Void)?
    
    var timeoutInterval:Double
    {
        get {
            return _request.timeoutInterval
        }
        set {
            _request.timeoutInterval = newValue
        }
    }
    
    var cachePolicy:NSURLRequest.CachePolicy
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
        _request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        _request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:40.0) Gecko/20100101 Firefox/40.0", forHTTPHeaderField: "User-Agent")
        
        _sessionHandler = URLSessionDelegateHandler()
        _sessionHandler?.delegate = self
        
        let queue = Foundation.URLSession.shared.delegateQueue
        //let queue = NSOperationQueue.mainQueue()
        _session = Foundation.URLSession(configuration: sessionConfiguration, delegate: _sessionHandler, delegateQueue: queue)
    }
    
    var data:Data{
        return _responseData as Data
    }
    
    var sessionConfiguration = URLSessionConfiguration.ephemeral {
        didSet {
            //session = NSURLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: NSOperationQueue.mainQueue())
        }
    }
    
    func load(_ url:String, data:AnyObject? = nil)
    {
        self.url = url
        _responseData = NSMutableData()
        _request.url = URL(string: url)
        
        requestModifier?(_request)
        
        _task = _session?.dataTask(with: _request)
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
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        _responseData.append(data)
        let current:Int = _responseData.length
        let total:Int = _contentLength
        progressCallback?(current, total)
    }
    
    //加载失败
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        if let error = error {
            failCallback?(error as NSError)
        }
        else {
            completeCallback?(self._responseData as Data)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        _contentLength = Int(response.expectedContentLength)
        startCallback?()
        completionHandler(Foundation.URLSession.ResponseDisposition.allow)
    }
    
    
}
