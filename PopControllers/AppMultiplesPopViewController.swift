//
//  AppMultiplesPopViewController.swift
//  minghaimuyuan
//

import UIKit
import RxSwift


enum PopKinds {
    case createFamily
}

class AppMultiplesPopViewController: BaseViewController {
    
    var isTouchBackGroundDismiss: Bool = false
    
    init(viewModel: AppMultiplesPopViewModel, types: PopKinds) {
        super.init(nibName: nil, bundle: nil)
        self.popType = types
        self.viewModel = viewModel
        
        modalPresentationStyle = .custom
        AppControllerTransitioningManager.shared.popType = types
        transitioningDelegate = AppControllerTransitioningManager.shared
        isTouchBackGroundDismiss = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var popType: PopKinds = .createFamily
    
    private var viewModel: AppMultiplesPopViewModel!
    
    private let contentViewTag: Int = 1102
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tag = 1101
        view.backgroundColor = UIColor(white: 0.1, alpha: 0.2)
        
        setupViews()
        setupBindings()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if popType == .createFamily {
            view.endEditing(true)
        }
        if isTouchBackGroundDismiss {
            dismiss(animated: true)
        }
    }

    private func setupViews() {
        
        switch popType {
        case .createFamily:
            isTouchBackGroundDismiss = false
            
//            let contentView = PopCreateFamilyView()
//            contentView.tag = contentViewTag
//            contentView.titleLabel.text = "创建家庭"
//            view.addSubview(contentView)
//            contentView.whc_Center(0, y: 0)
//                .whc_Width(contentView.viewSize.width)
//                .whc_Height(contentView.viewSize.height)
            
        }
    }
    
    private func setupBindings() {
        
        switch popType {
        case .createFamily:
            break
        }
    }
}


