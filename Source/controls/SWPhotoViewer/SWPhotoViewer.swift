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
    //本地相册PHAsset
    var object:Any? {get set}
}

//加载进度条
protocol SWPhotoViewerProgressView:class
{
    static func create() -> SWPhotoViewerProgressView
    
    var progress:Double {get set}
    var view:UIView {get}
    func startAnimating()
    func stopAnimating()
}

extension SWPhotoViewerProgressView where Self:NSObject
{
    static func create() -> SWPhotoViewerProgressView
    {
        return Self()
    }
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
    
    //图片上单击
    func photoViewer(_ photoViewer: SWPhotoViewer, didSingleTapAtIndex index: Int)
    
    //图片上长按
    func photoViewer(_ photoViewer: SWPhotoViewer, didLongPressAtIndex index: Int)
}

extension SWPhotoViewerDelegate
{
    func progressViewForPhotoViewer(_ photoViewer: SWPhotoViewer) -> SWPhotoViewerProgressView?
    {
        return nil
    }
    
    func photoViewer(_ photoViewer: SWPhotoViewer, didScrollToIndex index: Int)
    {
        
    }
    
    func photoViewer(_ photoViewer: SWPhotoViewer, didSingleTapAtIndex index: Int)
    {
        
    }
    
    func photoViewer(_ photoViewer: SWPhotoViewer, didLongPressAtIndex index: Int)
    {
        
    }
}

class SWPhotoViewer: UIView,UICollectionViewDataSource,UICollectionViewDelegate,SWPhotoViewerCellDelegate
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
    private var _layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    
    var backgroundView: UIView = UIView()
    
    private var _collectionView:UICollectionView?
    //private var _tableView:UITableView = UITableView()
    
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
            let newSize = newValue.size
            let newFrame:CGRect = CGRect(x: 0, y: 0, width: newValue.width + grid, height: newValue.height)
            _layout.itemSize = CGSizeMake(newSize.width + grid, newSize.height)
            _collectionView?.frame = newFrame
            _collectionView?.setCollectionViewLayout(_layout, animated: false)
            backgroundView.frame = newFrame
            
            
            super.frame = newValue
            
            
            //_tableView.frame = CGRect(x: 0, y: 0, width: newValue.width + grid, height: newValue.height)
            //_tableView.rowHeight = width + grid
        }
    }
    
    //图片打开前的位置及大小
    private var _startFrame:CGRect?
    func showFromIndex(_ index:Int, rect:CGRect? = nil)
    {
        let imagesCount:Int = delegate?.numberOfPhotosInPhotoViewer(self) ?? 0
        _startIndex = max(0, min(index, imagesCount - 1))
        _index = _startIndex
        if rect != nil
        {
            _startFrame = rect
            _animatedFromStartFrameFlag = false
        }
        //_tableView.reloadRows(at: [IndexPath(row: _startIndex, section: 0)], with: .none)
        let indexPath = IndexPath(row: _startIndex, section: 0)
        _collectionView?.reloadItems(at: [indexPath])
        _collectionView?.scrollToItem(at: indexPath, at: .left, animated: false)
    }
    
    func reloadData()
    {
        //_tableView.reloadData()
        _collectionView?.reloadData()
    }
    
    func dismiss()
    {
        if let imagesCount = delegate?.numberOfPhotosInPhotoViewer(self) , imagesCount > 0 && _index >= 0 && _index < imagesCount
        {
            
            //if let cell = _tableView.cellForRow(at: IndexPath(row: _index, section: 0)) as? SWPhotoViewerCell
            if let cell = _collectionView?.cellForItem(at: IndexPath(row: _index, section: 0)) as? SWPhotoViewerCell
            {
                let targetFrame:CGRect? = _index == _startIndex ? _startFrame : nil
                cell.dismiss(targetFrame)
            }
        }
        
    }
    
    private var _progressViewClass:AnyClass?
    func registerClassForProgressView(_ classType: AnyClass)
    {
        _progressViewClass = classType
    }
    
    private var _photoFetcherClass:AnyClass?
    func registerClassForPhotoFetcher(_ classType: AnyClass)
    {
        _photoFetcherClass = classType
    }
    
    private func createProgressView() -> SWPhotoViewerProgressView
    {
        var view:SWPhotoViewerProgressView?
        if let classType = _progressViewClass as? SWPhotoViewerProgressView.Type
        {
            view = classType.create()
        }
        return view ?? SWPhotoViewerDefaultProgressView()
    }
    
    private func createPhotoFetcher() -> SWPhotoViewerFetcher
    {
        var view:SWPhotoViewerFetcher?
        if let classType = _photoFetcherClass as? SWPhotoViewerFetcher.Type
        {
            view = classType.create()
        }
        return view ?? SWPhotoViewerDefaultFetcher()
    }
    
    private func setup()
    {
        //backgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(backgroundView)
        
        _layout.minimumInteritemSpacing = 0
        _layout.minimumLineSpacing = 0
        _layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        _layout.scrollDirection = .horizontal
        
        
        _collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: _layout)
        _collectionView?.backgroundColor = UIColor.clear
        _collectionView?.register(SWPhotoViewerCell.self, forCellWithReuseIdentifier: "SWPhotoViewerCell")
        _collectionView?.dataSource = self
        _collectionView?.delegate = self
        _collectionView?.isPagingEnabled = true
        _collectionView?.showsHorizontalScrollIndicator = false
        _collectionView?.showsVerticalScrollIndicator = false
        addSubview(_collectionView!)
        
        let a = frame
        frame = a
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return delegate?.numberOfPhotosInPhotoViewer(self) ?? 0
    }
    
    private var _cacheCell:[Int:Bool] = [:]
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell:SWPhotoViewerCell? = collectionView.dequeueReusableCell(withReuseIdentifier: "SWPhotoViewerCell", for: indexPath) as? SWPhotoViewerCell
        
        let tag:Int = cell?.hashValue ?? 0
        if _cacheCell[tag] == nil
        {
            _cacheCell[tag] = true
            cell?.progressView = createProgressView()
            cell?.fetcher = createPhotoFetcher()
            cell?.delegate = self
        }
        
        cell?.size = bounds.size
        cell?.indexPath = indexPath
        let imagesCount:Int = delegate?.numberOfPhotosInPhotoViewer(self) ?? 0
        let index:Int = indexPath.row
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
        
        
        return cell ?? SWPhotoViewerCell(frame: _collectionView?.frame ?? .zero)
    }
    
    
    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
//    {
//        return delegate?.numberOfPhotosInPhotoViewer(self) ?? 0
//    }
    
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
//    {
//        let identifier:String = "SWPhotoViewerCell"
//        var cell:SWPhotoViewerCell? = tableView.dequeueReusableCell(withIdentifier: identifier) as? SWPhotoViewerCell
//        if cell == nil
//        {
//            cell = SWPhotoViewerCell(style: UITableViewCellStyle.default, reuseIdentifier: identifier)
//            cell?.contentView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI) / 2)
//            //cell?.progressView = delegate?.progressViewForPhotoViewer(self) ?? SWPhotoViewerDefaultProgressView()
//            cell?.progressView = createProgressView()
//            cell?.fetcher = createPhotoFetcher()
//        }
//        cell?.size = bounds.size
//        cell?.indexPath = indexPath
//        cell?.delegate = self
//        let imagesCount:Int = delegate?.numberOfPhotosInPhotoViewer(self) ?? 0
//        let index:Int = indexPath.row
//        if index >= 0 && index < imagesCount
//        {
//            if _startFrame != nil && index == _startIndex && !_animatedFromStartFrameFlag
//            {
//                cell?.startFrame = _startFrame
//                _animatedFromStartFrameFlag = true
//            }
//            else
//            {
//                cell?.startFrame = nil
//            }
//            cell?.photo = delegate?.photoViewer(self, photoAtIndex: index)
//        }
//        return cell!
//    }
    
    func photoViewerCell(_ cell:SWPhotoViewerCell, didSingleTapAtIndexPath indexPath: IndexPath)
    {
        delegate?.photoViewer(self, didSingleTapAtIndex: indexPath.row)
    }
    
    func photoViewerCell(_ cell:SWPhotoViewerCell, didLongPressAtIndexPath indexPath: IndexPath)
    {
        delegate?.photoViewer(self, didLongPressAtIndex: indexPath.row)
    }
    
    private func scrollViewDidEndScrolling(_ scrollView: UIScrollView)
    {
        if !_didEndScrolling
        {
            _didEndScrolling = true
            
            let contentOffset:CGPoint = scrollView.contentOffset;
            let imageWidth:CGFloat = scrollView.width
            let index:Int = Int(contentOffset.x / imageWidth)
            if index != _index && index >= 0
            {
                _index = index
                delegate?.photoViewer(self, didScrollToIndex: _index)
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
        scrollViewDidEndScrolling(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
        scrollViewDidEndScrolling(scrollView)
    }
    
    
}
