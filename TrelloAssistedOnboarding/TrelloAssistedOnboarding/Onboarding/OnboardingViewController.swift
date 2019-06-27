//
//  OnboardingViewController.swift
//  Trellis
//
//  Created by Lou Franco on 4/11/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// This View Controller is the main Mad Libs screen with the board/lists/cards in the background and an overlay view
/// that describes what you should do (and offers a button to do the step and a skip).
///
/// This class is in an MVVM relationship with OnboardingViewModel and they are connected with Rx. The general pattern
/// to follow with these two classes
///
/// 1. The VC should provide "input" events to the VM
/// 2. The VM should "transform" those inputs into "output" drivers
/// 3. The VC should connect the drivers directly to bindable outputs of its views
/// 4. The drivers coming from the VM should not need any further transformation (we have an exception for animations)
class OnboardingViewController: UIViewController {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let stylesheet = Stylesheet()

    let viewModel: OnboardingViewModel

    // MARK: - Views
    let boardView: BoardView
    var boardViewLeadingConstraint = NSLayoutConstraint()
    var boardViewBottomConstraint = NSLayoutConstraint()

    let rightNavForEditingButton = UIButton(type: .system)
    let rightNavForOverlaySkipButton = UIButton(type: .system)

    // Allow the Coordinator to listen to VC Flow requests from View Model (see Reactive extension below)
    struct Output {
        let createBoard: Maybe<BoardTemplate.Board>
    }
    fileprivate let bindFlowSubject: PublishSubject<Output> = PublishSubject()

    class CompactUI: SizeClassViewContainer, UI {
        let overlays: [OverlayView]
        var overlayLeadingConstraint = NSLayoutConstraint()
        var overlayHeightConstraints: [NSLayoutConstraint]

        init(_ viewModel: OnboardingViewModel) {
            let overlayTemplates = viewModel.board.overlays
            self.overlays = viewModel.overlaySteps.map { (overlayStep: OverlayStep) in
                OverlayView(step: overlayStep, overlayTemplate: overlayTemplates[overlayStep.rawValue], style: .bottomOverlay)
            }
            self.overlayHeightConstraints = viewModel.overlaySteps.map { _ in return NSLayoutConstraint() }
        }

        override var views: [UIView] { return self.overlays }
    }
    fileprivate var compactUI: CompactUI

    class RegularUI: SizeClassViewContainer, UI {
        let overlays: [OverlayView]

        init(_ viewModel: OnboardingViewModel) {
            let overlayTemplates = viewModel.board.overlays
            self.overlays = viewModel.overlaySteps.map { (overlayStep: OverlayStep) in
                OverlayView(step: overlayStep, overlayTemplate: overlayTemplates[overlayStep.rawValue], style: .sidebar)
            }
        }

        override var views: [UIView] { return self.overlays }
    }
    fileprivate var regularUI: RegularUI

    // MARK: - Rx
    private let disposeBag = DisposeBag()

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        self.boardView = BoardView(viewModel)
        self.compactUI = CompactUI(viewModel)
        self.regularUI = RegularUI(viewModel)

        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        constrainViews()
        configureFonts()
        bindUI()
        
        NotificationCenter.default.rx.notification(UIContentSizeCategory.didChangeNotification)
            .subscribe(onNext: { [weak self] _ in self?.configureFonts() })
            .disposed(by: self.disposeBag)
    }

    /// This function implements the VC part of the Rx MVVM pattern
    /// 1. Gather the input events (textfields changing, buttons tapped, etc)
    /// 2. Give them to the VM and have it transform them into output drivers
    /// 3. Bind the drivers to the view properties
    ///
    /// All logic about how Mad Libs progresses from step to step is in the VM.
    private func bindUI() {
        /******** Create the Input for the OnboardingViewModel and receive an Output to Drive UI elements ********/

        let boardNameTextField = boardView.nameTextField
        
        let boardNameTextOrEmpty = boardNameTextField.rx.text.orEmpty.asObservable()
        let boardNameEditingDidBegin = boardNameTextField.rx.controlEvent(.editingDidBegin).asObservable()
        let boardNameEditingChanged = boardNameTextField.rx.controlEvent(.editingChanged).asObservable()
        let boardNameEditingDidEnd = boardNameTextField.rx.controlEvent(.editingDidEnd).asObservable()
        let boardNameEditingDidEndOnExit = boardNameTextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
        
        let rightNavForOverlaySkipButtonTap = self.rightNavForOverlaySkipButton.rx.tap.asObservable()

        let boardNameOverlayGoButtonsTap = Observable.merge(self.compactUI.overlays[0].contentView.goButton.rx.tap.asObservable(),
                                                        self.regularUI.overlays[0].contentView.goButton.rx.tap.asObservable())
        let listNameOverlayGoButtonsTap = Observable.merge(self.compactUI.overlays[1].contentView.goButton.rx.tap.asObservable(),
                                                         self.regularUI.overlays[1].contentView.goButton.rx.tap.asObservable())
        let cardTitleOverlayGoButtonsTap = Observable.merge(self.compactUI.overlays[2].contentView.goButton.rx.tap.asObservable(),
                                                        self.regularUI.overlays[2].contentView.goButton.rx.tap.asObservable())
        let createBoardOverlayGoButtonsTap = Observable.merge(self.compactUI.overlays[3].contentView.goButton.rx.tap.asObservable(),
                                                        self.regularUI.overlays[3].contentView.goButton.rx.tap.asObservable(),
                                                        rightNavForOverlaySkipButtonTap)

        let boardNameOverlaySkipButtonsTap = Observable.merge(self.compactUI.overlays[0].contentView.skipButton.rx.tap.asObservable(),
                                                          self.regularUI.overlays[0].contentView.skipButton.rx.tap.asObservable(),
                                                          rightNavForOverlaySkipButtonTap)
        let listNameOverlaySkipButtonsTap = Observable.merge(self.compactUI.overlays[1].contentView.skipButton.rx.tap.asObservable(),
                                                             self.regularUI.overlays[1].contentView.skipButton.rx.tap.asObservable(),
                                                             rightNavForOverlaySkipButtonTap)
        let cardTitleOverlaySkipButtonsTap = Observable.merge(self.compactUI.overlays[2].contentView.skipButton.rx.tap.asObservable(),
                                                              self.regularUI.overlays[2].contentView.skipButton.rx.tap.asObservable(),
                                                              rightNavForOverlaySkipButtonTap)

        let rightNavForEditingButtonTap = self.rightNavForEditingButton.rx.tap.asObservable()

        let listNameTextFields = boardView.boardContentView.listViews.map { $0.nameTextField }
        // Grab all but the last list text field and set return key to Next
        listNameTextFields[0..<listNameTextFields.count - 1].forEach { textField in
            textField.returnKeyType = .next
        }
        
        let listViewModels = self.listViewModels(listNameTextFields)
        
        let traitCollection = self.rx.traitCollection.asObservable()
        let viewSize = self.rx.viewSize.asObservable()

        // We only make editable cards in the first list
        let cardTextFields = boardView.boardContentView.listViews[0].cardViews.map { $0.cardTitleTextField }

        // Grab all but the last card text field and set return key to Next
        cardTextFields[0..<cardTextFields.count - 1].forEach { textField in
            textField.returnKeyType = .next
        }
        let cardViewModels = self.cardViewModels(cardTextFields)
        
        // Permanently disable editing on the second list card text fields, as they are strictly for illustrative purposes and not editing
        let secondListCardTextFields = boardView.boardContentView.listViews[1].cardViews.map { $0.cardTitleTextField }
        secondListCardTextFields.forEach { $0.isEnabled = false }
        
        let output = viewModel.transform(OnboardingViewModel.Input(boardNameText: boardNameTextOrEmpty,
                                                                boardNameEditingDidBegin: boardNameEditingDidBegin,
                                                                boardNameEditingChanged: boardNameEditingChanged,
                                                                boardNameEditingDidEnd: boardNameEditingDidEnd,
                                                                boardNameEditingDidEndOnExit: boardNameEditingDidEndOnExit,
                                                                listViewModels: listViewModels,
                                                                cardViewModels: cardViewModels,
                                                                boardNameOverlayGoButtonsTap: boardNameOverlayGoButtonsTap,
                                                                listNameOverlayGoButtonsTap: listNameOverlayGoButtonsTap,
                                                                cardTitleOverlayGoButtonsTap: cardTitleOverlayGoButtonsTap,
                                                                createBoardOverlayGoButtonsTap: createBoardOverlayGoButtonsTap,
                                                                boardNameOverlaySkipButtonsTap: boardNameOverlaySkipButtonsTap,
                                                                listNameOverlaySkipButtonsTap: listNameOverlaySkipButtonsTap,
                                                                cardTitleOverlaySkipButtonsTap: cardTitleOverlaySkipButtonsTap,
                                                                rightNavForEditingButtonTap: rightNavForEditingButtonTap,
                                                                viewSize: viewSize,
                                                                traitCollection: traitCollection,
                                                                keyboardHeight: RxKeyboard.instance.visibleHeight))
        
        /* Board View */
        
        // Handle resetting board view content offset
        output.boardZeroContentOffset.drive(boardView.rx.zeroContentOffsetWithSpringAnimation).disposed(by: disposeBag)
        // Handle board view zoom state
        output.boardViewZoomOut.drive(boardView.rx.zoomOut).disposed(by: disposeBag)
        
        /* Board name */
        // Set the text field based on validation from view model
        output.boardNameDisplayText.drive(boardNameTextField.rx.text).disposed(by: disposeBag)
        // Handle what happens when the Name Board Go Button is tapped
        output.focusBoardNameTextField.drive(boardNameTextField.rx.isFirstResponder).disposed(by: disposeBag)
        // Handle the board name text field active border
        output.boardNameTextFieldShowActiveBorder.drive(boardNameTextField.rx.showBorder).disposed(by: disposeBag)
        // Handle the board name text field hint border
        output.boardNameTextFieldShowHintBorder.drive(boardNameTextField.rx.showHintBorder).disposed(by: disposeBag)
        // Handle the board name text field selecting all text when initially becoming first responder
        output.boardNameTextFieldSelectAllText.drive(boardNameTextField.rx.selectAll()).disposed(by: disposeBag)

        /* Overlays */
        // Move the first overlay to leading side when step progresses
        output.overlayLeadingConstraintConstant.drive(onNext: { [weak self] leadingConstant in
            self?.moveOverlay(leadingConstant: leadingConstant)
        }).disposed(by: disposeBag)
        
        // Disabling Go buttons
        output.boardNamingOverlayButtonEnabled.drive(self.compactUI.overlays[0].contentView.goButton.rx.isEnabled).disposed(by: disposeBag)
        output.boardNamingOverlayButtonEnabled.drive(self.regularUI.overlays[0].contentView.goButton.rx.isEnabled).disposed(by: disposeBag)
        output.listNamingOverlayButtonEnabled.drive(self.compactUI.overlays[1].contentView.goButton.rx.isEnabled).disposed(by: disposeBag)
        output.listNamingOverlayButtonEnabled.drive(self.regularUI.overlays[1].contentView.goButton.rx.isEnabled).disposed(by: disposeBag)
        output.cardNamingOverlayButtonEnabled.drive(self.compactUI.overlays[2].contentView.goButton.rx.isEnabled).disposed(by: disposeBag)
        output.cardNamingOverlayButtonEnabled.drive(self.regularUI.overlays[2].contentView.goButton.rx.isEnabled).disposed(by: disposeBag)

        // Handle the alpha of each overlay
        self.compactUI.overlays.forEach { overlay in
            output.overlayFadeAnimations(overlay.step).drive(onNext: { [weak self] alpha in
                self?.fadeInOutOverlay(overlay: overlay, alpha: alpha)
            }).disposed(by: self.disposeBag)
        }

        self.regularUI.overlays.forEach { overlay in
            output.overlayFadeAnimations(overlay.step).drive(onNext: { [weak self] alpha in
                self?.fadeInOutOverlay(overlay: overlay, alpha: alpha)
            }).disposed(by: self.disposeBag)
        }
        
        /* Compact/Regular UI */
        output.compactUIHidden.drive(self.compactUI.rx.isHidden).disposed(by: self.disposeBag)
        output.regularUIHidden.drive(self.regularUI.rx.isHidden).disposed(by: self.disposeBag)
        output.boardLeadingConstant.drive(self.boardViewLeadingConstraint.rx.constant).disposed(by: self.disposeBag)
        output.boardBottomConstant.drive(self.boardViewBottomConstraint.rx.constant).disposed(by: self.disposeBag)
        
        // Bindings for each list name text field
        for (index, textField) in listNameTextFields.enumerated() {
            // Set the text in the field based on validation from view model
            output.listNameDisplayTexts[index].drive(textField.rx.text).disposed(by: disposeBag)
            // Set whether the text field should show active border or not
            output.listNameTextFieldsShowActiveBorders[index].drive(textField.rx.showBorder).disposed(by: disposeBag)
            // Set whether the text field should become first responder or resign it
            output.focusListNameTextFields[index].drive(textField.rx.isFirstResponder).disposed(by: disposeBag)
            // Set whether the text fields should be shown or hidden
            let isShownAnimated: Binder<Bool> = textField.rx.isShownAnimated(duration: stylesheet.standardAnimationDuration,
                                                                             options: [.curveEaseOut])
            output.listNameTextFieldsVisible.drive(isShownAnimated).disposed(by: disposeBag)
            // Selects the entire default string of the list text field
            output.listNameTextFieldsSelectAllText[index].drive(textField.rx.selectAll()).disposed(by: disposeBag)
        }
        
        // Show the hint border on the first list text field
        output.firstListNameTextFieldShowHintBorder.drive(listNameTextFields[0].rx.showHintBorder).disposed(by: disposeBag)

        // Set up bindings for hiding the cards in each list.
        for (index, listView) in boardView.boardContentView.listViews.enumerated() {
            output.listShouldHideCards[index].drive(listView.rx.shouldHideCards).disposed(by: disposeBag)
        }

        let cardViews = boardView.boardContentView.listViews.flatMap { $0.cardViews }
        cardViews.forEach {
            output.cardTitleTextFieldsEnabled.drive($0.rx.isActive).disposed(by: disposeBag)
            output.cardTitleTextFieldsEnabled.drive($0.rx.setPlaceholderText).disposed(by: disposeBag)
        }
        
        // Bindings for each card title text field
        for (index, textField) in cardTextFields.enumerated() {
            // Set the text field based on validation from view model
            output.cardTitleDisplayTexts[index].drive(textField.rx.text).disposed(by: disposeBag)
            // Set whether the first text field should show the active border or not
            output.cardTitleTextFieldsShowActiveBorders[index].drive(textField.rx.showBorder).disposed(by: disposeBag)
            // Set whether the first text field should become first responder or resign it
            output.focusCardTitleTextFields[index].drive(textField.rx.isFirstResponder).disposed(by: disposeBag)
            // Set whether all card title text fields should be enabled or disabled
            output.cardTitleTextFieldsEnabled.drive(textField.rx.isEnabled).disposed(by: disposeBag)
        }
        
        // Show the hint border on the first card text field
        output.firstCardTitleTextFieldShowHintBorder.drive(cardTextFields[0].rx.showHintBorder).disposed(by: disposeBag)

        // Set whether the editing right nav button should be shown
        output.rightNavForEditingButtonHidden.drive(onNext: { [weak self] (hidden) in
            self?.isHiddenFromNavBar(button: self?.rightNavForEditingButton, hidden: hidden)
        }).disposed(by: disposeBag)
        // Set the correct title for the editing right nav button depending on context (which field is currently first responder)
        output.rightNavForEditingButtonText.drive(rightNavForEditingButton.rx.updateTitleAndResize).disposed(by: disposeBag)
        // When the editing right nav button is tapped, force the editingDidEndOnExit event for the current first responder
        output.rightNavForEditingButtonAction.drive(self.view.rx.forceEndOnExitEventForCurrentFirstResponderControl).disposed(by: disposeBag)

        // Set whether the overlay skip right nav button should be shown
        output.rightNavForOverlaySkipButtonHidden.drive(onNext: { [weak self] (hidden) in
            self?.isHiddenFromNavBar(button: self?.rightNavForOverlaySkipButton, hidden: hidden)
        }).disposed(by: disposeBag)
        // Set the correct title for the overlay skip right nav button depending on context (which overlay step we're on)
        output.rightNavForOverlaySkipButtonText.drive(self.rightNavForOverlaySkipButton.rx.updateTitleAndResize).disposed(by: disposeBag)

        self.bindFlowSubject.onNext(Output(createBoard: output.createBoard))
        self.bindFlowSubject.onCompleted()

        // When the accessibility screen should change notification is posted
        output.accessibilityScreenChanged.drive(self.rx.accessibilityScreenChanged).disposed(by: disposeBag)
    }
    
    /// Creates List VMs for use within `transform`
    /// VMs are based upon a collection of text fields
    private func listViewModels(_ listTextFields: [UITextField]) -> [ListViewModelType] {
        return listTextFields.enumerated().map { (index, textField) -> ListViewModelType in
            guard viewModel.board.lists.count > index else {
                fatalError("Programmer error: The BoardContentView needs the same number of list views as exist in the template")
            }
            
            return ListViewModel(list: viewModel.board.lists[index],
                                        listNameText: textField.rx.text.orEmpty.asObservable(),
                                        editingDidBegin: textField.rx.controlEvent(.editingDidBegin).asObservable(),
                                        editingChanged: textField.rx.controlEvent(.editingChanged).asObservable(),
                                        editingDidEnd: textField.rx.controlEvent(.editingDidEnd).asObservable(),
                                        editingDidEndOnExit: textField.rx.controlEvent(.editingDidEndOnExit).asObservable())
        }
    }
    
    /// Creates Card VMs for use within `transform`
    /// VMs are based upon a collection of text fields
    private func cardViewModels(_ cardTitleTextFields: [UITextField]) -> [CardViewModelType] {
        return cardTitleTextFields.enumerated().map { (index, textField) -> CardViewModelType in
            let allCards = viewModel.board.lists.flatMap { $0.cards }
            guard allCards.count > index else {
                fatalError("Programmer error: The BoardContentView needs the same number of card views as exist in the template")
            }
            
            return CardViewModel(card: allCards[index],
                                        cardTitleText: textField.rx.text.orEmpty.asObservable(),
                                        editingDidBegin: textField.rx.controlEvent(.editingDidBegin).asObservable(),
                                        editingChanged: textField.rx.controlEvent(.editingChanged).asObservable(),
                                        editingDidEnd: textField.rx.controlEvent(.editingDidEnd).asObservable(),
                                        editingDidEndOnExit: textField.rx.controlEvent(.editingDidEndOnExit).asObservable())
            
        }
    }
    
    /// Constructs the view hierarchy and sets view properties that don't change. Design properties should come from the
    /// Stylesheet.
    private func configureViews() {
        let backButton = UIBarButtonItem()
        backButton.title = "start_over_back_button".localized
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton

        navigationItem.titleView = stylesheet.trelloLogoImageView
        
        rightNavForOverlaySkipButton.setTitle("skip_button".localized, for: .normal)

        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: rightNavForEditingButton),
                                              UIBarButtonItem(customView: rightNavForOverlaySkipButton)]
        
        self.view.backgroundColor = stylesheet.mainBackgroundColor
        
        self.view.addAutoLaidOutSubview(self.boardView)
        configureViewsForCompactWidth()
        configureViewsForRegularWidth()
    }

    /// Constructs the view hiearchy that is specific to the compact width version.
    private func configureViewsForCompactWidth() {
        for overlay in self.compactUI.overlays {
            view.addAutoLaidOutSubview(overlay)
        }
    }

    /// Constructs the view hiearchy that is specific to the compact width version.
    private func configureViewsForRegularWidth() {
        for overlay in self.regularUI.overlays {
            view.addAutoLaidOutSubview(overlay)
        }
    }

    /// Sets up the auto-layout constraints
    private func constrainViews() {
        // The board view is a scroll view that scrolls in both directions (mostly when in compact UI and large text/small devices)
        self.boardViewLeadingConstraint = (self.boardView.leadingAnchor |== self.view.leadingAnchor |+ self.stylesheet.gridUnit * 2)
        self.boardView.trailingAnchor |== self.view.trailingAnchor |- self.stylesheet.gridUnit
        self.boardView.topAnchor |== self.view.safeAreaLayoutGuide.topAnchor |+ stylesheet.gridUnit
        self.boardViewBottomConstraint = (self.boardView.bottomAnchor |== self.view.bottomAnchor |+ self.stylesheet.gridUnit)

        constrainViewsForCompactWidth()
        constrainViewsForRegularWidth()
    }
    
    private func configureFonts() {
        rightNavForEditingButton.titleLabel?.font = stylesheet.rightNavButtonFont
        rightNavForEditingButton.sizeToFit()
        
        rightNavForOverlaySkipButton.titleLabel?.font = stylesheet.rightNavButtonFont
        rightNavForOverlaySkipButton.sizeToFit()
    }

    private func constrainViewsForCompactWidth() {
        // Add all of the overlays left to right such that the first one is on screen and
        // the other ones abut it on the right. As we go through the process, we'll slide them in.
        var previousOverlay: OverlayView?
        for (index, overlay) in self.compactUI.overlays.enumerated() {
            // We make .defaultLow leading anchors so that the rubberbanding gesture can override
            if let previousOverlay = previousOverlay {
                overlay.leadingAnchor |== previousOverlay.trailingAnchor ~ .defaultLow
            } else {
                self.compactUI.overlayLeadingConstraint = (overlay.leadingAnchor |== self.view.leadingAnchor ~ .defaultLow)
            }

            overlay.widthAnchor |== self.view.widthAnchor |* 1
            overlay.bottomAnchor |== self.view.bottomAnchor

            // Make the overlay fit the content, but try not to cover the whole board
            overlay.heightAnchor |<= self.view.heightAnchor |* 0.6
            self.compactUI.overlayHeightConstraints[index] =
                (overlay.heightAnchor |== overlay.contentView.heightAnchor |+ compactOverlayHeightConstant() ~ .defaultLow)

            previousOverlay = overlay
        }
    }

    private func compactOverlayHeightConstant() -> CGFloat {
        return stylesheet.overlayCornerRadius + stylesheet.gridUnit + self.view.safeAreaInsets.bottom
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        for index in 0..<self.compactUI.overlays.count {
            self.compactUI.overlayHeightConstraints[index].constant = compactOverlayHeightConstant()
        }
    }

    private func constrainViewsForRegularWidth() {
        for overlay in self.regularUI.overlays {
            overlay.leadingAnchor |== self.view.leadingAnchor |+ stylesheet.gridUnit
            overlay.widthAnchor |== self.stylesheet.overlayRegularWidth
            overlay.topAnchor |== self.boardView.topAnchor

            // Make the overlay fit the content, but not be bigger than the board it's next to.
            overlay.heightAnchor |== overlay.contentView.heightAnchor |+ (stylesheet.overlayCornerRadius + stylesheet.gridUnit) ~ .defaultLow
            overlay.heightAnchor |<= self.boardView.heightAnchor |* 1
        }
    }

    /// RxCocoa drivers have no way of animating their changes, so this function applies the overlayLeadingConstant
    /// in an animation block so that the overlays slide over (rather than just instantly change)
    /// Could be replaced with a simple RxAnimated call in the future.
    private func moveOverlay(leadingConstant: CGFloat) {
        guard
            leadingConstant != self.compactUI.overlayLeadingConstraint.constant
        else {
            return
        }
        UIView.animate(
            withDuration: self.stylesheet.overlaySlideDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: { [weak self] in
                self?.compactUI.overlayLeadingConstraint.constant = leadingConstant
                self?.view.layoutIfNeeded()
        })
    }

    /// RxCocoa drivers have no way of animating their changes, so this function applies the alpha
    /// in an animation block so that the overlays fade in/out (rather than just instantly change)
    /// Could be replaced with a simple RxAnimated call in the future.
    private func fadeInOutOverlay(overlay: OverlayView, alpha: CGFloat) {
        guard alpha != overlay.alpha else { return }
        UIView.animate(
            withDuration: self.stylesheet.overlaySlideDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: { [weak overlay] in
                overlay?.alpha = alpha
        })
    }

    /// Removes right nav bar buttons from the bar when they are hidden and puts them back when they are not.
    /// Otherwise, there will be space reserved for them.
    func isHiddenFromNavBar(button: UIButton?, hidden: Bool) {
        guard let button = button else { return }
        if hidden {
            self.navigationItem.rightBarButtonItems?.removeAll(where: { (item) -> Bool in
                item.customView == button
            })
        } else {
            self.navigationItem.rightBarButtonItems?.append(UIBarButtonItem(customView: button))
        }
        
        self.navigationItem.rightBarButtonItems?.forEach({ (item) in
            item.customView?.setNeedsLayout()
            item.customView?.layoutIfNeeded()
        })
    }
}

extension Reactive where Base: OnboardingViewController {

    // The Coordinator/FlowController that creates this VC should observe this for requests to move
    // to sign-up or any other VC (see the VC's Output struct)
    var bindFlow: Maybe<Base.Output> {
        return base.bindFlowSubject.asMaybe()
    }
    
    // When the flow step changes, accessibility must make updates.
    var accessibilityScreenChanged: Binder<FlowStep> {
        return Binder(self.base) { onboardingVC, flowStep in
            var elements = [Any]()
            let ui: UI = (onboardingVC.traitCollection.horizontalSizeClass == .compact) ? onboardingVC.compactUI : onboardingVC.regularUI
            
            // At each flow step we change the accessibilityElements of the VC's view. This ensures that only the desired elements
            // are read by the voiceover system. We then post a notification to let voiceover know that the screen has changed and
            // it should begin reading its new collection of accessibilityElements.
            switch flowStep {
            case .begin:
                elements = [ui.overlays[0]]
            case .nameBoard:
                elements = [onboardingVC.boardView.nameTextField]
                elements.append(onboardingVC.navigationItem.rightBarButtonItem as Any)
            case .finishBoardNaming:
                elements = [ui.overlays[1]]
            case .nameLists:
                elements = onboardingVC.boardView.boardContentView.listViews.map { $0.nameTextField }
                elements.append(onboardingVC.navigationItem.rightBarButtonItem as Any)
            case .finishListNaming:
                elements = [ui.overlays[2]]
            case .nameCards:
                elements = onboardingVC.boardView.boardContentView.listViews.compactMap { $0.cardViews.map { $0.cardTitleTextField } }
                elements.append(onboardingVC.navigationItem.rightBarButtonItem as Any)
            case .finishCardNaming, .createBoard:
                elements = [ui.overlays[3]]
            }
            
            onboardingVC.view.accessibilityElements = elements
            UIAccessibility.post(notification: .screenChanged, argument: onboardingVC.view)
        }
    }

}


protocol UI {
    var overlays: [OverlayView] { get }
}
