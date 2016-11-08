//
//  SWPhotoViewer.swift
//  uicomponetTest3
//
//  Created by linhan on 15/9/2.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit

protocol SWPVPhoto
{
    var largeImage:UIImage? {get set}
    var largeImageURL:String? {get set}
    var thumbImage:UIImage? {get set}
}

protocol SWPhotoViewerProgressView:class
{
    var progress:Double {get set}
    var view:UIView {get}
    func startAnimating()
    func stopAnimating()
}

class SWPhotoViewerDefaultProgressView:NSObject,SWPhotoViewerProgressView
{
    lazy private var _indicatorView:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    
    var progress:Double = 0
    
    var view:UIView{
        return _indicatorView
    }
    
    func startAnimating()
    {
        _indicatorView.startAnimating()
    }
    
    func stopAnimating()
    {
        _indicatorView.stopAnimating()
    }
}

/**
class SWPhotoViewerProgressView:UIView, SWPVProgressViewProtocol
{
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    var progress:Double? = 0
    
    func startAnimating()
    {
        fatalError("NSCoding not supported")
    }
    
    func stopAnimating()
    {
        
    }
}
**/
protocol SWPhotoViewerDelegate:class
{
    //照片总数
    func numberOfPhotosInPhotoViewer(_ photoViewer: SWPhotoViewer) -> Int
    
    //对应位置的照片
    func photoViewer(_ photoViewer: SWPhotoViewer, photoAtIndex index: Int) -> SWPVPhoto?
    
    //进度条
    func progressViewForPhotoViewer(_ photoViewer: SWPhotoViewer) -> SWPhotoViewerProgressView?
    
    //当前选中索引变化
    func photoViewer(_ photoViewer: SWPhotoViewer, didScrollToIndex index: Int)
    
    func photoViewer(_ photoViewer: SWPhotoViewer, didSingleTapAtIndex index: Int)
    
    //图片上长按
    func photoViewer(_ photoViewer: SWPhotoViewer, didLongPressAtIndex index: Int)
}

class SWPhotoViewer: UIView,UITableViewDelegate,UITableViewDataSource,SWPhotoViewerCellDelegate
{
    weak var delegate:SWPhotoViewerDelegate?
    
    //图片之间的间隙
    var grid:CGFloat = 20
    
    private var _startIndex:Int = 0
    
    //当前图片的索引
    private var _index:Int = 0
    
    //第一次打开的时从原始大小变化到自适应大小；是否已经变化过，如果变化过则不在变化
    private var _animatedFromStartFrameFlag:Bool = false
    
    private var _inited:Bool = false
    
    var backgroundView: UIView = UIView()
    
    private var _tableView:UITableView = UITableView()
    
    init()
    {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        //trace("DEINIT SWPhotoViewer")
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
            backgroundView.frame = newValue
            _tableView.frame = CGRect(x: 0, y: 0, width: newValue.width + grid, height: newValue.height)
            _tableView.rowHeight = width + grid
        }
    }
    
    //图片打开前的位置及大小
    private var _startFrame:CGRect?
    func showFromIndex(_ index:Int, rect:CGRect? = nil)
    {
        let imagesCount:Int = delegate?.numberOfPhotosInPhotoViewer(self) ?? 0
        _startIndex = max(0, min(index, imagesCount - 1))
        if rect != nil
        {
            _startFrame = rect
            _animatedFromStartFrameFlag = false
        }
        _tableView.reloadRows(at: [IndexPath(row: _startIndex, section: 0)], with: .none)
        updateContentOffset()
    }
    
    func reloadData()
    {
        _tableView.reloadData()
    }
    
    func dismiss()
    {
        if let imagesCount = delegate?.numberOfPhotosInPhotoViewer(self) , imagesCount > 0 && _index >= 0 && _index < imagesCount
        {
            if let cell = _tableView.cellForRow(at: IndexPath(row: _index, section: 0)) as? SWPhotoViewerCell
            {
                let targetFrame:CGRect? = _index == _startIndex ? _startFrame : nil
                cell.dismiss(targetFrame)
            }
        }
        
    }
    
    private func setup()
    {
        //backgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(backgroundView)
        
        _tableView.delegate = self
        _tableView.dataSource = self
        _tableView.bounces = true
        _tableView.showsVerticalScrollIndicator = false
        _tableView.transform = CGAffineTransform(rotationAngle: -CGFloat(M_PI) / 2)
        _tableView.frame = CGRect(x: 0, y: 0, width: width + grid, height: height)
        _tableView.isPagingEnabled = true
        _tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        _tableView.backgroundColor = UIColor.clear
        addSubview(_tableView)
    }
    
    //更新tableView的内容位置
    private func updateContentOffset()
    {
        let imagesCount:Int = delegate?.numberOfPhotosInPhotoViewer(self) ?? 0
        if _startIndex > -1 && _startIndex < imagesCount
        {
            _index = _startIndex
            _tableView.contentOffset = CGPoint(x: 0, y: CGFloat(_startIndex) * _tableView.width)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return delegate?.numberOfPhotosInPhotoViewer(self) ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let identifier:String = "SWPhotoViewerCell"
        var cell:SWPhotoViewerCell? = tableView.dequeueReusableCell(withIdentifier: identifier) as? SWPhotoViewerCell
        if cell == nil
        {
            cell = SWPhotoViewerCell(style: UITableViewCellStyle.default, reuseIdentifier: identifier)
            cell?.contentView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI) / 2)
            cell?.progressView = delegate?.progressViewForPhotoViewer(self) ?? SWPhotoViewerDefaultProgressView()
        }
        cell?.size = bounds.size
        cell?.indexPath = indexPath
        cell?.delegate = self
        let imagesCount:Int = delegate?.numberOfPhotosInPhotoViewer(self) ?? 0
        let index:Int = (indexPath as NSIndexPath).row
        if index >= 0 && index < imagesCount
        {
            if _startFrame != nil && index == _startIndex && !_animatedFromStartFrameFlag
            {
                cell?.startFrame = _startFrame
                _animatedFromStartFrameFlag = true
            }
            else
            {
                cell?.startFrame = nil
            }
            cell?.photo = delegate?.photoViewer(self, photoAtIndex: index)
        }
        return cell!
    }
    
    func photoViewerCell(_ cell:SWPhotoViewerCell, didSingleTapAtIndexPath indexPath: IndexPath)
    {
        delegate?.photoViewer(self, didSingleTapAtIndex: (indexPath as NSIndexPath).row)
    }
    
    func photoViewerCell(_ cell:SWPhotoViewerCell, didLongPressAtIndexPath indexPath: IndexPath)
    {
        delegate?.photoViewer(self, didLongPressAtIndex: (indexPath as NSIndexPath).row)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let contentOffset:CGPoint = scrollView.contentOffset;
        let imageWidth:CGFloat = _tableView.width
        let index:Int = Int(contentOffset.y / imageWidth)
        if index != _index && index >= 0
        {
            _index = index
            delegate?.photoViewer(self, didScrollToIndex: _index)
        }
    }
    
    
}
