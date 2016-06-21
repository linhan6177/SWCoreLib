//
//  ScrollADImage.swift
//  SMZDM
//
//  Created by linhan on 15-1-25.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit
@objc protocol ScrollADImageDelagate:NSObjectProtocol
{
    //
    optional func scrollADImage(scrollADImage: ScrollADImage, didSelectIndex index: Int)
    optional func scrollADImage(scrollADImage: ScrollADImage, didScrollToIndex index: Int)
}

class ScrollADImage:UIView,UIScrollViewDelegate
{
    weak var delegate:ScrollADImageDelagate?
    
    //自动滚动时间间隔(当大于0时开启自动滚动，小于0关闭自动滚动)
    var autoScrollInterval:Double = 0
        {
        didSet
        {
            if autoScrollInterval > 0
            {
                _timer = MSWeakTimer.scheduledTimerWithTimeInterval(autoScrollInterval, target: self, selector: "timeInterval", userInfo: nil, repeats: true, dispatchQueue: dispatch_get_main_queue())
            }
            else
            {
                _timer?.invalidate()
                _timer = nil
            }
        }
    }
    
    //缓存的，用于重用的ImageView
    private var _cacheImageViews:[ImageLoader] = []
    
    //当前在用的imageView
    private var _imageViews:[ImageLoader] = []
    
    private var _timer:MSWeakTimer?
    
    private var _index:Int = 1
    
    private var _scrollView:UIScrollView = UIScrollView()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    init()
    {
        super.init(frame: CGRectZero)
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        //print("DEINIT ScrollADImage")
    }
    
    override var frame:CGRect
        {
        get
        {
            return super.frame
        }
        set
        {
            super.frame = newValue
            _scrollView.frame = CGRectMake(0, 0, newValue.width, newValue.height)
        }
    }
    
    
    private var _multiImage:Bool = false
    var images:[AnyObject] = []
        {
        didSet
        {
            _imageViews.removeAll()
            _scrollView.removeAllSubview()
            _multiImage = images.count > 1
            if images.count > 0
            {
                let numCreate:Int = max((_multiImage ? images.count + 2 : 1) - _cacheImageViews.count, 0)
                for _ in 0..<numCreate
                {
                    let imageView:ImageLoader = createImageView()
                    _cacheImageViews.append(imageView)
                }
                
                if _multiImage
                {
                    //首尾多加两个，到达无限循环滚动,3+123+1
                    _scrollView.contentSize = CGSizeMake(frame.width * CGFloat(images.count + 2), frame.height)
                    //停留在第一张
                    _scrollView.contentOffset = CGPointMake(frame.width, 0)
                    
                    var item:AnyObject = images.last!
                    addImageView(item, tag:-1)
                    for i in 0..<images.count
                    {
                        item = images[i]
                        addImageView(item, tag:i)
                    }
                    item = images.first!
                    addImageView(item, tag:images.count)
                }
                else
                {
                    _scrollView.contentSize = CGSizeMake(frame.width, frame.height)
                    _scrollView.contentOffset = CGPointMake(0, 0)
                    addImageView(images[0], tag:0)
                }
                scrollViewDidEndScrolling()
            }//end count > 0
        }//end did set
    }
    
    private func createImageView() -> ImageLoader
    {
        let tapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:"imageViewTapped:")
        let imageView:ImageLoader = ImageLoader()
        imageView.clipsToBounds = true
        imageView.options.contentMode = .ScaleAspectFill
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.completeCallback = {imageView, readFromCache in
            if !readFromCache
            {
                imageView.alpha = 0
                UIView.animateWithDuration(0.3, animations: {
                    imageView.alpha = 1
                })
            }
        }
        return imageView
    }
    
    private func setup()
    {
        backgroundColor = UIColor(white: 0.97, alpha: 1)
        
        _scrollView.delegate = self
        _scrollView.clipsToBounds = true
        //不显示水平滚动条
        _scrollView.showsHorizontalScrollIndicator = false
        _scrollView.showsVerticalScrollIndicator = false
        _scrollView.pagingEnabled = true
        addSubview(_scrollView)
        
    }
    
    private func addImageView(image:AnyObject, tag:Int)
    {
        let x:CGFloat = CGFloat(_multiImage ? tag + 1 : tag) * width
        let imageView:ImageLoader = _cacheImageViews.valueAt(_imageViews.count) ?? createImageView()
        imageView.frame = CGRectMake(x, 0, width, height)
        imageView.tag = tag
        if let image = image as? UIImage
        {
            imageView.image = image
        }
        else if let url = image as? String
        {
            imageView.load(url)
        }
        _imageViews.append(imageView)
        _scrollView.addSubview(imageView)
    }
    
    private func scrollViewDidEndScrolling()
    {
        if !_didEndScrolling
        {
            _didEndScrolling = true
            
            let contentOffset:CGPoint = _scrollView.contentOffset
            let imageWidth:CGFloat = _scrollView.width
            let index:Int = Int(contentOffset.x / imageWidth)
            if index != _index
            {
                _index = index
                if _multiImage
                {
                    if index == 0
                    {
                        _index = images.count
                        _scrollView.contentOffset = CGPointMake(CGFloat(_index) * imageWidth, 0)
                    }
                    if index > images.count
                    {
                        _index = 1
                        _scrollView.contentOffset = CGPointMake(imageWidth, 0)
                    }
                }
                
                if let delegate = delegate where delegate.respondsToSelector("scrollADImage:didScrollToIndex:")
                {
                    delegate.scrollADImage?(self, didScrollToIndex: _multiImage ? _index - 1 : _index)
                }
            }
        }
        
    }
    
    private var _didEndScrolling:Bool = false
    func scrollViewDidScroll(scrollView: UIScrollView)
    {
        _didEndScrolling = false
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
        scrollViewDidEndScrolling()
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView)
    {
        scrollViewDidEndScrolling()
    }
    
    @objc private func timeInterval()
    {
        if _multiImage && !_scrollView.dragging
        {
            _scrollView.setContentOffset(CGPointMake(CGFloat(_index + 1) * _scrollView.width, 0), animated: true)
        }
    }
    
    @objc private func imageViewTapped(recongnizer:UITapGestureRecognizer)
    {
        if let imageView:UIImageView = recongnizer.view as? UIImageView
        {
            let index:Int = imageView.tag
            if index >= 0 && index < images.count
            {
                if let delegate = delegate where delegate.respondsToSelector("scrollADImage:didSelectIndex:")
                {
                    delegate.scrollADImage?(self, didSelectIndex: index)
                }
            }
        }
        
    }
    
    
    
}//end class