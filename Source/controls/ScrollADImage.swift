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
    @objc optional func scrollADImage(_ scrollADImage: ScrollADImage, didSelectIndex index: Int)
    @objc optional func scrollADImage(_ scrollADImage: ScrollADImage, didScrollToIndex index: Int)
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
                _timer = MSWeakTimer.scheduledTimer(withTimeInterval: autoScrollInterval, target: self, selector: #selector(timeInterval), userInfo: nil, repeats: true, dispatchQueue: DispatchQueue.main)
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
        super.init(frame: CGRect.zero)
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        print("DEINIT ScrollADImage")
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
            _scrollView.frame = CGRect(x: 0, y: 0, width: newValue.width, height: newValue.height)
        }
    }
    
    
    private var _multiImage:Bool = false
    var images:[Any] = []
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
                    _scrollView.contentSize = CGSize(width: frame.width * CGFloat(images.count + 2), height: frame.height)
                    //停留在第一张
                    _scrollView.contentOffset = CGPoint(x: frame.width, y: 0)
                    
                    if let last = images.last
                    {
                        addImageView(last, tag:-1)
                    }
                    
                    for i in 0..<images.count
                    {
                        if let item = images.valueAt(i)
                        {
                            addImageView(item, tag:i)
                        }
                    }
                    
                    if let first = images.first
                    {
                        addImageView(first, tag:images.count)
                    }
                }
                else
                {
                    _scrollView.contentSize = CGSize(width: frame.width, height: frame.height)
                    _scrollView.contentOffset = CGPoint(x: 0, y: 0)
                    addImageView(images[0], tag:0)
                }
                scrollViewDidEndScrolling()
            }//end count > 0
        }//end did set
    }
    
    private func createImageView() -> ImageLoader
    {
        let tapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(ScrollADImage.imageViewTapped(_:)))
        let imageView:ImageLoader = ImageLoader()
        imageView.clipsToBounds = true
        imageView.options.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.completeCallback = {imageView, readFromCache in
            if !readFromCache
            {
                imageView.alpha = 0
                UIView.animate(withDuration: 0.3, animations: {
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
        _scrollView.isPagingEnabled = true
        addSubview(_scrollView)
        
    }
    
    private func addImageView(_ image:Any, tag:Int)
    {
        let x:CGFloat = CGFloat(_multiImage ? tag + 1 : tag) * width
        let imageView:ImageLoader = _cacheImageViews.valueAt(_imageViews.count) ?? createImageView()
        imageView.frame = CGRect(x: x, y: 0, width: width, height: height)
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
                        _scrollView.contentOffset = CGPoint(x: CGFloat(_index) * imageWidth, y: 0)
                    }
                    if index > images.count
                    {
                        _index = 1
                        _scrollView.contentOffset = CGPoint(x: imageWidth, y: 0)
                    }
                }
                
                if let delegate = delegate , delegate.responds(to: #selector(ScrollADImageDelagate.scrollADImage(_:didScrollToIndex:)))
                {
                    delegate.scrollADImage?(self, didScrollToIndex: _multiImage ? _index - 1 : _index)
                }
            }
        }
        
    }
    
    private var _didEndScrolling:Bool = false
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        _didEndScrolling = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        scrollViewDidEndScrolling()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
        scrollViewDidEndScrolling()
    }
    
    @objc private func timeInterval()
    {
        if _multiImage && !_scrollView.isDragging
        {
            _scrollView.setContentOffset(CGPoint(x: CGFloat(_index + 1) * _scrollView.width, y: 0), animated: true)
        }
    }
    
    @objc private func imageViewTapped(_ recongnizer:UITapGestureRecognizer)
    {
        if let imageView:UIImageView = recongnizer.view as? UIImageView
        {
            let index:Int = imageView.tag
            if index >= 0 && index < images.count
            {
                if let delegate = delegate , delegate.responds(to: #selector(ScrollADImageDelagate.scrollADImage(_:didSelectIndex:)))
                {
                    delegate.scrollADImage?(self, didSelectIndex: index)
                }
            }
        }
        
    }
    
    
    
}//end class
