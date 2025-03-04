import UIKit

import ZFPlayer

/// 数据源
protocol PlayerToolViewDataSource: AnyObject {
    /// 返回当前播放器
    func playerToolView(playerFor toolView: PlayerToolView) -> ZFPlayerController?
}

/// 代理
protocol PlayerToolViewDelegate: AnyObject {
    /// 播放/暂停按钮点击
    func playerToolView(playOrPauseTappedAt toolView: PlayerToolView)
    /// 滑块滑动开始
    func playerToolView(sliderTouchBegan toolView: PlayerToolView)
    /// 滑块滑动中
    func playerToolView(sliderValueChanging toolView: PlayerToolView, value: Float, forward: Bool)
    /// 滑块滑动结束
    func playerToolView(sliderValueChanged toolView: PlayerToolView, value: Float)
}


/// 播放器控制工具栏
class PlayerToolView: UIView {
    
    weak var dataSource: PlayerToolViewDataSource?
    weak var delegate: PlayerToolViewDelegate?
    
    /// 视图交互控制
    enum Interaction {
        // 所有控件可操作
        case normal
        // 所有子控件不响应手势
        case allUserInteractionDisable
        // 仅`playOrPauseBtn`控件响应手势
        case onlyPlayOrPauseUserInteractionEnable
    }
    var userInteraction: Interaction = .normal {
        didSet  {
            switch userInteraction {
                // 并且所有控件可操作
            case .normal:
                self.playOrPauseBtn.isEnabled = true
                self.slider.isUserInteractionEnabled = true
                self.slider.sliderBtn.isEnabled = true
                self.fullScreenBtn.isEnabled = true
                
                // 所有子控件不响应手势
            case .allUserInteractionDisable:
                self.playOrPauseBtn.isEnabled = false
                self.slider.isUserInteractionEnabled = false
                self.slider.sliderBtn.isEnabled = false
                self.fullScreenBtn.isEnabled = false
                
                // 仅`playOrPauseBtn`控件响应手势
            case .onlyPlayOrPauseUserInteractionEnable:
                self.playOrPauseBtn.isEnabled = true
                self.slider.isUserInteractionEnabled = false
                self.slider.sliderBtn.isEnabled = false
                self.fullScreenBtn.isEnabled = false
            }
        }
    }
    
    private var curTimeStr = "00:00"
    private var totalTimeStr = "00:00"

    private var disposeBag = DisposeBag()

    static var viewTag: Int {
        return 11111
    }
    
    lazy var playOrPauseBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage()/*R.image.memorial_toolbar_play()*/, for: .normal)
        button.setImage(UIImage()/*R.image.memorial_toolbar_pause()*/, for: .selected)
        button.isSelected = true
        return button
    }()
    
    lazy var slider: ZFSliderView = {
        let slider = ZFSliderView()
        slider.delegate = self
        slider.maximumTrackTintColor = .init(hex: "#d8d8d8", alpha: 1)
        slider.minimumTrackTintColor = .init(white: 1, alpha: 0.8)
        slider.bufferTrackTintColor = .white
        slider.setThumbImage(UIImage()/*R.image.memorial_toolbar_play()*/, for: .normal)
        slider.setThumbImage(UIImage()/*R.image.memorial_toolbar_play()*/, for: .disabled)
        slider.sliderHeight = 2
        return slider
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .fontMedium(fontSize: 12)
        label.textColor = .white
        label.text = "\(curTimeStr)/\(totalTimeStr)"
        return label
    }()
    
    lazy var fullScreenBtn: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(
            UIImage()/*R.image.comment_close_btn()*/,
            for: .normal
        )
        button.isHidden = true
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(playOrPauseBtn)
        addSubview(slider)
        addSubview(timeLabel)
        addSubview(fullScreenBtn)

        playOrPauseBtn.whc_Left(0)
            .whc_CenterY(0)
            .whc_WidthAuto()
            .whc_HeightAuto()
        slider.whc_Left(10, toView: playOrPauseBtn)
            .whc_Right(10, toView: timeLabel)
            .whc_CenterY(0)
            .whc_Height(18)
        timeLabel.whc_Right(10, toView: fullScreenBtn)
            .whc_CenterY(0)
            .whc_WidthAuto()
            .whc_HeightAuto()
        fullScreenBtn.whc_Right(0)
            .whc_CenterY(0)
            .whc_WidthAuto()
            .whc_HeightAuto()
        
        // 播放/暂停按钮点击
        playOrPauseBtn.rx.tap
            .subscribe { [weak self] _ in
                guard let `self` = self else { return }
                self.delegate?.playerToolView(playOrPauseTappedAt: self)
            }
            .disposed(by: disposeBag)
        
        // 全屏按钮点击
        fullScreenBtn.rx.tap
            .subscribe { [weak self] _ in
                guard let `self` = self else { return }
                guard let player = self.dataSource?.playerToolView(playerFor: self) else {
                    fatalError("Please implement the `dataSource` method!")
                }
                player.enterFullScreen(true, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public func resetView() {
        playOrPauseBtn.isSelected = true
        slider.value = 0
        slider.bufferValue = 0
        curTimeStr = "00:00"
        totalTimeStr = "00:00"
        timeLabel.text = "\(curTimeStr)/\(totalTimeStr)"
    }
    
    public func updateTime(currentTime: String, totalTime: String) {
        curTimeStr = currentTime
        totalTimeStr = totalTime
        
        timeLabel.text = "\(curTimeStr)/\(totalTimeStr)"
    }
    
    
    /// 调节播放进度slider和当前时间更新
    public func sliderValueChanged(value: Float, currentTimeString timeString: String) {
        curTimeStr = timeString
        timeLabel.text = "\(curTimeStr)/\(totalTimeStr)"
        
        slider.value = value
        slider.isdragging = true
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.slider.sliderBtn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }
    
    /// 滑杆结束滑动
    public func sliderChangeEnded() {
        slider.isdragging = false
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.slider.sliderBtn.transform = CGAffineTransform.identity
        }
    }
    
}

//MARK: - ZFSliderViewDelegate
extension PlayerToolView: ZFSliderViewDelegate {
    
    func sliderTouchBegan(_ value: Float) {
        guard let _ = self.dataSource?.playerToolView(playerFor: self) else { return }
        self.slider.isdragging = true
        self.delegate?.playerToolView(sliderTouchBegan: self)
    }
    
    func sliderValueChanged(_ value: Float) {
        guard let player = self.dataSource?.playerToolView(playerFor: self) else { return }
        if player.totalTime == 0 {
            self.slider.value = 0
            return
        }
        self.slider.isdragging = true

        let totalTime = player.totalTime
        let currentTime = totalTime*Double(value)
        self.updateTime(
            currentTime: ZFUtilities.convertTimeSecond(Int(currentTime)),
            totalTime: ZFUtilities.convertTimeSecond(Int(totalTime)))
        
        self.delegate?.playerToolView(sliderValueChanging: self, value: value, forward: self.slider.isForward)
    }
    
    func sliderTouchEnded(_ value: Float) {
        guard let player = self.dataSource?.playerToolView(playerFor: self) else { return }
        if player.totalTime > 0 {
            self.slider.isdragging = true
            self.delegate?.playerToolView(sliderValueChanging: self, value: value, forward: self.slider.isForward)
            player.seek(toTime: player.totalTime*Double(value), completionHandler: { [weak self] finished in
                guard let `self` = self else { return }
                debugPrint("seek完成")
                self.slider.isdragging = false
                if finished {
                    player.currentPlayerManager.play()
                    debugPrint("seek到 \(value) 位置")
                    self.delegate?.playerToolView(sliderValueChanged: self, value: value)
                }
            })
        } else {
            self.slider.isdragging = false
            self.slider.value = 0
        }
    }
    
    func sliderTapped(_ value: Float) {
        guard let player = self.dataSource?.playerToolView(playerFor: self) else { return }
        if player.totalTime > 0 {
            self.slider.isdragging = true
            player.seek(toTime: player.totalTime*Double(value)) {  [weak self] finished in
                guard let `self` = self else { return }
                debugPrint("seek完成")
                self.slider.isdragging = false
                if finished {
                    player.currentPlayerManager.play()
                    debugPrint("seek到 \(value) 位置")
                }
            }
        } else {
            self.slider.isdragging = false
            self.slider.value = 0
        }
    }
    
}
