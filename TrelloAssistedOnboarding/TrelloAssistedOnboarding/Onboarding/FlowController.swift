//
//  FlowController.swift
//  Trellis
//
//  Created by Andrew Frederick on 4/17/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit
import RxSwift

final class FlowController: NSObject, UINavigationControllerDelegate {

    @objc let navVC = UINavigationController()
    let disposeBag = DisposeBag()

    override init() {
        super.init()
        
        let pickerVC = BoardTemplatePickerViewController(self)
        self.navVC.delegate = self
        self.navVC.pushViewController(pickerVC, animated: false)
    }
    
    func showBoard(_ boardTemplate: BoardTemplate) {
        let viewModel = OnboardingViewModel(boardTemplate: boardTemplate)
        let onboardingVC = OnboardingViewController(viewModel: viewModel)

        // This listens to the bindFlow Maybe from the VC, which will give it an Output containing flow observables.
        onboardingVC.rx
            .bindFlow
            .flatMap { $0.createBoard }
            .subscribe(onSuccess: { [weak self] (board) in
                guard let self = self else { return }
                self.goToTrello(board: board)
            })
            .disposed(by: self.disposeBag)


        self.navVC.navigationItem.isAccessibilityElement = true
        self.navVC.interactivePopGestureRecognizer?.isEnabled = false
        self.navVC.pushViewController(onboardingVC, animated: true)
    }
    
    func goToTrello(board: BoardTemplate.Board? = nil) {
        self.navVC.presentingViewController?.dismiss(animated: true, completion: nil)

    }

    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return (UIDevice.current.userInterfaceIdiom == .pad) ? .all : .portrait
    }
    
}
