//
//  PhotoCell.swift
//  uicomponetTest3
//
//  Created by linhan on 14-11-21.
//  Copyright (c) 2014年 linhan. All rights reserved.
//

import Foundation
import UIKit

protocol SWPhotoViewerCellDelegate:NSObjectProtocol
{
    func photoViewerCell(cell:SWPhotoViewerCell, didSingleTapAtIndexPath indexPath: NSIndexPath)
    func photoViewerCell(cell:SWPhotoViewerCell, didLongPressAtIndexPath indexPath: NSIndexPath)
}

class SWPhotoViewerCell: UITableViewCell,UIScrollViewDelegate
{
    weak var delegate:SWPhotoViewerCellDelegate?
    
    weak var progressView:SWPhotoViewerProgressView?
    {
        didSet
        {
            if let progressView = progressView?.view
            {
                progressView.hidden = true
                contentView.insertSubview(progressView, aboveSubview: _scrollView)
                progressView.frame = CGRectMake((size.width - progressView.width) * 0.5, (size.height - progressView.height) * 0.5, progressView.width, progressView.height)
            }
        }
    }
    
    var indexPath:NSIndexPath!
    
    private var selfFrame:CGRect = CGRectZero
    
    private var _downloader:Downloader = Downloader()
    
    private var _cachePath:String?
    
    //图片打开前的位置及大小
    var startFrame:CGRect?
    
    private var _startX:CGFloat = 0
    private var _startY:CGFloat = 0
    
    //最合适比例，双击时，如果图片大于此比例，则缩小
    private var _adaptiveScale:CGFloat = 1
    
    private var _adaptivePoint:CGPoint = CGPoint(x: 0, y: 0)
    
    //图片最大缩放程度
    private var _maxScale:CGFloat = 0
    
    private var _lastRotation:CGFloat = 0
    
    
    private var _startScale:CGFloat = 1
    //捏合时相对imageview的两手指间坐标点
    private var _pinchCenter:CGPoint = CGPointZero
    //捏合时相对整个父级容器的两手指间坐标点
    private var _superPinchCenter:CGPoint = CGPointZero
    
    
    private var _imageView:UIImageView = UIImageView()
    
    lazy private var _scrollView:UIScrollView = UIScrollView()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        _imageView.removeObserver(self, forKeyPath: "frame")
    }
    
    var size:CGSize = CGSizeZero
    {
        didSet
        {
            selfFrame = CGRectMake(0, 0, size.width, size.height)
            _scrollView.frame = selfFrame
            if let progressView = progressView?.view
            {
                progressView.frame = CGRectMake((size.width - progressView.width) * 0.5, (size.height - progressView.height) * 0.5, progressView.width, progressView.height)
            }
        }
    }
    
    var photo:SWPhoto?
    {
        didSet
        {
            _imageView.image = nil
            _imageView.alpha = 1
            if let photo = photo
            {
                var largeImage:UIImage?
                if let image = photo.largeImage
                {
                    largeImage = image
                    setupImage(image)
                }
                else if let url = photo.largeImageURL
                {
                    let cacheFilenameHash:String = MD5.md532BitUpper(url)
                    _cachePath = FileUtility.imageCachePath(cacheFilenameHash)
                    largeImage = FileUtility.imageDataFromPath(_cachePath!)
                    if largeImage != nil
                    {
                        setupImage(largeImage!)
                    }
                    else
                    {
                        _downloader.load(url)
                    }
                }
                
                //大图还没加载完成，则先用小图代替
                if let thumbImage = photo.thumbImage where largeImage == nil
                {
                    setupImage(thumbImage)
                }
            }
        }
        
    }
    
    //收起消失
    func dismiss(targetFrame:CGRect? = nil)
    {
        if let targetFrame = targetFrame
        {
            UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self._imageView.frame = targetFrame
                }, completion: {finish in
                    //self._imageView.image = nil
            })
        }
        else
        {
            let scaleOffset:Double = 3 - Double(_imageView.width / _imageView.bounds.width)
            UIView.animateWithDuration(scaleOffset * 0.2, animations: {
                
                self._imageView.transform = CGAffineTransformMakeScale(3, 3)
                self._imageView.alpha = 0
                
                }, completion: {(finish:Bool) in
                    
                    self._imageView.image = nil
            })
        }
    }
    
    private func setupImage(image:UIImage, replace:Bool = false)
    {
        var replaceFrame:CGRect?
        if replace && _imageView.image != nil && !_imageView.frame.isEmpty
        {
            replaceFrame = _imageView.frame
        }
        
        _imageView.alpha = 1
        _imageView.image = image
        let imageSize:CGSize = image.size
        _imageView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height)
        _scrollView.contentSize = CGSizeMake(imageSize.width, imageSize.height)
        _scrollView.contentOffset = CGPointZero
        imageViewSuitSize()
        
        if startFrame != nil || replaceFrame != nil
        {
            let targetFrame:CGRect = _imageView.frame
            _imageView.frame = replaceFrame ?? startFrame!
            UIView.animateWithDuration(0.3, animations:{
                //self._imageView.transform = newTransform
                self._imageView.frame = targetFrame
            })
        }
    }
    
    private func setup()
    {
        backgroundColor = UIColor.clearColor()
        
        _downloader.startCallback = {[weak self] in
            self?.loadStartCallback()
        }
        _downloader.failCallback = {[weak self] error in
            self?.loadFailCallback(error)
        }
        _downloader.progressCallback = {[weak self] current, total in
            self?.loadProgressCallback(current, totalBytes: total)
        }
        _downloader.completeCallback = {[weak self] data in
            self?.loadCompleteCallback(data)
        }
        
        //长按弹出菜单选择保存到手机相册或分享
        let longPressGestureRecognizer:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "imageLongPress:")
        longPressGestureRecognizer.minimumPressDuration = 1
        
        //单击
        let singleTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "imageSingleTap:")
        let doubleTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "imageDoubleTap:")
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        singleTapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGestureRecognizer)
        
        let pinchGestureRecognizer:UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "imagePinch:")
        
        _imageView.userInteractionEnabled = true
        _imageView.addGestureRecognizer(longPressGestureRecognizer)
        _imageView.addGestureRecognizer(singleTapGestureRecognizer)
        _imageView.addGestureRecognizer(doubleTapGestureRecognizer)
        _imageView.addGestureRecognizer(pinchGestureRecognizer)
        //_imageView.addGestureRecognizer(rotationGestureRecognizer)
        _imageView.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.New, context: nil)
        
        _scrollView.delegate = self
        _scrollView.bounces = false
        contentView.addSubview(_scrollView)
        _scrollView.addSubview(_imageView)
        
        
        
        let cellTapGesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "cellTapped:")
        addGestureRecognizer(cellTapGesture)
        //cellTapGesture.requireGestureRecognizerToFail(singleTapGestureRecognizer)
    }
    
    private func loadStartCallback()
    {
        //trace("startAnimating")
        progressView?.view.hidden = false
        progressView?.startAnimating()
    }
    
    private func loadFailCallback(error:NSError)
    {
        progressView?.view.hidden = true
        progressView?.stopAnimating()
    }
    
    private func loadProgressCallback(loadedBytes:Int, totalBytes:Int)
    {
        var progress:Double = Double(loadedBytes) / Double(totalBytes)
        progress = max(min(progress, 1), 0)
        progressView?.progress = progress
    }
    
    private func loadCompleteCallback(data:NSData)
    {
        if let image = UIImage(data:data),let path = _cachePath
        {
            let replace:Bool = _imageView.image != nil
            setupImage(image, replace: replace)
            FileUtility.saveImageCacheToPath(path, image:data)
        }
        progressView?.view.hidden = true
        progressView?.stopAnimating()
    }
    
    //图片尺寸自适应缩放到容器内
    private func imageViewSuitSize()
    {
        if _imageView.image != nil
        {
            let image:UIImage = _imageView.image!
            //大长图
            let tooLong:Bool = image.size.height > 3 * image.size.width
            if tooLong
            {
                _adaptiveScale = selfFrame.width / image.size.width
            }
            else
            {
                _adaptiveScale = ViewUtil.getAdaptiveScale(image.size.width, targetH: image.size.height, containerW: selfFrame.width, containerH: selfFrame.height, inscribed: true)
            }
            
            let imageWidth:CGFloat = image.size.width * _adaptiveScale
            let imageHeight:CGFloat = image.size.height * _adaptiveScale
            if tooLong
            {
                _adaptivePoint = CGPointMake(0, 0)
            }
            else
            {
                _adaptivePoint = CGPointMake((selfFrame.width - imageWidth) * 0.5, (selfFrame.height - imageHeight) * 0.5)
            }
            
            _maxScale = 2
            if _adaptiveScale < 1
            {
                _maxScale = 1
                if image.size.width < selfFrame.width || image.size.height < selfFrame.height
                {
                    _maxScale = ViewUtil.getAdaptiveScale(image.size.width, targetH: image.size.height, containerW: selfFrame.width, containerH: selfFrame.height, inscribed: false)
                }
            }
            _imageView.transform = CGAffineTransformMakeScale(_adaptiveScale, _adaptiveScale)
            _imageView.frame = CGRectMake(_adaptivePoint.x, _adaptivePoint.y, imageWidth, imageHeight)
        }
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let imageView = object as? NSObject where imageView == _imageView && keyPath == "frame"
        {
            _scrollView.contentSize = CGSizeMake(_imageView.frame.width, _imageView.frame.height)
        }
    }
    
    //图片长按保存
    @objc private func imageLongPress(recognizer:UILongPressGestureRecognizer)
    {
        //会触发两次长按事件，一次是长按开始的时候，一次是长按结束的时候
        if recognizer.state == UIGestureRecognizerState.Began
        {
            delegate?.photoViewerCell(self, didLongPressAtIndexPath: indexPath)
        }
    }
    
    @objc private func cellTapped(recognizer:UITapGestureRecognizer)
    {
        //println("cellTapped")
        delegate?.photoViewerCell(self, didSingleTapAtIndexPath: indexPath)
    }
    
    //图片单击关闭
    @objc private func imageSingleTap(recognizer:UITapGestureRecognizer)
    {
        //println("imageSingleTap")
        delegate?.photoViewerCell(self, didSingleTapAtIndexPath: indexPath)
    }
    
    //图片双击
    @objc private func imageDoubleTap(recognizer:UITapGestureRecognizer)
    {
        if _imageView.image == nil
        {
            return
        }
        let touchPoint:CGPoint = recognizer.locationInView(self._imageView)
        //println("doubleTapPoint:\(touchPoint)")
        let scale:CGFloat = _imageView.transform.a
        let image:UIImage = _imageView.image!
        var targetWidth:CGFloat = 0
        var targetHeight:CGFloat = 0
        var targetX:CGFloat = 0
        var targetY:CGFloat = 0
        var targetScale:CGFloat = 0
        //双击时，如当前图片已经超过最适比例而缩小，否则放大
        var newTransform:CGAffineTransform
        var newFrame:CGRect
        let zoomIn:Bool = scale < (_adaptiveScale + 0.1)
        if zoomIn
        {
            targetScale = _maxScale
            newTransform = CGAffineTransformMakeScale(targetScale, targetScale)
            targetWidth = image.size.width * targetScale
            targetHeight = image.size.height * targetScale
            //双击时，双击的点移动到屏幕中间
            if targetWidth > selfFrame.width
            {
                //targetWidth = _imageView.frame.origin.x + ()
                targetX = size.width * 0.5 - touchPoint.x * targetScale
                if targetX > 0
                {
                    targetX = 0
                }
                else if targetX + targetWidth < selfFrame.width
                {
                    targetX = selfFrame.width - targetWidth
                }
                
            }
            else
            {
                targetX = (selfFrame.width - targetWidth) * 0.5
            }
            
            if targetHeight > selfFrame.height
            {
                targetY = size.height * 0.5 - touchPoint.y * targetScale
                if targetY > 0
                {
                    targetY = 0
                }
                else if targetY + targetHeight < selfFrame.height
                {
                    targetY = selfFrame.height - targetHeight
                }
                
            }
            else
            {
                targetY = (selfFrame.height - targetHeight) * 0.5
            }
            
            
        }
        //缩小时，缩到最适比例
        else
        {
            targetScale = _adaptiveScale
            newTransform = CGAffineTransformMakeScale(_adaptiveScale, _adaptiveScale)
            targetX = _adaptivePoint.x
            targetY = _adaptivePoint.y
            targetWidth = image.size.width * targetScale
            targetHeight = image.size.height * targetScale
        }
        
        newFrame = CGRectMake(targetWidth > selfFrame.width ? 0 : targetX, targetHeight > selfFrame.height ? 0 : targetY, targetWidth, targetHeight)
        //println("newFrame:\(newFrame)")
        
        UIView.animateWithDuration(0.3, animations:{
            self._imageView.transform = newTransform
            self._imageView.frame = newFrame
            if targetWidth > self.selfFrame.width || targetHeight > self.selfFrame.height
            {
                self._scrollView.contentOffset = CGPoint(x: targetWidth > self.selfFrame.width ? -targetX : 0, y: targetHeight > self.selfFrame.height ? -targetY : 0)
            }
        })
        
        
    }
    
    
    //图片捏合缩放
    @objc private func imagePinch(recognizer:UIPinchGestureRecognizer)
    {
        let rectView:UIView = recognizer.view! as UIView
        var newFrame:CGRect
        
        var targetWidth:CGFloat = 0
        var targetHeight:CGFloat = 0
        var targetX:CGFloat = 0
        var targetY:CGFloat = 0
        if recognizer.state == .Began
        {
            _startScale = rectView.transform.a
            _pinchCenter = recognizer.locationInView(_imageView)
            _superPinchCenter = recognizer.locationInView(self.contentView)
           //println("_superPinchCenter:\(_superPinchCenter)")
        }
        //为两根手指的中点
        let targetScale:CGFloat = _startScale + (recognizer.scale - 1)
        var location:CGPoint = recognizer.locationInView(self)
        
        targetX = _superPinchCenter.x - _pinchCenter.x * targetScale
        targetY = _superPinchCenter.y - _pinchCenter.y * targetScale
        
        rectView.transform = CGAffineTransformMakeScale(targetScale, targetScale);
        targetWidth = rectView.frame.width
        targetHeight = rectView.frame.height
        
        newFrame = CGRectMake(targetWidth >= selfFrame.width ? 0 : targetX, targetHeight >= selfFrame.height ? 0 : targetY, targetWidth, targetHeight)
        
        _imageView.frame = newFrame
        if targetWidth >= self.selfFrame.width || targetHeight >= self.selfFrame.height
        {
            self._scrollView.contentOffset = CGPoint(x: targetWidth >= self.selfFrame.width ? -targetX : 0, y: targetHeight >= self.selfFrame.height ? -targetY : 0)
        }
        
        //手指捏合完毕，捏合过小或者过大的进行复原
        if recognizer.state == .Ended
        {
            let scale:CGFloat = _imageView.transform.a
            let image:UIImage = _imageView.image!
            var targetScale:CGFloat = 0
            var resize:Bool = false
            var relocate:Bool = true
            
            var newTransform:CGAffineTransform
            
            if scale > _maxScale
            {
                resize = true
                relocate = true
                targetScale = _maxScale
                newTransform = CGAffineTransformMakeScale(targetScale, targetScale)
                targetX = size.width * 0.5 - _pinchCenter.x * targetScale
                targetY = size.height * 0.5 - _pinchCenter.y * targetScale
                targetWidth = image.size.width * targetScale
                targetHeight = image.size.height * targetScale
                
            }
            //缩放小于一定程度return
            else if scale < _adaptiveScale
            {
                resize = true
                targetScale = _adaptiveScale
                newTransform = CGAffineTransformMakeScale(_adaptiveScale, _adaptiveScale)
                targetX = _adaptivePoint.x
                targetY = _adaptivePoint.y
                targetWidth = image.size.width * _adaptiveScale
                targetHeight = image.size.height * _adaptiveScale
            }
            else
            {
                relocate = true
                newTransform = CGAffineTransformIdentity
                targetWidth = _imageView.frame.width
                targetHeight = _imageView.frame.height
                targetX = targetWidth >= selfFrame.width ? -self._scrollView.contentOffset.x : _imageView.frame.origin.x
                targetY = targetHeight >= selfFrame.height ? -self._scrollView.contentOffset.y : _imageView.frame.origin.y
            }
            
            if relocate
            {
                if targetWidth > selfFrame.width
                {
                    if targetX > 0
                    {
                        targetX = 0
                    }
                    else if targetX + targetWidth < selfFrame.width
                    {
                        targetX = selfFrame.width - targetWidth
                    }
                    
                }
                else
                {
                    targetX = (selfFrame.width - targetWidth) * 0.5
                }
                
                if targetHeight > selfFrame.height
                {
                    if targetY > 0
                    {
                        targetY = 0
                    }
                    else if targetY + targetHeight < selfFrame.height
                    {
                        targetY = selfFrame.height - targetHeight
                    }
                    
                }
                else
                {
                    targetY = (selfFrame.height - targetHeight) * 0.5
                }
            }
            newFrame = CGRectMake(targetWidth >= selfFrame.width ? 0 : targetX, targetHeight >= selfFrame.height ? 0 : targetY, targetWidth, targetHeight)
            if resize
            {
                
                UIView.animateWithDuration(0.3, animations:{
                    self._imageView.transform = newTransform
                    self._imageView.frame = newFrame
                    })
                if targetWidth >= self.selfFrame.width || targetHeight >= self.selfFrame.height
                {
                    self._scrollView.contentOffset = CGPoint(x: targetWidth >= self.selfFrame.width ? -targetX : 0, y: targetHeight >= self.selfFrame.height ? -targetY : 0)
                }
                
            }
            else if relocate
            {
                UIView.animateWithDuration(0.3, animations:{
                    
                    self._imageView.frame = newFrame
                    if targetWidth >= self.selfFrame.width || targetHeight >= self.selfFrame.height
                    {
                        self._scrollView.contentOffset = CGPoint(x: targetWidth >= self.selfFrame.width ? -targetX : 0, y: targetHeight >= self.selfFrame.height ? -targetY : 0)
                    }
                    
                })
                
                
            }
            
        }//state == ended
        
    }
    
    
    
    
}