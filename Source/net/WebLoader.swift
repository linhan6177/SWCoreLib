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
    @objc optional func webLoaderDidFail(_ webLoader:WebLoader, error:NSError?, bindArgs:Any?)
    
    @objc optional func webLoaderCacheDataDidFinishLoading(_ webLoader:WebLoader, data:Data, bindArgs:Any?)
    
    func webLoaderDidFinishLoading(_ webLoader:WebLoader, data:Data, bindArgs:Any?)
}

//NSURLSession Delegate是强引用，因此中间加入一个弱引用层来打破引用循环
class WebLoaderSessionHandler: NSObject, URLSessionDataDelegate
{
    weak var delegate:URLSessionDataDelegate?
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        delegate?.urlSession?(session, dataTask: dataTask, didReceive:data)
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

class WebLoader: NSObject,URLSessionDataDelegate
{
    weak var delegate:WebLoaderDelegate?
    
    var bindArgs:Any?
    
    private var _session:Foundation.URLSession?
    private var _task:URLSessionDataTask?
    private var _sessionHandler:WebLoaderSessionHandler?
    
    private var _responseData:NSMutableData = NSMutableData()
    
    private var _url:String = ""
    var url:String
    {
        return _url
    }
    
    var localCertData: Data?
    var SSLValidateErrorCallBack: (() -> Void)?
    
    
    
    private var _requestData:AnyObject?
    private var _method:String = "GET"
    private var _headers:[String:String]?
    
    var cachePolicy:NSURLRequest.CachePolicy = .useProtocolCachePolicy
    
    override init()
    {
        super.init()
        
        _sessionHandler = WebLoaderSessionHandler()
        _sessionHandler?.delegate = self
        
        let configuration = Foundation.URLSession.shared.configuration
        let queue = Foundation.URLSession.shared.delegateQueue
        _session = Foundation.URLSession(configuration: configuration, delegate: _sessionHandler, delegateQueue: queue)
    }
    
    deinit
    {
        //print("DEINIT WebLoader")
    }
    
    //MARK ============================================================================================
    //==============================            Public Method           ===============================
    //=================================================================================================
    
    func load(_ url:String, data:Any? = nil, method:String? = "GET", headers:[String:String]? = nil, returnCacheData:Bool = false)
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
            let response:CachedURLResponse? = URLCache.shared.cachedResponse(for: request)
            //println("response:\(response?.data.length)")
            if let data = response?.data , data.count > 0
            {
                delegate?.webLoaderCacheDataDidFinishLoading?(self, data:data, bindArgs:bindArgs)
            }
        }
        
        _task = _session?.dataTask(with: request)
        _task?.resume()
    }
    
    func addSSLPinning(LocalCertData data: Data, SSLValidateErrorCallBack: (()->Void)? = nil) {
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
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        _responseData.append(data)
    }
    
    //加载失败
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        if let error = error
        {
            self.delegate?.webLoaderDidFail?(self, error:error as NSError?, bindArgs:self.bindArgs)
        }
        else
        {
            var data:Data = self._responseData as Data
            if let statusCode = (task.response as? HTTPURLResponse)?.statusCode , statusCode == 304,
                let request = task.currentRequest,
                let cachedData = URLCache.shared.cachedResponse(for: request)?.data
            {
                data = cachedData
            }
            self.delegate?.webLoaderDidFinishLoading(self, data:data, bindArgs:self.bindArgs)
        }
    }
    
    //证书验证
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let localCertificateData = self.localCertData
        {
            if let serverTrust = challenge.protectionSpace.serverTrust,
                let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
                let remoteCertificateData: Data = SecCertificateCopyData(certificate) as Data {
                    if localCertificateData == remoteCertificateData {
                        let credential = URLCredential(trust: serverTrust)
                        challenge.sender?.use(credential, for: challenge)
                        completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, credential)
                    } else {
                        challenge.sender?.cancel(challenge)
                        completionHandler(Foundation.URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
                        self.SSLValidateErrorCallBack?()
                    }
            } else {
                NSLog("Get RemoteCertificateData or LocalCertificateData error!")
            }
        }
        else {
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, nil)
        }
    }
    
    
    
    
    class func query(_ parameters: [String: Any], URLEncode:Bool = true) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(key, value, URLEncode:URLEncode)
        }
        
        return (components.map { "\($0)=\($1)" } as [String]).joined(separator: "&")
    }
    
    class func queryComponents(_ key: String, _ value: Any, URLEncode:Bool = true) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value, URLEncode:URLEncode)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value, URLEncode:URLEncode)
            }
        } else {
            let valueString:String = "\(value)"
            components.append((URLEncode ? key.URLEncoded : key, URLEncode ? valueString.URLEncoded : valueString))
        }
        
        return components
    }
    
    
    
    
    //创建一个请求头
    class func buildRequest(_ url:String, data:Any? = nil, method:String? = "GET", headers:[String:String]? = nil) -> URLRequest
    {
        let HTTPMethod = method ?? "GET"
        var HTTPBody:Data?
        var HTTPHeaders:[String:String] = headers ?? [String:String]()
        var contentType:String? = HTTPHeaders["Content-Type"]
        var requestURL:String = url
        if let data = data
        {
            var queryString:String = ""
            if let dic = data as? [String: Any]
            {
                queryString = query(dic)
                contentType = contentType ?? "application/x-www-form-urlencoded; charset=UTF-8"
                HTTPHeaders["Content-Type"] = contentType
            }
            else if !(data is Data)
            {
                queryString = HTTPMethod == "GET" ? "\(data)".URLEncoded : "\(data)"
            }
            
            if HTTPMethod == "GET"
            {
                //requestURL += (url.indexOf("?") == -1 ? "?" : "&") + queryString
                requestURL += (url.contains("?") ? "&" : "?") + queryString
            }
            else if HTTPMethod == "POST" || HTTPMethod == "PUT"
            {
                if let data = data as? Data
                {
                    HTTPBody = data
                }
                else
                {
                    HTTPBody = queryString.data(using: String.Encoding.utf8)
                }
            }
        }
        //println("requestURL:\(requestURL)")
        let nsurl:URL = URL(string: requestURL) ?? URL(string: requestURL.URLEncoded)!
        let request:NSMutableURLRequest = NSMutableURLRequest(url: nsurl, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 25)
        request.httpMethod = HTTPMethod
        
        if HTTPMethod == "POST" || HTTPMethod == "PUT"
        {
            request.httpBody = HTTPBody
        }
        
        //设置标头
        if HTTPHeaders.count > 0
        {
            for (key, value) in HTTPHeaders
            {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request as URLRequest
    }
    
    
    class func loadLocalElseRemote(_ url:String, localCompletionHandler:((_ data:Data?)->Void), remoteCompletionHandler:@escaping ((_ data:Data?)->Void), errorHandler:@escaping ((_ error:NSError)->Void), data:AnyObject? = nil, method:String? = "GET", headers:[String:String]? = nil) -> URLRequest
    {
        
        
        let request = WebLoader.load(url, completionHandler: {data in
        
            remoteCompletionHandler(data)
        
        }, errorHandler: errorHandler, data: data, method: method, headers: headers)
        
        //如果本地有缓存
        let response:CachedURLResponse? = URLCache.shared.cachedResponse(for: request)
        if let data = response?.data , data.count > 0
        {
            localCompletionHandler(data)
        }
        
        return request
    }

    @discardableResult
    class func load(_ url:String, completionHandler:@escaping ((_ data:Data?)->Void), errorHandler:@escaping ((_ error:NSError)->Void), data:Any? = nil, method:String? = "GET", headers:[String:String]? = nil) -> URLRequest
    {
        
        let request = buildRequest(url, data:data, method:method, headers:headers)
        
        let queue = OperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { response, data, error in
            if let error = error
            {
                errorHandler(error as NSError)
            }
            else
            {
                completionHandler(data)
            }
        })
        
        return request
    }
    
    
    
}
