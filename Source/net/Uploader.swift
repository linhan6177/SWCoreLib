



//
//  Downloader.swift
//  JokeSiJie
//
//  Created by linhan on 14-11-27.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
import UIKit

@objc protocol UploaderDelegate:NSObjectProtocol
{
    func uploaderResponse(_ uploader:Uploader, response data:Data?, bindArgs:AnyObject?)
    
    @objc optional func uploaderFail(_ uploader:Uploader, error:NSError, bindArgs:AnyObject?)
}

class Uploader: NSObject,NSURLConnectionDataDelegate
{
    weak var delegate:UploaderDelegate?
    
    var bindArgs:AnyObject?
    
    fileprivate var _connection:NSURLConnection?
    
    fileprivate var _contentLength:Int = 0
    fileprivate var _responseData:NSMutableData = NSMutableData()
    
    
    var startCallback:(() -> Void)?
    var failCallback:((NSError) -> Void)?
    var progressCallback:((Int,Int) -> Void)?
    var responseCallback:((Data?) -> Void)?
    
    override init()
    {
        super.init()
    }
    
    deinit
    {
        //trace("Uploader deinit")
    }
    
    func upload(_ url:String, fileData:Data!, uploadDataFieldName:String!, params:NSDictionary? = nil)
    {
        let request:NSMutableURLRequest = getPOSTRequest(URL(string: url)!, fileData:fileData, uploadDataFieldName:uploadDataFieldName, params:params)
        _responseData = NSMutableData()
        if _connection != nil
        {
            _connection!.cancel()
            _connection = nil
        }
        _connection = NSURLConnection(request: request as URLRequest, delegate: self)
        
        startCallback?()
    }
    
    func cancel()
    {
        _connection?.cancel()
    }
    
    func getPOSTRequest(_ url:URL, fileData:Data!, uploadDataFieldName:String!, params:NSDictionary!)->NSMutableURLRequest
    {
        // Create a POST request
        let myMedRequest:NSMutableURLRequest = NSMutableURLRequest(url: url, cachePolicy:NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
            timeoutInterval:30)
        myMedRequest.httpMethod = "POST"
        
        let POSTBoundary:String = "nbdfapfjygwkgavthqwnjvrjdnkyapny"
        
        
        // Add HTTP Body
        let POSTBody:NSMutableData = NSMutableData()
        
        // Add Key/Values to the Body
        if (params != nil)
        {
            for (key,value) in params
            {
                POSTBody.append(NSString(string: "--\(POSTBoundary)\r\n").data(using: String.Encoding.utf8)!)
                POSTBody.append(NSString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n").data(using: String.Encoding.utf8)!)
                POSTBody.append(NSString(string: "\(value)\r\n").data(using: String.Encoding.utf8)!)
            }
        }
        
        //字节
        //Assuming data is not nil we add this to the multipart form
        if (fileData != nil)
        {
            let filename:String = "1.jpg"
            POSTBody.append(NSString(string: "--\(POSTBoundary)\r\n").data(using: String.Encoding.utf8)!)
            POSTBody.append(NSString(string: "Content-Disposition: form-data; name=\"\(uploadDataFieldName)\"; filename=\"\(filename)\"\r\n").data(using: String.Encoding.utf8)!)
            POSTBody.append(NSString(string: "Content-Type:image/jpeg\r\n\r\n").data(using: String.Encoding.utf8)!)
            POSTBody.append(fileData)
            POSTBody.append(NSString(string: "\r\n").data(using: String.Encoding.utf8)!)
        }
        
        // Add the closing -- to the POST Form
        POSTBody.append(NSString(string: "\r\n--\(POSTBoundary)--\r\n").data(using: String.Encoding.utf8)!)
        
        // Add the body to the myMedRequest & return
        myMedRequest.httpBody = POSTBody as Data
        
        //设置HTTPHeader
        myMedRequest.setValue("multipart/form-data; boundary=\(POSTBoundary)", forHTTPHeaderField: "Content-Type")
        //设置Content-Length
        myMedRequest.setValue("\(POSTBody.length)", forHTTPHeaderField: "Content-Length")
        
        
        return myMedRequest;
    }
    
    
    //上传失败
    func connection(_ connection: NSURLConnection, didFailWithError error: Error)
    {
        failCallback?(error as NSError)
        delegate?.uploaderFail?(self, error: error as NSError, bindArgs:bindArgs)
    }
    
    //上传过程
    func connection(_ connection: NSURLConnection, didSendBodyData bytesWritten: Int, totalBytesWritten: Int, totalBytesExpectedToWrite: Int)
    {
        progressCallback?(totalBytesWritten, totalBytesExpectedToWrite)
        var progress:Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
    }
    
    
    func connection(_: NSURLConnection, didReceive data: Data)
    {
        _responseData.append(data)
    }
    
    //下载完成
    func connectionDidFinishLoading(_ connection: NSURLConnection)
    {
        responseCallback?(_responseData as Data)
        delegate?.uploaderResponse(self, response:_responseData as Data, bindArgs:bindArgs)
    }
    
    
}
