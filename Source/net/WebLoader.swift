//
//  YRHttpRequest.swift
//  JokeClient-Swift
//
//  Created by YANGReal on 14-6-5.
//  Copyright (c) 2014年 YANGReal. All rights reserved.
//

//import UIKit
import Foundation

@objc protocol WebLoaderDelegate:NSObjectProtocol
{
    optional func webLoaderDidFail(webLoader:WebLoader, error:NSError?, bindArgs:AnyObject?)
    
    optional func webLoaderCacheDataDidFinishLoading(webLoader:WebLoader, data:NSData, bindArgs:AnyObject?)
    
    func webLoaderDidFinishLoading(webLoader:WebLoader, data:NSData, bindArgs:AnyObject?)
}

//NSURLSession Delegate是强引用，因此中间加入一个弱引用层来打破引用循环
class WebLoaderSessionHandler: NSObject, NSURLSessionDataDelegate
{
    weak var delegate:NSURLSessionDataDelegate?
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)
    {
        delegate?.URLSession?(session, dataTask: dataTask, didReceiveData:data)
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

class WebLoader: NSObject,NSURLSessionDataDelegate
{
    weak var delegate:WebLoaderDelegate?
    
    var bindArgs:AnyObject?
    
    private var _session:NSURLSession?
    private var _task:NSURLSessionDataTask?
    private var _sessionHandler:WebLoaderSessionHandler?
    
    private var _responseData:NSMutableData = NSMutableData()
    
    private var _url:String = ""
    var url:String
    {
        return _url
    }
    
    var localCertData: NSData?
    var SSLValidateErrorCallBack: (() -> Void)?
    
    
    
    private var _requestData:AnyObject?
    private var _method:String = "GET"
    private var _headers:[String:String]?
    
    var cachePolicy:NSURLRequestCachePolicy = .UseProtocolCachePolicy
    
    override init()
    {
        super.init()
        
        _sessionHandler = WebLoaderSessionHandler()
        _sessionHandler?.delegate = self
        
        let configuration = NSURLSession.sharedSession().configuration
        let queue = NSURLSession.sharedSession().delegateQueue
        _session = NSURLSession(configuration: configuration, delegate: _sessionHandler, delegateQueue: queue)
    }
    
    deinit
    {
        //print("DEINIT WebLoader")
    }
    
    //MARK ============================================================================================
    //==============================            Public Method           ===============================
    //=================================================================================================
    
    func load(url:String, data:AnyObject? = nil, method:String? = "GET", headers:[String:String]? = nil, returnCacheData:Bool = false)
    {
        
        if url != _url
        {
            _url = url
        }
        
        _responseData = NSMutableData()
        let request = WebLoader.buildRequest(url, data:data, method:method, headers:headers)
        (request as? NSMutableURLRequest)?.cachePolicy = cachePolicy
        //如果本地有缓存
        if returnCacheData
        {
            let response:NSCachedURLResponse? = NSURLCache.sharedURLCache().cachedResponseForRequest(request)
            //println("response:\(response?.data.length)")
            if let data = response?.data where data.length > 0
            {
                delegate?.webLoaderCacheDataDidFinishLoading?(self, data:data, bindArgs:bindArgs)
            }
        }
        
        _task = _session?.dataTaskWithRequest(request)
        _task?.resume()
    }
    
    func addSSLPinning(LocalCertData data: NSData, SSLValidateErrorCallBack: (()->Void)? = nil) {
        self.localCertData = data
        self.SSLValidateErrorCallBack = SSLValidateErrorCallBack
    }
    
    func cancel()
    {
        _task?.cancel()
    }
    
    
    //MARK ============================================================================================
    //==============================        NSURLSessionDelegate        ===============================
    //=================================================================================================
    
    //接收响应数据
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)
    {
        _responseData.appendData(data)
    }
    
    //加载失败
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        if let error = error
        {
            dispatch_async(dispatch_get_main_queue(), {
                self.delegate?.webLoaderDidFail?(self, error:error, bindArgs:self.bindArgs)
            })
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), {
                
                var data:NSData = self._responseData
                if let statusCode = (task.response as? NSHTTPURLResponse)?.statusCode where statusCode == 304,
                   let request = task.currentRequest,
                   let cachedData = NSURLCache.sharedURLCache().cachedResponseForRequest(request)?.data
                {
                    data = cachedData
                }
                self.delegate?.webLoaderDidFinishLoading(self, data:data, bindArgs:self.bindArgs)
            })
        }
    }
    
    //证书验证
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if let localCertificateData = self.localCertData
        {
            if let serverTrust = challenge.protectionSpace.serverTrust,
                certificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
                remoteCertificateData: NSData = SecCertificateCopyData(certificate) {
                    if localCertificateData.isEqualToData(remoteCertificateData) {
                        let credential = NSURLCredential(forTrust: serverTrust)
                        challenge.sender?.useCredential(credential, forAuthenticationChallenge: challenge)
                        completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, credential)
                    } else {
                        challenge.sender?.cancelAuthenticationChallenge(challenge)
                        completionHandler(NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil)
                        self.SSLValidateErrorCallBack?()
                    }
            } else {
                NSLog("Get RemoteCertificateData or LocalCertificateData error!")
            }
        }
        else {
            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, nil)
        }
    }
    
    
    
    
    class func query(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sort(<) {
            let value = parameters[key]!
            components += queryComponents(key, value)
        }
        
        return (components.map { "\($0)=\($1)" } as [String]).joinWithSeparator("&")
    }
    
    class func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            let valueString:String = "\(value)"
            components.append((key.URLEncoded, valueString.URLEncoded))
        }
        
        return components
    }
    
    
    
    
    //创建一个请求头
    class func buildRequest(url:String, data:AnyObject? = nil, method:String? = "GET", headers:[String:String]? = nil) -> NSURLRequest
    {
        let HTTPMethod = method ?? "GET"
        var HTTPBody:NSData?
        var HTTPHeaders:[String:String] = headers ?? [String:String]()
        var contentType:String? = HTTPHeaders["Content-Type"]
        var requestURL:String = url
        if let data = data
        {
            var queryString:String
            if let dic = data as? [String: AnyObject]
            {
                queryString = query(dic)
                contentType = contentType ?? "application/x-www-form-urlencoded; charset=UTF-8"
                HTTPHeaders["Content-Type"] = contentType
            }
            else
            {
                queryString = HTTPMethod == "GET" ? "\(data)".URLEncoded : "\(data)"
            }
            
            if HTTPMethod == "GET"
            {
                //requestURL += (url.indexOf("?") == -1 ? "?" : "&") + queryString
                requestURL += (url.containsString("?") ? "&" : "?") + queryString
            }
            else if HTTPMethod == "POST"
            {
                HTTPBody = queryString.dataUsingEncoding(NSUTF8StringEncoding)
            }
        }
        //println("requestURL:\(requestURL)")
        let nsurl:NSURL = NSURL(string: requestURL) ?? NSURL(string: requestURL.URLEncoded)!
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: nsurl, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 25)
        request.HTTPMethod = HTTPMethod
        
        if HTTPMethod == "POST"
        {
            request.HTTPBody = HTTPBody
        }
        
        //设置标头
        if HTTPHeaders.count > 0
        {
            for (key, value) in HTTPHeaders
            {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    
    class func loadLocalElseRemote(url:String, localCompletionHandler:((data:NSData?)->Void), remoteCompletionHandler:((data:NSData?)->Void), errorHandler:((error:NSError)->Void), data:AnyObject? = nil, method:String? = "GET", headers:[String:String]? = nil) -> NSURLRequest
    {
        
        
        let request = WebLoader.load(url, completionHandler: {data in
        
            remoteCompletionHandler(data:data)
        
        }, errorHandler: errorHandler, data: data, method: method, headers: headers)
        
        //如果本地有缓存
        let response:NSCachedURLResponse? = NSURLCache.sharedURLCache().cachedResponseForRequest(request)
        if let data = response?.data where data.length > 0
        {
            localCompletionHandler(data: data)
        }
        
        return request
    }

    
    class func load(url:String, completionHandler:((data:NSData?)->Void), errorHandler:((error:NSError)->Void), data:AnyObject? = nil, method:String? = "GET", headers:[String:String]? = nil) -> NSURLRequest
    {
        
        let request = buildRequest(url, data:data, method:method, headers:headers)
        
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { response, data, error in
            if let error = error
            {
                errorHandler(error:error)
            }
            else
            {
                completionHandler(data:data)
            }
        })
        
        return request
    }
    
    
    
}
