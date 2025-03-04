//
//  PopBaseView.swift
//  minghaimuyuan
//

import RxSwift
import UIKit

class PopBaseView: BaseView {
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hex: "#000000")
        label.font = .fontMedium(fontSize: 17)
        return label
    }()

    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor(hex: "#000000"), for: .normal)
        button.titleLabel?.font = .fontMedium(fontSize: 17)
        return button
    }()
    
    lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle("确定", for: .normal)
//        button.setTitleColor(kMainColor, for: .normal)
        button.titleLabel?.font = .fontMedium(fontSize: 17)
        return button
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        
        setupBaseView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupBaseView() {
        
        addSubview(titleLabel)
        titleLabel.whc_CenterX(0)
            .whc_Top(20)
            .whc_Height(24)
            .whc_WidthAuto()
        
        let lineH = UIView()
        lineH.backgroundColor = UIColor(white: 0.2, alpha: 0.2)
        addSubview(lineH)
        lineH.whc_Bottom(42)
            .whc_Left(0)
            .whc_Right(0)
            .whc_Height(0.5)
        
        let lineV = UIView()
        lineV.backgroundColor = UIColor(white: 0.2, alpha: 0.2)
        addSubview(lineV)
        lineV.whc_CenterX(0)
            .whc_Top(0, toView: lineH)
            .whc_Bottom(0)
            .whc_Width(0.5)
        
        addSubview(cancelButton)
        cancelButton.whc_Bottom(0)
            .whc_Height(42)
            .whc_Right(0, toView: lineV)
            .whc_Left(0)
        
        addSubview(confirmButton)
        confirmButton.whc_Bottom(0)
            .whc_Left(0, toView: lineV)
            .whc_Right(0)
            .whc_Height(42)
        
    }
}
