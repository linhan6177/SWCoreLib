



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
    func uploaderResponse(uploader:Uploader, response data:NSData?, bindArgs:AnyObject?)
    
    optional func uploaderFail(uploader:Uploader, error:NSError, bindArgs:AnyObject?)
}

class Uploader: NSObject,NSURLConnectionDataDelegate
{
    weak var delegate:UploaderDelegate?
    
    var bindArgs:AnyObject?
    
    private var _connection:NSURLConnection?
    
    private var _contentLength:Int = 0
    private var _responseData:NSMutableData = NSMutableData()
    
    
    var startCallback:(() -> Void)?
    var failCallback:((NSError) -> Void)?
    var progressCallback:((Int,Int) -> Void)?
    var responseCallback:((NSData?) -> Void)?
    
    override init()
    {
        super.init()
    }
    
    deinit
    {
        //trace("Uploader deinit")
    }
    
    func upload(url:String, fileData:NSData!, uploadDataFieldName:String!, params:NSDictionary? = nil)
    {
        let request:NSMutableURLRequest = getPOSTRequest(NSURL(string: url)!, fileData:fileData, uploadDataFieldName:uploadDataFieldName, params:params)
        _responseData = NSMutableData()
        if _connection != nil
        {
            _connection!.cancel()
            _connection = nil
        }
        _connection = NSURLConnection(request: request, delegate: self)
        
        startCallback?()
    }
    
    func cancel()
    {
        _connection?.cancel()
    }
    
    func getPOSTRequest(url:NSURL, fileData:NSData!, uploadDataFieldName:String!, params:NSDictionary!)->NSMutableURLRequest
    {
        // Create a POST request
        let myMedRequest:NSMutableURLRequest = NSMutableURLRequest(URL: url, cachePolicy:NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval:30)
        myMedRequest.HTTPMethod = "POST"
        
        let POSTBoundary:String = "nbdfapfjygwkgavthqwnjvrjdnkyapny"
        
        
        // Add HTTP Body
        let POSTBody:NSMutableData = NSMutableData()
        
        // Add Key/Values to the Body
        if (params != nil)
        {
            for (key,value) in params
            {
                POSTBody.appendData(NSString(string: "--\(POSTBoundary)\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
                POSTBody.appendData(NSString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
                POSTBody.appendData(NSString(string: "\(value)\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        
        //字节
        //Assuming data is not nil we add this to the multipart form
        if (fileData != nil)
        {
            let filename:String = "1.jpg"
            POSTBody.appendData(NSString(string: "--\(POSTBoundary)\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            POSTBody.appendData(NSString(string: "Content-Disposition: form-data; name=\"\(uploadDataFieldName)\"; filename=\"\(filename)\"\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            POSTBody.appendData(NSString(string: "Content-Type:image/jpeg\r\n\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            POSTBody.appendData(fileData)
            POSTBody.appendData(NSString(string: "\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        
        // Add the closing -- to the POST Form
        POSTBody.appendData(NSString(string: "\r\n--\(POSTBoundary)--\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
        
        // Add the body to the myMedRequest & return
        myMedRequest.HTTPBody = POSTBody
        
        //设置HTTPHeader
        myMedRequest.setValue("multipart/form-data; boundary=\(POSTBoundary)", forHTTPHeaderField: "Content-Type")
        //设置Content-Length
        myMedRequest.setValue("\(POSTBody.length)", forHTTPHeaderField: "Content-Length")
        
        
        return myMedRequest;
    }
    
    
    //上传失败
    func connection(connection: NSURLConnection, didFailWithError error: NSError)
    {
        failCallback?(error)
        delegate?.uploaderFail?(self, error: error, bindArgs:bindArgs)
    }
    
    //上传过程
    func connection(connection: NSURLConnection, didSendBodyData bytesWritten: Int, totalBytesWritten: Int, totalBytesExpectedToWrite: Int)
    {
        progressCallback?(totalBytesWritten, totalBytesExpectedToWrite)
        var progress:Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
    }
    
    
    func connection(_: NSURLConnection, didReceiveData data: NSData)
    {
        _responseData.appendData(data)
    }
    
    //下载完成
    func connectionDidFinishLoading(connection: NSURLConnection)
    {
        responseCallback?(_responseData)
        delegate?.uploaderResponse(self, response:_responseData, bindArgs:bindArgs)
    }
    
    
}