import UIKit
import ZFPlayer

//自动播放最大重试次数
fileprivate let kMaxRetryCount: Int = 5

fileprivate let backLeft: CGFloat = kSafeAreaLeftWidth+60
fileprivate let backTop: CGFloat = 30
fileprivate let toolbarBtm: CGFloat = 25
fileprivate let toolbarHeight: CGFloat = 36


/// 播放器控制视图
class PlayerControlView: UIView, ZFPlayerMediaControl {
    
    /// 播放器（ZFPlayerMediaControl协议属性）
    weak var player: ZFPlayerController?
    
    /// 底部进度条（外部引用）
    weak var bottomProgress: ZFSliderView?
    
    var viewWillChangeBlock: ((Bool)->())?
    var playResultBlock: ((Bool)->())?
    var playbackProgressCallback: ((_ currentTime: Int, _ totalTime: Int)->())?

    // 是否手动暂停中
    var isManuallyPausing: Bool = false
    // 当前重试次数
    var curRetryCount: Int = 0

    // 是否上报过视频播放
    var isReportedPlay: Bool = false
    // 记录视频prepare时间戳
    var prepareTimeStamp: TimeInterval?
    
    // `toolView`是否加入了当前视图
    var isToolViewAddedTo: Bool {
        var exist = false
        for (_, subview) in self.allSubviews().enumerated() {
            if subview.tag == PlayerToolView.viewTag {
                exist = true
                break
            }
        }
        return exist
    }
    
    var sumTime: TimeInterval?
    
    /// 中间播放按钮
    lazy var playOrPauseBtn: UIButton = {
        let button = UIButton(type: .custom)
//        button.setImage(ThemeGuide.Icons.Common.video_play, for: .normal)
        return button
    }()
    
    /// 加载loading
    lazy var activity: ZFSpeedLoadingView = {
        let activity = ZFSpeedLoadingView()
        return activity
    }()
    
    /// 加载失败按钮
    lazy var failBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("加载失败", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.fontRegular(fontSize: 14)
        button.backgroundColor = .init(white: 1, alpha: 0.5)
        button.isHidden = true
        return button
    }()
    
    /// 快进/快退视图
    lazy var fastView: PlayerFastView = {
        let view = PlayerFastView()
        view.isHidden = true
        return view
    }()
    
    /// 底部工具栏
    lazy var toolView: PlayerToolView = {
        let view = PlayerToolView()
        view.tag = PlayerToolView.viewTag
        view.dataSource = self
        view.delegate = self
        return view
    }()
    
    /// 横屏返回按钮
    var landScapeBackButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage()/*R.image.comment_close_btn()*/, for: .normal)
        button.setImage(UIImage()/*R.image.comment_close_btn()*/, for: .highlighted)
        button.isHidden = true
        return button
    }()
    
    private var disposeBag = DisposeBag()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true

        addSubview(playOrPauseBtn)
        addSubview(activity)
        addSubview(failBtn)
        addSubview(fastView)
        addSubview(landScapeBackButton)

        resetControlView()
        
        // 中间播放按钮点击
        playOrPauseBtn.rx.tap
            .subscribe { [weak self] _ in
                self?.togglePlayOrPause()
            }.disposed(by: disposeBag)
        
        // 加载失败点击
        failBtn.rx.tap
            .subscribe { [weak self] _ in
                debugPrint("重试点击")
                self?.player?.currentPlayerManager.reloadPlayer()
            }.disposed(by: disposeBag)
        
        // 横屏返回按钮点击
        landScapeBackButton.rx.tap
            .subscribe { [weak self] _ in
                self?.player?.enterFullScreen(false, animated: true)
            }.disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        playOrPauseBtn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        playOrPauseBtn.center = self.center
        
        activity.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        activity.zf_centerX = self.zf_centerX
        activity.zf_centerY = self.zf_centerY + 10
        
        let failTitleSize = TTReLayoutButton.getTheSizeOfTitle(title: (failBtn.titleLabel?.text!)!, font: (failBtn.titleLabel?.font)!)
        failBtn.frame = CGRect(x: 0, y: 0, width: failTitleSize.width+40, height: 50)
        failBtn.center = self.center
        
        fastView.frame = CGRect(x: 0, y: 0, width: PlayerFastView.viewWidth, height: PlayerFastView.viewHeight)
        fastView.center = self.center

        if self.isToolViewAddedTo {
            landScapeBackButton.frame = CGRect(x: backLeft, y: backTop, width:40, height:40)

            self.toolView.frame = CGRect(x: backLeft, y: self.bounds.size.height-toolbarBtm-toolbarHeight, width: self.bounds.size.width-backLeft*2, height: toolbarHeight)
        }
    }
    
    public func addToolViewToSelf() {
        if !self.isToolViewAddedTo {
            self.addSubview(toolView)

            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    public func removeToolViewFromSelf() {
        if self.isToolViewAddedTo {
            self.toolView.removeFromSuperview()
        }
    }
    
    public func showCoverURL(coverUrl: String, fullScreenMode: ZFFullScreenMode) {
        resetControlView()
        layoutIfNeeded()
        setNeedsLayout()
        player?.orientationObserver.fullScreenMode = fullScreenMode
        player?.currentPlayerManager.view.coverImageView.setImage(withURL: URL(string: coverUrl), placeholderImage: UIImage(color: .black))
    }
    
    public func togglePlayOrPause() {
        playOrPauseBtn.isSelected = !playOrPauseBtn.isSelected
        toolView.playOrPauseBtn.isSelected = playOrPauseBtn.isSelected
        checkPlayOrPauseBtnHidden()
        
        if playOrPauseBtn.isSelected {
            isManuallyPausing = false
            player?.currentPlayerManager.play()
        } else {
            isManuallyPausing = true
            player?.currentPlayerManager.pause()
        }
    }
    
    @objc private func toggleDecorationViewHidden() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let `self` = self else { return }
            if self.landScapeBackButton.y != -toolbarHeight {
                self.landScapeBackButton.y = -toolbarHeight
                self.toolView.y = self.bounds.size.height
            } else {
                self.landScapeBackButton.y = backTop
                self.toolView.y = self.bounds.size.height-toolbarBtm-toolbarHeight
            }
        }
    }
    
    private func checkShowDecorationView() {
        if self.landScapeBackButton.y != backTop {
            self.landScapeBackButton.y = backTop
            self.toolView.y = self.bounds.size.height-toolbarBtm-toolbarHeight
        }
    }
    
    public func updatePlayOrPauseButtonState() {
        guard let player = player else { return }
        playOrPauseBtn.isSelected = player.currentPlayerManager.isPlaying
        toolView.playOrPauseBtn.isSelected = playOrPauseBtn.isSelected
        checkPlayOrPauseBtnHidden()
    }
    
    private func playBtnSelectedState(selected: Bool) {
        playOrPauseBtn.isSelected = selected
        toolView.playOrPauseBtn.isSelected = playOrPauseBtn.isSelected
        checkPlayOrPauseBtnHidden()
    }
    
    private func checkPlayOrPauseBtnHidden() {
        playOrPauseBtn.isHidden = playOrPauseBtn.isSelected
    }
    
    private func resetControlView() {
        playOrPauseBtn.isSelected = true
        toolView.resetView()
        checkPlayOrPauseBtnHidden()
        failBtn.isHidden = true
        bottomProgress?.value = 0
        bottomProgress?.bufferValue = 0
    }
    
    private func sliderValueChangingValue(value: Float, isForward forward: Bool) {
        guard let player = player else { return }

        /// 显示控制层
        checkShowDecorationView()
        
        self.fastView.fastProgressView.value = value
        self.fastView.isHidden = false
        self.fastView.alpha = 1
        if forward {
            self.fastView.fastImageView.image = UIImage(named: "ZFPlayer.bundle/ZFPlayer_fast_forward")
        } else {
            self.fastView.fastImageView.image = UIImage(named: "ZFPlayer.bundle/ZFPlayer_fast_backward")
        }
        guard let draggedTime = ZFUtilities.convertTimeSecond(Int(Float(player.totalTime)*value)) else {
            return
        }
        guard let totalTime = ZFUtilities.convertTimeSecond(Int(player.totalTime)) else {
            return
        }
        self.fastView.fastTimeLabel.text = "\(draggedTime) / \(totalTime)"
        /// 更新滑杆
        self.toolView.sliderValueChanged(value: value, currentTimeString: draggedTime)
        self.bottomProgress?.isdragging = true
        self.bottomProgress?.value = value
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideFastView), object: nil)
        perform(#selector(hideFastView), with: nil, afterDelay: 0.1)
        
        UIView.animate(withDuration: 0.4) { [weak self] in
            self?.fastView.transform = CGAffineTransform(translationX: forward ? 8 : -8, y: 0)
        }
    }
    
    @objc private func hideFastView() {
        UIView.animate(withDuration: 0.4) { [weak self] in
            self?.fastView.transform = .identity
            self?.fastView.alpha = 0
        } completion: {[weak self] _ in
            self?.fastView.isHidden = true
        }
    }
}

//MARK: - ZFPlayerMediaControl
extension PlayerControlView {
    
    /// 手势筛选，返回NO不响应该手势
    func gestureTriggerCondition(
        _ gestureControl: ZFPlayerGestureControl,
        gestureType: ZFPlayerGestureType,
        gestureRecognizer: UIGestureRecognizer,
        touch: UITouch) -> Bool
    {
        //let point = touch.location(in: self)
        guard let player = self.player else {
            debugPrint("播放器手势筛选，不响应")
            return false
        }

        if player.isSmallFloatViewShow && !player.isFullScreen && gestureType != .singleTap {
            debugPrint("播放器手势筛选，不响应")
            return false
        }
        if player.isFullScreen {
            /// 不禁用滑动方向
            player.disablePanMovingDirection = []
            if player.isLockedScreen && gestureType != .singleTap { //锁定屏幕方向后只相应tap手势
                debugPrint("播放器手势筛选，不响应")
                return false
            }
            debugPrint("播放器手势筛选，响应")
            return true
        }
        
        return false
    }
    
    /// 单击手势事件
    func gestureSingleTapped(_ gestureControl: ZFPlayerGestureControl) {
        /*guard let player = self.player else { return }
        
        if player.isSmallFloatViewShow && !player.isFullScreen {
            player.enterFullScreen(true, animated: true)
        }*/
        
        toggleDecorationViewHidden()
    }
    
    /// 双击手势事件
    func gestureDoubleTapped(_ gestureControl: ZFPlayerGestureControl) {
         togglePlayOrPause()
    }
    
    /// 开始滑动手势事件
    func gestureBeganPan(
        _ gestureControl: ZFPlayerGestureControl,
        panDirection direction: ZFPanDirection,
        panLocation location: ZFPanLocation)
    {
        if direction == .H {
            self.sumTime = self.player?.currentTime
        }
    }
    
    /// 滑动中手势事件
    func gestureChangedPan(
        _ gestureControl: ZFPlayerGestureControl,
        panDirection direction: ZFPanDirection,
        panLocation location: ZFPanLocation,
        withVelocity velocity: CGPoint)
    {
        if direction == .H {
            guard let player = player, player.totalTime > 0 else { return }
            guard var sumTime = self.sumTime else { return }
            if (velocity.x == 0) { return }
            
            // 每次滑动需要叠加时间
            sumTime += velocity.x / 200
            // 需要限定sumTime的范围
            if sumTime > player.totalTime {
                sumTime = player.totalTime
            }
            if sumTime < 0 {
                sumTime = 0
            }
            self.sumTime = sumTime
            
            var style = false
            if (velocity.x > 0) {
                style = true
            }
            if (velocity.x < 0) {
                style = false
            }
            
            self.sliderValueChangingValue(value: Float(sumTime/player.totalTime), isForward: style)
        }
    }
    
    /// 滑动结束手势事件
    func gestureEndedPan(
        _ gestureControl: ZFPlayerGestureControl,
        panDirection direction: ZFPanDirection,
        panLocation location: ZFPanLocation)
    {
        if direction == .H {
            guard let player = player, player.totalTime > 0 else { return }
            guard let sumTime = self.sumTime else { return }
            
            player.seek(toTime: sumTime, completionHandler: { [weak self] finished in
                guard let `self` = self else { return }
                debugPrint("seek完成")
                if finished {
                    debugPrint("seek到 \(sumTime) 位置")
                    self.toolView.sliderChangeEnded()
                    self.bottomProgress?.isdragging = false
                    player.currentPlayerManager.play()
                }
            })
            
            self.sumTime = 0
        }
    }
    
    /// 捏合手势事件，这里改变了视频的填充模式
    func gesturePinched(
        _ gestureControl: ZFPlayerGestureControl,
        scale: Float)
    {
        if scale > 1 {
            self.player?.currentPlayerManager.scalingMode = .aspectFill
        } else {
            self.player?.currentPlayerManager.scalingMode = .aspectFit
        }
    }
    
    /// 准备播放
    func videoPlayer(_ videoPlayer: ZFPlayerController, prepareToPlay assetURL: URL) {
        debugPrint("准备播放视频...")
        if !isReportedPlay {
            self.prepareTimeStamp = Date().timeIntervalSince1970
        }
    }
    
    /// 播放状态改变
    func videoPlayer(
        _ videoPlayer: ZFPlayerController,
        playStateChanged state: ZFPlayerPlaybackState)
    {
        if state == .playStatePlaying {
            debugPrint("播放状态改变: 播放中")
            self.playBtnSelectedState(selected: true)
            failBtn.isHidden = true
            /// 开始播放时候判断是否显示loading
            if videoPlayer.currentPlayerManager.loadState == .stalled {
                activity.startAnimating()
            } else if videoPlayer.currentPlayerManager.loadState == .stalled ||
                        videoPlayer.currentPlayerManager.loadState == .prepare {
                activity.startAnimating()
            }
            /// 重置重试计数
            curRetryCount = 0
        } else if state == .playStatePaused {
            debugPrint("播放状态改变: 暂停")
            
            func manuallyPauseHandle() {
                self.playBtnSelectedState(selected: false)
                /// 暂停的时候隐藏loading
                activity.stopAnimating()
                failBtn.isHidden = true
            }
            
            if isManuallyPausing { //手动暂停
                debugPrint("手动方式暂停!")
                manuallyPauseHandle()
            } else { //如果不是手动暂停，自动重试
                if curRetryCount < kMaxRetryCount {
                    curRetryCount += 1
                    debugPrint("重试播放，当前重试次数：\(curRetryCount)")
                    player?.currentPlayerManager.play()
                } else {
                    debugPrint("超过最大重试次数，不再重试!")
                    manuallyPauseHandle()
                }
            }
        } else if state == .playStatePlayFailed {
            debugPrint("播放状态改变: 失败")
            if curRetryCount < kMaxRetryCount {
                curRetryCount += 1
                debugPrint("重试加载播放器，当前重试次数：\(curRetryCount)")
                //player?.currentPlayerManager.reloadPlayer()
                player?.currentPlayerManager.play()
            } else {
                debugPrint("超过最大重试次数，不再重试!")
                activity.stopAnimating()
                failBtn.isHidden = false
            }
            
            if !isReportedPlay, let prepareTimeStamp = self.prepareTimeStamp {
                isReportedPlay = true
                
                debugPrint("上报视频首次播放结果: 失败")
//                FirebaseManager.shared.logPlayVideoEvent(url: videoPlayer.assetURL.absoluteString,
//                                                         result: .falseValue,
//                                                         prepareTimeStamp: prepareTimeStamp,
//                                                         totalTime: videoPlayer.totalTime) {
//                }
                
                playResultBlock?(false)
            }
        }
    }
    
    /// 加载状态改变
    func videoPlayer(
        _ videoPlayer: ZFPlayerController,
        loadStateChanged state: ZFPlayerLoadState)
    {
        if state == .prepare {
            debugPrint("加载状态改变: 111111")
        } else if state == .playthroughOK || state == .playable {
            debugPrint("加载状态改变: 222222")
            player?.currentPlayerManager.view.backgroundColor = .black
            
            if !isReportedPlay, let prepareTimeStamp = self.prepareTimeStamp {
                isReportedPlay = true
                
                debugPrint("上报视频首次播放结果: 成功")
//                FirebaseManager.shared.logPlayVideoEvent(url: videoPlayer.assetURL.absoluteString,
//                                                         result: .trueValue,
//                                                         prepareTimeStamp: prepareTimeStamp,
//                                                         totalTime: videoPlayer.totalTime) {
//                }
                
                playResultBlock?(true)
            }
        }
        if state == .stalled && videoPlayer.currentPlayerManager.isPlaying {
            debugPrint("加载状态改变: 333333")
            activity.startAnimating()
        } else if state == .stalled || state == .prepare && videoPlayer.currentPlayerManager.isPlaying {
            debugPrint("加载状态改变: 444444")
            activity.startAnimating()
        } else {
            debugPrint("加载状态改变: 555555")
            activity.stopAnimating()
        }
    }
    
    /// 播放进度改变回调
    func videoPlayer(
        _ videoPlayer: ZFPlayerController,
        currentTime: TimeInterval,
        totalTime: TimeInterval)
    {
        //debugPrint("播放进度改变回调，currentTime：\(currentTime)")
        
        if !toolView.slider.isdragging {
            toolView.updateTime(currentTime: ZFUtilities.convertTimeSecond(Int(currentTime)),
                                totalTime: ZFUtilities.convertTimeSecond(Int(totalTime)))
            toolView.slider.value = videoPlayer.progress
        }
        
        bottomProgress?.value = videoPlayer.progress
        
        playbackProgressCallback?(Int(currentTime), Int(totalTime))
    }
    
    /// 缓冲改变回调
    func videoPlayer(
        _ videoPlayer: ZFPlayerController,
        bufferTime: TimeInterval)
    {
        //debugPrint("缓冲改变回调，bufferTime：\(bufferTime)")

        if !toolView.slider.isdragging {
            toolView.slider.bufferValue = videoPlayer.bufferProgress
        }
        bottomProgress?.bufferValue = videoPlayer.bufferProgress
    }
    
    /// 视频大小改变
    func videoPlayer(
        _ videoPlayer: ZFPlayerController,
        presentationSizeChanged size: CGSize)
    {
        
    }
    
    /// 视频view即将旋转
    func videoPlayer(
        _ videoPlayer: ZFPlayerController,
        orientationWillChange observer: ZFOrientationObserver)
    {
        debugPrint("视频view即将旋转，isFullScreen：\(videoPlayer.isFullScreen)")
        
        if videoPlayer.isFullScreen {
            landScapeBackButton.isHidden = false
            
            self.addToolViewToSelf()
            self.toolView.fullScreenBtn.isHidden = true
        } else {
            landScapeBackButton.isHidden = true

            self.removeToolViewFromSelf()
            self.toolView.fullScreenBtn.isHidden = false
        }
        
        self.viewWillChangeBlock?(videoPlayer.isFullScreen)
    }
    
    /// 视频view已经旋转
    func videoPlayer(
        _ videoPlayer: ZFPlayerController,
        orientationDidChanged observer: ZFOrientationObserver)
    {
        layoutIfNeeded()
        setNeedsLayout()
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(toggleDecorationViewHidden), object: nil)
        if videoPlayer.isFullScreen {
            perform(#selector(toggleDecorationViewHidden), with: nil, afterDelay: 2.0)
        }
    }
    
    /// 锁定旋转方向
    func lockedVideoPlayer(
        _ videoPlayer: ZFPlayerController,
        lockedScreen locked: Bool)
    {
        
    }
    
}

// MARK: - PlayerToolViewDataSource
extension PlayerControlView: PlayerToolViewDataSource {

    /// 返回当前播放器
    func playerToolView(playerFor toolView: PlayerToolView) -> ZFPlayerController? {
        return self.player
    }

}

// MARK: - PlayerToolViewDataSource
extension PlayerControlView: PlayerToolViewDelegate {

    /// 播放/暂停按钮点击
    func playerToolView(playOrPauseTappedAt toolView: PlayerToolView) {
        self.togglePlayOrPause()
    }
    
    /// 滑块滑动开始
    func playerToolView(sliderTouchBegan toolView: PlayerToolView) {
        // 取消隐藏界面指令，避免在拖动滑动中界面隐藏了
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(toggleDecorationViewHidden), object: nil)
    }
    
    /// 滑块滑动中
    func playerToolView(sliderValueChanging toolView: PlayerToolView, value: Float, forward: Bool) {
        self.fastView.fastProgressView.value = value
        self.bottomProgress?.isdragging = true
        self.bottomProgress?.value = value
    }
    
    /// 滑块滑动结束
    func playerToolView(sliderValueChanged toolView: PlayerToolView, value: Float) {
        self.fastView.fastProgressView.value = value
        self.bottomProgress?.isdragging = false
        self.bottomProgress?.value = value
    }

}
