//
//  SWAVPlayer.swift
//  SimplePlayer
//
//  Created by linhan on 2016/12/8.
//  Copyright © 2016年 linhan. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol SWAVPlayerDelegate:NSObjectProtocol
{
    func playerStartLoad(_ player:SWAVPlayer)
    func playerPlayError(_ player:SWAVPlayer, error:NSError)
    //初步加载完成，准备播放
    func playerReadyToPlay(_ player:SWAVPlayer, duration:Double)
    func playerPlayProgress(_ player:SWAVPlayer, progress:Double)
    func playerPause(_ player:SWAVPlayer)
    func playerPlay(_ player:SWAVPlayer)
    func playerBufferEnough(_ player:SWAVPlayer)
    func playerBufferEmpty(_ player:SWAVPlayer)
    func playerDidFinishPlaying(_ player: SWAVPlayer)
}

extension SWAVPlayerDelegate
{
    func playerStartLoad(_ player:SWAVPlayer){}
    func playerPlayError(_ player:SWAVPlayer, error:NSError){}
    //初步加载完成，准备播放
    func playerReadyToPlay(_ player:SWAVPlayer, duration:Double){}
    func playerPlayProgress(_ player:SWAVPlayer, progress:Double){}
    func playerPause(_ player:SWAVPlayer){}
    func playerPlay(_ player:SWAVPlayer){}
    func playerBufferEnough(_ player:SWAVPlayer){}
    func playerBufferEmpty(_ player:SWAVPlayer){}
    func playerDidFinishPlaying(_ player: SWAVPlayer){}
}

class SWAVPlayer:NSObject
{
    weak var delegate:SWAVPlayerDelegate?
    
    //缓冲区大小。可设置(单位为秒)，默认为0.1秒
    var bufferTime:TimeInterval = 0.5
    
    private let URLNullError = NSError(domain: "SWAVPlayer", code: 1, userInfo: nil)
    private let URLInvalidError = NSError(domain: "SWAVPlayer", code: 2, userInfo: nil)
    
    private var _url:URL?
    fileprivate var _playerDisposed:Bool = false
    
    private var _timeObserver:Any?
    
    private var _playerItem:AVPlayerItem?
    
    //当前已播放时间
    private var _currentTime:Double = 0
    
    //总时长
    private var _duration:Double = 0
    
    private var _timeScale:Int32 = 0
    
    private let MaxRetryLoadTimes:Int = 3
    
    private var _retryLoadTimes:Int = 0
    
    private var _played:Bool = false
    private var _playDidEnd:Bool = false
    
    private var _playStatus:SWAVPlayStatus = .play
    
    private var _player:AVPlayer?
    
    deinit
    {
        print("SWAVPlayer DEINIT")
        dispose()
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK ============================================================================================
    //==============================           Getter And Setter        ===============================
    //=================================================================================================
    
    
    //当前是否处于播放状态
    var playing:Bool
    {
        var value:Bool = false
        //不在播放状态下，rate为0，正常播放情况下，rate为1
        if let rate = _player?.rate , rate == 1
        {
            value = true
        }
        return value
    }
    
    private var _readyToPlay:Bool = false
    var readyToPlay:Bool{
        return _readyToPlay
    }
    
    //是否已经开始播放
    var played:Bool
    {
        return _played
    }
    
    //缓冲是否足够
    var bufferEnough:Bool
    {
        return _bufferEnough ?? false
    }
    
    var duration: Double{
        return _duration
    }
    
    var currentTime:Double{
        return _currentTime
    }
    
    var playStatus:SWAVPlayStatus{
        return _playStatus
    }
    
    //MARK ============================================================================================
    //==============================            Public Method           ===============================
    //=================================================================================================
    
    func dispose()
    {
        _playerDisposed = false
        playerDispose()
    }
    
    //加载视频并进行播放
    func load(urlString url:String)
    {
        if url == ""
        {
            delegate?.playerPlayError(self, error: URLNullError)
            return
        }
        
        if let aURL = URL(string:url)
        {
            load(url: aURL)
        }
        else
        {
            delegate?.playerPlayError(self, error: URLInvalidError)
        }
    }
    
    func load(url:URL)
    {
        playerReset()
        
        if _url != url
        {
            _retryLoadTimes = 0
            _url = url
        }
        
        let asset:AVURLAsset = AVURLAsset(url:url)
        let playerItem:AVPlayerItem = AVPlayerItem(asset: asset)
        playerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEndNotify), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        //关联播放器和屏幕
        _player = AVPlayer(playerItem: playerItem)
        monitoringPlayback(playerItem)
        _playerItem = playerItem
        
        _playStatus = .play
        _played = true
        delegate?.playerStartLoad(self)
    }
    
    //跳转到指定时间进行播放(以秒为单位)
    func seek(to time:Double)
    {
        _currentTime = min(max(time, 0), _duration)
        let time:CMTime = CMTimeMakeWithSeconds(_currentTime, _timeScale)
        if let playerItem = _playerItem, playerItem.status == .readyToPlay
        {
            _player?.seek(to: time)
            play()
        }
    }
    
    //重播
    func replay()
    {
        if let playerItem = _playerItem, playerItem.status == .readyToPlay
        {
            _player?.seek(to: CMTimeMakeWithSeconds(0, _timeScale))
            play()
        }
    }
    
    //暂停
    func pause()
    {
        _player?.pause()
        _playStatus = .pause
        delegate?.playerPause(self)
    }
    
    //恢复播放
    func play()
    {
        if _played
        {
            _player?.play()
        }
        _playStatus = .play
        delegate?.playerPlay(self)
    }
    
    private func playerReset()
    {
        _playerDisposed = false
        playerDispose()
        _played = false
        _currentTime = 0
        _duration = 0
        _playStatus = .play
        _playDidEnd = false
        _bufferEnough = false
        _readyToPlay = false
    }
    
    //播放器释放
    fileprivate func playerDispose()
    {
        if !_playerDisposed
        {
            print("------dispose")
            
            _playerDisposed = true
            
            if let playerItem = _playerItem
            {
                playerItem.removeObserver(self, forKeyPath: "status")
                playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
                _playerItem = nil
            }
            
            if let timeObserver = _timeObserver
            {
                _player?.removeTimeObserver(timeObserver)
                _timeObserver = nil
            }
            _player?.pause()
            _player = nil
        }
    }
    
    private func monitoringPlayback(_ playItem:AVPlayerItem)
    {
        _timeObserver = _player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: DispatchQueue.global(priority: .default), using: {[weak self] time in
            
            //每隔1s执行一次 刷新进度
            let currentTime:CMTime  = playItem.currentTime()
            //总时间
            let duration:CMTime  = playItem.duration
            let progress:Double = (CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(duration)).numberValue
            
            if let strongSelf = self
            {
                strongSelf._currentTime = Double(currentTime.value) / Double(currentTime.timescale)
                DispatchQueue.main.async {
                    strongSelf.setProgress(progress)
                }
            }
        })
    }
    
    //设置当前进度(progress的值从0到1)
    private func setProgress(_ progress:Double)
    {
        delegate?.playerPlayProgress(self, progress: progress)
    }
    
    //获取缓冲
    private func fetchBufferStates() -> Bool
    {
        let available:TimeInterval = availableDuration()
        return ((_duration - available > bufferTime && available - _currentTime > bufferTime) || (_duration - available < 1 && available > _currentTime))
    }
    
    //获取缓冲可播放时长
    private func availableDuration() -> TimeInterval
    {
        guard let _ = _player,let playerItem = _playerItem else{
            return 0
        }
        return VideoUtil.getAvailableDuration(playerItem)
    }
    
    //开始准备播放
    private func statusReadyToPlay()
    {
        _readyToPlay = true
        if let player = _player,
           let currentItem = player.currentItem
        {
            //总时间
            let duration:CMTime = currentItem.duration
            _duration = CMTimeGetSeconds(duration).numberValue
            _timeScale = duration.timescale
            delegate?.playerReadyToPlay(self, duration: _duration)
        }
    }
    
    fileprivate func playToEnd()
    {
        delegate?.playerDidFinishPlaying(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        guard let playerItem = object as? AVPlayerItem , playerItem == _playerItem else
        {
            return
        }
        if keyPath == "status"
        {
            if playerItem.status == AVPlayerItemStatus.readyToPlay
            {
                print("playerItem.status readyToPlay")
                statusReadyToPlay()
            }
            else if playerItem.status == AVPlayerItemStatus.failed
            {
                if _retryLoadTimes < MaxRetryLoadTimes
                {
                    _retryLoadTimes += 1
                    if let url = _url
                    {
                        load(url:url)
                    }
                }
                else
                {
                    delegate?.playerPlayError(self, error: URLInvalidError)
                }
            }
        }
        else if keyPath == "loadedTimeRanges"
        {
            //当有足够缓冲时进行播放
            let enough:Bool = fetchBufferStates()
            _bufferEnough = enough
            
            if enough
            {
                if _playStatus == .play
                {
                    _player?.play()
                }
            }
            else
            {
                _player?.pause()
            }
            
        }//end of keyPath
        
    }
    
    private var _bufferEnough:Bool?{
        didSet{
            if let enough = _bufferEnough,enough != oldValue
            {
                enough ? delegate?.playerBufferEnough(self) : delegate?.playerBufferEmpty(self)
            }
        }
    }
    
    //MARK ============================================================================================
    //==============================               Selector             ===============================
    //=================================================================================================
    
    @objc private func moviePlayDidEndNotify()
    {
        playToEnd()
    }
    
    
    
}

class SWVideoPlayer:SWAVPlayer
{
    private var _playerLayer:AVPlayerLayer?
    private var _container:UIView
    
    init(container:UIView)
    {
        _container = container
        super.init()
    }
    
    deinit
    {
        print("SWVideoPlayer DEINIT")
    }
    
    private func setup()
    {
        _playerLayer = AVPlayerLayer()
        _playerLayer?.frame = _container.bounds
        _container.layer.addSublayer(_playerLayer!)
    }
    
    override fileprivate func playerDispose()
    {
        if !_playerDisposed
        {
            super.playerDispose()
            _playerLayer?.player = nil
        }
    }
}



enum SWAVPlayStatus:Int
{
    case play
    case pause
    case buffer
}
