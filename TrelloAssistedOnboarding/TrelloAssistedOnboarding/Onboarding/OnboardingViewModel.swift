//
//  OnboardingViewModel.swift
//  Trellis
//
//  Created by Lou Franco on 4/11/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol IOViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(_ input: Input) -> Output
}

protocol ListViewModelType {
    var list: BoardTemplate.List { get }
    var listNameText: Observable<String> { get }
    var editingDidBegin: Observable<Void> { get }
    var editingChanged: Observable<Void> { get }
    var editingDidEnd: Observable<Void> { get }
    var editingDidEndOnExit: Observable<Void> { get }
}

struct ListViewModel: ListViewModelType {
    let list: BoardTemplate.List
    let listNameText: Observable<String>
    let editingDidBegin: Observable<Void>
    let editingChanged: Observable<Void>
    let editingDidEnd: Observable<Void>
    let editingDidEndOnExit: Observable<Void>
}

protocol CardViewModelType {
    var card: BoardTemplate.Card { get }
    var cardTitleText: Observable<String> { get }
    var editingDidBegin: Observable<Void> { get }
    var editingChanged: Observable<Void> { get }
    var editingDidEnd: Observable<Void> { get }
    var editingDidEndOnExit: Observable<Void> { get }
}

struct CardViewModel: CardViewModelType {
    let card: BoardTemplate.Card
    let cardTitleText: Observable<String>
    let editingDidBegin: Observable<Void>
    let editingChanged: Observable<Void>
    let editingDidEnd: Observable<Void>
    let editingDidEndOnExit: Observable<Void>
}


class OnboardingViewModel: IOViewModelType {
    
    private let stylesheet = Stylesheet()

    // VC should make one of these, injecting all possible UI event sequences
    struct Input {
        // Board naming
        let boardNameText: Observable<String>
        let boardNameEditingDidBegin: Observable<Void>
        let boardNameEditingChanged: Observable<Void>
        let boardNameEditingDidEnd: Observable<Void>
        let boardNameEditingDidEndOnExit: Observable<Void>
        // List naming
        let listViewModels: [ListViewModelType]
        // Card naming
        let cardViewModels: [CardViewModelType]
        // Other
        let boardNameOverlayGoButtonsTap: Observable<Void>
        let listNameOverlayGoButtonsTap: Observable<Void>
        let cardTitleOverlayGoButtonsTap: Observable<Void>
        let createBoardOverlayGoButtonsTap: Observable<Void>
        let boardNameOverlaySkipButtonsTap: Observable<Void>
        let listNameOverlaySkipButtonsTap: Observable<Void>
        let cardTitleOverlaySkipButtonsTap: Observable<Void>
        let rightNavForEditingButtonTap: Observable<Void>
        let viewSize: Observable<CGSize>
        // Size class
        let traitCollection: Observable<UITraitCollection>
        // Keyboard
        let keyboardHeight: Driver<CGFloat>
    }
    
    // Bind to these in order to drive some UI
    struct Output {
        // Board view
        let boardZeroContentOffset: Driver<Void>
        let boardViewZoomOut: Driver<Bool>
        // Overlay
        let overlayLeadingConstraintConstant: Driver<CGFloat>
        let overlayFadeAnimations: (OverlayStep) -> Driver<CGFloat>
        let boardNamingOverlayButtonEnabled: Driver<Bool>
        let listNamingOverlayButtonEnabled: Driver<Bool>
        let cardNamingOverlayButtonEnabled: Driver<Bool>
        // Board name text field
        let boardNameDisplayText: Driver<String>
        let focusBoardNameTextField: Driver<Bool>
        let boardNameTextFieldSelectAllText: Driver<Void>
        let boardNameTextFieldShowActiveBorder: Driver<Bool>
        let boardNameTextFieldShowHintBorder: Driver<Bool>
        // List name text fields
        let listNameDisplayTexts: [Driver<String>]
        let focusListNameTextFields: [Driver<Bool>]
        let listNameTextFieldsVisible: Driver<Bool>
        let listNameTextFieldsSelectAllText: [Driver<Void>]
        let listNameTextFieldsShowActiveBorders: [Driver<Bool>]
        let firstListNameTextFieldShowHintBorder: Driver<Bool>
        // List - other attributes
        let listShouldHideCards: [Driver<Bool>]
        // Card title text fields
        let cardTitleDisplayTexts: [Driver<String>]
        let focusCardTitleTextFields: [Driver<Bool>]
        let cardTitleTextFieldsEnabled: Driver<Bool>
        let cardTitleTextFieldsShowActiveBorders: [Driver<Bool>]
        let firstCardTitleTextFieldShowHintBorder: Driver<Bool>
        // Compact/Regular UI control
        let compactUIHidden: Driver<Bool>
        let regularUIHidden: Driver<Bool>
        let boardLeadingConstant: Driver<CGFloat>
        let boardBottomConstant: Driver<CGFloat>
        // The board model
        let createBoard: Maybe<BoardTemplate.Board>
        // Skip editing nav button
        let rightNavForEditingButtonHidden: Driver<Bool>
        let rightNavForEditingButtonText: Driver<String>
        let rightNavForEditingButtonAction: Driver<Void>
        // Skip overlay nav button
        let rightNavForOverlaySkipButtonText: Driver<String>
        let rightNavForOverlaySkipButtonHidden: Driver<Bool>

        // Accessibility
        let accessibilityScreenChanged: Driver<FlowStep>
    }

    private let boardTemplate: BoardTemplate
    let boardMaxCharacters = 35
    let listMaxCharacters = 35
    let cardMaxCharacters = 35

    var board: BoardTemplate.Board { return boardTemplate.board }

    var overlaySteps: [OverlayStep] {
        return OverlayStep.allCases
    }

    init(boardTemplate: BoardTemplate) {
        self.boardTemplate = boardTemplate
    }
    
    // Takes an Input provided by a VC and performs any transformations needed for business rules or display.
    // The Output should contain Drivers that are bound to UI elements by the VC.
    func transform(_ input: Input) -> Output {
        let flowStep: Observable<FlowStep> = self.flowStep(input)
        let overlayStep: Observable<OverlayStep> = self.overlayStep(input)
        
        let boardZeroContentOffset: Driver<Void> = self.boardZeroContentOffset(flowStep)
        let boardNameDisplayText: Driver<String> = self.boardNameDisplayText(input, flowStep)
        let focusBoardNameTextField: Driver<Bool> = self.focusBoardNameTextField(input)
        let boardNameTextFieldSelectAllText: Driver<Void> = self.boardNameTextFieldSelectAllText(input)
        let boardNameTextFieldShowActiveBorder: Driver<Bool> = self.boardNameTextFieldShowActiveBorder(input)
        let boardNameTextFieldShowHintBorder: Driver<Bool> = self.boardNameTextFieldShowHintBorder(flowStep)

        let boardViewZoomOut: Driver<Bool> = self.boardViewZoomOut(input, flowStep)
        
        let overlayLeadingConstraintConstant: Driver<CGFloat> = self.overlayLeadingConstraintConstant(input, overlayStep)
        let boardNamingOverlayButtonEnabled: Driver<Bool> = self.boardNamingOverlayButtonEnabled(flowStep)
        let listNamingOverlayButtonEnabled: Driver<Bool> = self.listNamingOverlayButtonEnabled(flowStep)
        let cardNamingOverlayButtonEnabled: Driver<Bool> = self.cardNamingOverlayButtonEnabled(flowStep)
        let overlayFadeAnimations: (OverlayStep) -> Driver<CGFloat> = self.overlayFadeAnimations(input, overlayStep: overlayStep)

        let listNameDisplayTexts: [Driver<String>] = self.listNameDisplayTexts(input, flowStep)
        let focusListNameTextFields: [Driver<Bool>] = self.focusListNameTextFields(input, flowStep)
        let listNameTextFieldsVisible: Driver<Bool> = self.listNameTextFieldsVisible(flowStep)
        let listNameTextFieldsSelectAllText: [Driver<Void>] = self.listNameTextFieldsSelectAllText(input)
        let listNameTextFieldsShowActiveBorders: [Driver<Bool>] = self.listNameTextFieldsShowActiveBorders(input)
        let firstListNameTextFieldShowHintBorder: Driver<Bool> = self.firstListNameTextFieldShowHintBorder(flowStep)
        
        let listShouldHideCards: [Driver<Bool>] = self.listShouldHideCards(input, flowStep)
        
        let cardTitleDisplayTexts: [Driver<String>] = self.cardTitleDisplayTexts(input, flowStep)
        let focusCardTitleTextFields: [Driver<Bool>] = self.focusCardTitleTextFields(input, flowStep)
        let cardTitleTextFieldsEnabled: Driver<Bool> = self.cardTitleTextFieldsEnabled(flowStep)
        let cardTitleTextFieldsShowActiveBorders: [Driver<Bool>] = self.cardTitleTextFieldsShowActiveBorders(input)
        let firstCardTitleTextFieldShowHintBorder: Driver<Bool> = self.firstCardTitleTextFieldShowHintBorder(flowStep)

        let compactUIHidden = self.compactUIHidden(input)
        let regularUIHidden = self.regularUIHidden(compactUIHidden)
        let boardLeadingConstant = self.boardLeadingConstraint(compactUIHidden)
        let boardBottomConstant = self.boardBottomConstraint(input.keyboardHeight)

        let rightNavForEditingButtonText = self.rightNavForEditingButtonText(input)
        let rightNavForEditingButtonHidden = self.rightNavForEditingButtonHidden(rightNavForEditingButtonText.asObservable())
        let rightNavForEditingButtonAction = self.rightNavForEditingButtonAction(input)

        let rightNavForOverlaySkipButtonText = self.rightNavForOverlaySkipButtonText(flowStep)
        let rightNavForOverlaySkipButtonHidden = self.rightNavForOverlaySkipButtonHidden(flowStep, editHidden: rightNavForEditingButtonHidden.asObservable())

        let createBoard = self.createBoard(flowStep, boardNameDisplayText, listNameDisplayTexts, cardTitleDisplayTexts)

        let accessibilityScreenChanged = self.accessibilityScreenChanged(flowStep)

        return Output(boardZeroContentOffset: boardZeroContentOffset,
                      boardViewZoomOut: boardViewZoomOut,
                      overlayLeadingConstraintConstant: overlayLeadingConstraintConstant,
                      overlayFadeAnimations: overlayFadeAnimations,
                      boardNamingOverlayButtonEnabled: boardNamingOverlayButtonEnabled,
                      listNamingOverlayButtonEnabled: listNamingOverlayButtonEnabled,
                      cardNamingOverlayButtonEnabled: cardNamingOverlayButtonEnabled,
                      boardNameDisplayText: boardNameDisplayText,
                      focusBoardNameTextField: focusBoardNameTextField,
                      boardNameTextFieldSelectAllText: boardNameTextFieldSelectAllText,
                      boardNameTextFieldShowActiveBorder: boardNameTextFieldShowActiveBorder,
                      boardNameTextFieldShowHintBorder: boardNameTextFieldShowHintBorder,
                      listNameDisplayTexts: listNameDisplayTexts,
                      focusListNameTextFields: focusListNameTextFields,
                      listNameTextFieldsVisible: listNameTextFieldsVisible,
                      listNameTextFieldsSelectAllText: listNameTextFieldsSelectAllText,
                      listNameTextFieldsShowActiveBorders: listNameTextFieldsShowActiveBorders,
                      firstListNameTextFieldShowHintBorder: firstListNameTextFieldShowHintBorder,
                      listShouldHideCards: listShouldHideCards,
                      cardTitleDisplayTexts: cardTitleDisplayTexts,
                      focusCardTitleTextFields: focusCardTitleTextFields,
                      cardTitleTextFieldsEnabled: cardTitleTextFieldsEnabled,
                      cardTitleTextFieldsShowActiveBorders: cardTitleTextFieldsShowActiveBorders,
                      firstCardTitleTextFieldShowHintBorder: firstCardTitleTextFieldShowHintBorder,
                      compactUIHidden: compactUIHidden,
                      regularUIHidden: regularUIHidden,
                      boardLeadingConstant: boardLeadingConstant,
                      boardBottomConstant: boardBottomConstant,
                      createBoard: createBoard,
                      rightNavForEditingButtonHidden: rightNavForEditingButtonHidden,
                      rightNavForEditingButtonText: rightNavForEditingButtonText,
                      rightNavForEditingButtonAction: rightNavForEditingButtonAction,
                      rightNavForOverlaySkipButtonText: rightNavForOverlaySkipButtonText,
                      rightNavForOverlaySkipButtonHidden: rightNavForOverlaySkipButtonHidden,
                      accessibilityScreenChanged: accessibilityScreenChanged)
    }
    
    /// Describes the current state of the overall  Flow
    private func flowStep(_ input: Input) -> Observable<FlowStep> {

        // Create observables that have nexts when their respective skip button is tapped.
        // You can merge into name editing steps to skip them.
        let isBoardNamingSkipped = input.boardNameOverlaySkipButtonsTap.share(replay: 1, scope: .forever)
        let isListNamingSkipped = input.listNameOverlaySkipButtonsTap.share(replay: 1, scope: .forever)
        let isCardNamingSkipped = input.cardTitleOverlaySkipButtonsTap.share(replay: 1, scope: .forever)

        // boardNameSteps emits two nexts to move from .begin to .nameBoard to .finishBoard.
        // Each step will be skipped if the skip button is tapped
        let boardNameSteps = Observable.merge(input.boardNameEditingDidBegin, isBoardNamingSkipped).take(1)
            .concat(Observable.merge(input.boardNameEditingDidEnd, isBoardNamingSkipped).take(1))

        // List naming steps. Listens to all lists.
        let allListEditingDidBegins = Observable.merge(input.listViewModels.map { return $0.editingDidBegin.take(1) })
        let lastListEditingDidEnd: Observable<Void> = input.listViewModels.last?.editingDidEnd.take(1) ?? Observable.never()

        // listNameSteps emits two nexts to move from .finishBoard to .nameLists to .finishLists
        // Each step will be skipped if the skip button is tapped
        let listNameSteps = Observable.merge(allListEditingDidBegins, isListNamingSkipped).take(1)
            .concat(Observable.merge(lastListEditingDidEnd, isListNamingSkipped).take(1))

        // Card naming steps. Listens to call cards.
        let allCardEditingDidBegins = Observable.merge(input.cardViewModels.map { return $0.editingDidBegin.take(1) })
        let lastCardEditingDidEnd: Observable<Void> = input.cardViewModels.last?.editingDidEnd.take(1) ?? Observable.never()

        // cardNameSteps emits two nexts to move from .finishLists to .nameCards to .finishCards
        // Each step will be skipped if the skip button is tapped
        let cardNameSteps = Observable.merge(allCardEditingDidBegins, isCardNamingSkipped).take(1)
            .concat(Observable.merge(lastCardEditingDidEnd, isCardNamingSkipped).take(1))

        let createBoardSteps = input.createBoardOverlayGoButtonsTap.take(1)

        return boardNameSteps
            .concat(listNameSteps)
            .concat(cardNameSteps)
            .concat(createBoardSteps)
            // share, because we have multiple subscribers and we don't want them resubscribing to the events above this.
            .share(replay: 1, scope: .whileConnected)
            .concat(Observable.never())
            .scan(FlowStep.begin) { (previous, _) -> FlowStep in
                return previous.nextCase ?? previous
            }
            .startWith(.begin)
    }
    
    /// Describes the current state of the overlay step
    private func overlayStep(_ input: Input) -> Observable<OverlayStep> {
        let lastListTextFieldEditingDidEnd: Observable<Void> = input.listViewModels.last?.editingDidEnd.take(1) ?? Observable.never()
        let lastCardTextFieldEditingDidEnd: Observable<Void> = input.cardViewModels.last?.editingDidEnd.take(1) ?? Observable.never()

        // The overlay can move when the text field is edited or the skip button is tapped.
        let boardNameOverlayComplete = Observable.merge(input.boardNameEditingDidEnd,
                                                        input.boardNameOverlaySkipButtonsTap).take(1)
        let listNameOverlayComplete = Observable.merge(lastListTextFieldEditingDidEnd,
                                                       input.listNameOverlaySkipButtonsTap).take(1)
        let cardTitleOverlayComplete = Observable.merge(lastCardTextFieldEditingDidEnd,
                                                        input.cardTitleOverlaySkipButtonsTap).take(1)

        // This is the Create Account overlay -- all they can do is hit the go button
        let fourthOverlayComplete = input.createBoardOverlayGoButtonsTap.take(1)

        return boardNameOverlayComplete
            .concat(listNameOverlayComplete)
            .concat(cardTitleOverlayComplete)
            .concat(fourthOverlayComplete)
            .concat(Observable.never())
            .scan(.describeBoard) { (previous, _) -> OverlayStep in
                return previous.nextCase ?? previous
            }
            .startWith(.describeBoard)
    }
    
    /// Describes when the board view should reset its content offset
    private func boardZeroContentOffset(_ flowStep: Observable<FlowStep>) -> Driver<Void> {
        let stepsThatZeroOffset: [FlowStep] = [.finishBoardNaming,
                                                      .finishListNaming,
                                                      .finishCardNaming]
        return flowStep
            .filter { return stepsThatZeroOffset.contains($0) }
            .map { _ in }
            .observeOn(MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: ())
    }
    
    /// A validated Board name
    /// Validation rules:
    ///     1. Cannot exceed 35 characters
    ///     2. Cannot be empty, if so will become the default board name
    private func boardNameDisplayText(_ input: Input, _ flowStep: Observable<FlowStep>) -> Driver<String> {
        // Constrain board name text to max characters
        let maxCharacters = self.boardMaxCharacters
        let defaultBoardName = self.board.defaultName
        let validRealTimeBoardName: Observable<String> = input.boardNameEditingChanged
            .withLatestFrom(input.boardNameText)
            .startWith(defaultBoardName)
            .scan(defaultBoardName) { (previous, next) in
                if next.count > maxCharacters {
                    return previous
                }
                return next
        }
        
        // If board name is empty, fall back to template default name
        let validFinalBoardName = input.boardNameEditingDidEnd
            .withLatestFrom(validRealTimeBoardName)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { ($0.isEmpty) ? defaultBoardName : $0 }
        
        // If the user taps the Skip nav button revert to default board name
        let skipBoardNaming = input.boardNameOverlaySkipButtonsTap
            .withLatestFrom(flowStep)
            .filter { step in step < .finishBoardNaming }
            .map { _ in defaultBoardName }
        
        let displayBoardNameText = Observable.merge(validRealTimeBoardName, validFinalBoardName, skipBoardNaming)
        
        return displayBoardNameText.asDriver(onErrorJustReturn: defaultBoardName)
    }
    
    /// Describes the events that should cause the board name text field to become or resign first responder
    private func focusBoardNameTextField(_ input: Input) -> Driver<Bool> {
        return Observable
            .merge(input.boardNameOverlayGoButtonsTap.map { true },
                   input.boardNameOverlaySkipButtonsTap.map { false },
                   input.boardNameEditingDidEndOnExit.map { false })
            .asDriver(onErrorJustReturn: false)
    }
    
    /// Describes the events that should cause the board name text field to select all content
    private func boardNameTextFieldSelectAllText(_ input: Input) -> Driver<Void> {
        return input.boardNameEditingDidBegin.take(1).asDriver(onErrorJustReturn: ())
    }

    /// Describes whether the board name text field should show the active border
    private func boardNameTextFieldShowActiveBorder(_ input: Input) -> Driver<Bool> {
        return Observable.merge(
            input.boardNameEditingDidBegin.map { true },
            input.boardNameEditingDidEnd.map { false },
            input.boardNameEditingDidEndOnExit.map { false }
        ).asDriver(onErrorJustReturn: false)
    }

    /// Describes whether the board name text field should show the hint border
    private func boardNameTextFieldShowHintBorder(_ flowStep: Observable<FlowStep>) -> Driver<Bool> {
        return flowStep
            .map { $0 == .begin }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
    }
    
    /// Describes whether the board view should zoom out or back in based on the current flow step
    private func boardViewZoomOut(_ input: Input, _ flowStep: Observable<FlowStep>) -> Driver<Bool> {
        return Observable.combineLatest(input.traitCollection, flowStep.skip(1), resultSelector: { trait, step -> Bool in
            if trait.horizontalSizeClass == .compact && step == .finishBoardNaming {
                return true
            }
            
            return false
        }).asDriver(onErrorJustReturn: false)
    }
    
    /// Describes the leading constraint for the first overlay view based on the current overlay step
    private func overlayLeadingConstraintConstant(_ input: Input, _ overlayStep: Observable<OverlayStep>) -> Driver<CGFloat> {
        return Observable.combineLatest(overlayStep, input.viewSize) { step, size in
            return -CGFloat(step.rawValue) * size.width
        }.asDriver(onErrorJustReturn: 0.0)
    }
    
    private func boardNamingOverlayButtonEnabled(_ flowStep: Observable<FlowStep>) -> Driver<Bool> {
        return flowStep
            .filter { $0 > .begin }
            .map { _ in false }
            .take(1)
            .asDriver(onErrorJustReturn: true)
    }
    
    private func listNamingOverlayButtonEnabled(_ flowStep: Observable<FlowStep>) -> Driver<Bool> {
        return flowStep
            .filter { $0 >= .nameLists }
            .map { _ in false }
            .take(1)
            .asDriver(onErrorJustReturn: true)
    }
    
    private func cardNamingOverlayButtonEnabled(_ flowStep: Observable<FlowStep>) -> Driver<Bool> {
        return flowStep
            .filter { $0 >= .nameCards }
            .map { _ in false }
            .take(1)
            .asDriver(onErrorJustReturn: true)
    }
    
    /// Describes a function that takes an overlay step and VC state and returns a function that returns the alpha driver for each overlay view
    private func overlayFadeAnimations(_ input: Input, overlayStep: Observable<OverlayStep>) -> ((OverlayStep) -> Driver<CGFloat>) {
        let keyboardHidesOverlay = keyboardUpInCompact(input)

        // We take step and return a animation driver for it.
        return { (step: OverlayStep) -> Driver<CGFloat> in
            // We want to always hide the overlay in compact when the KB is up.
            // Otherwise, we want to show the current one and hide the rest.
            return Observable.combineLatest(overlayStep, keyboardHidesOverlay) { (currentStep, keyboardHidesOverlay) -> CGFloat in
                if keyboardHidesOverlay {
                    return 0
                } else {
                    return currentStep == step ? 1 : 0
                }
            }.asDriver(onErrorJustReturn: 1)
        }
    }

    /// Describes a function that takes the VC state and returns a Bool for whether the KB is up in compact width UI
    private func keyboardUpInCompact(_ input: Input) -> Observable<Bool> {
        let compactUIHiddenObservable = compactUIHidden(input)
        return Observable.combineLatest(input.keyboardHeight.asObservable(), compactUIHiddenObservable.asObservable(), resultSelector: { (keyboardHeight, compactUIHidden) -> Bool in
            return (keyboardHeight > 0 && !compactUIHidden)
        })
        .distinctUntilChanged()
        // When we move focus, we get a quick true, false, true
        .debounce(0.2, scheduler: MainScheduler.instance)
        .startWith(false)
        .share(replay: 1, scope: .whileConnected)
    }
    
    /// Describes when the view should hide the compact size class overlay UI
    private func compactUIHidden(_ input: Input) -> Driver<Bool> {
        let horizontalSizeClass = input.traitCollection.map { $0.horizontalSizeClass }
        return horizontalSizeClass.map { $0 != .compact }.asDriver(onErrorJustReturn: true)
    }
    
    /// Describes when the view should hide the regular size class overlay UI
    private func regularUIHidden(_ compactUIHidden: Driver<Bool>) -> Driver<Bool> {
        return compactUIHidden.not()
    }

    /// Based on if we are in compact or regular, manage the leading constraint of the Board
    private func boardLeadingConstraint(_ compactUIHidden: Driver<Bool>) -> Driver<CGFloat> {
        return compactUIHidden.map { [weak self] compactUIHidden in
            guard let stylesheet = self?.stylesheet else { return 0 }
            return compactUIHidden ? (stylesheet.overlayRegularWidth + stylesheet.gridUnit * 2) : stylesheet.gridUnit
        }
    }
    
    /// Based on the keyboard height, manage the bottom constraint of the Board
    private func boardBottomConstraint(_ keyboardHeight: Driver<CGFloat>) -> Driver<CGFloat> {
        let gridUnit = self.stylesheet.gridUnit
        return keyboardHeight
            // When we move focus, we get a quick KB down/up
            .debounce(0.2)
            .map { height in
                return -(height + gridUnit)
            }
            .asDriver(onErrorJustReturn: 0)
    }

    /// A collection of validated List name sequences
    /// Validation rules:
    ///     1. Cannot exceed 35 characters
    ///     2. Cannot be empty, if so will become the default list name
    private func listNameDisplayTexts(_ input: Input, _ flowStep: Observable<FlowStep>) -> [Driver<String>] {
        let listMaxCharacters = self.listMaxCharacters

        return input.listViewModels.map { (listViewModel: ListViewModelType) in
            let defaultListName = listViewModel.list.defaultName
            
            // Constrain list name text to max characters
            let validRealTimeListName: Observable<String> = listViewModel.editingChanged
                .withLatestFrom(listViewModel.listNameText)
                .startWith(defaultListName)
                .scan(defaultListName) { (previous, next) in
                    if next.count > listMaxCharacters {
                        return previous
                    }
                    return next
            }
            
            // If list name is empty, fall back to template default name
            let validFinalListName: Observable<String> = listViewModel.editingDidEnd
                .withLatestFrom(validRealTimeListName)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map { ($0.isEmpty) ? defaultListName : $0 }
            
            // If the user taps the Skip overlay button revert to default list name
            let skipListNaming = input.listNameOverlaySkipButtonsTap
                .withLatestFrom(flowStep)
                .filter { step in step < .finishListNaming }
                .map { _ in defaultListName }
            
            // Merge the validations so any one can drive the textField
            let displayListText = Observable.merge(validRealTimeListName, validFinalListName, skipListNaming)
                .asDriver(onErrorJustReturn: defaultListName)
            return displayListText
        }
    }
    
    /// Describes the events that should cause the each list text field to become or resign first responder
    private func focusListNameTextFields(_ input: Input, _ flowStep: Observable<FlowStep>) -> [Driver<Bool>] {
        return input.listViewModels.enumerated().map { (index, listViewModel) -> Driver<Bool> in
            
            // Focus the first List text field if hitting List Overlay Go button
            let focusFirstTextFieldOnlyOnListOverlayGoButtonTap = input.listNameOverlayGoButtonsTap.map { index == 0 }
            
            // Move focus to the next List
            let didEndOnExitEventsOfPreviousIndex: Observable<Bool> = (index > 0) ?
                input.listViewModels[index - 1].editingDidEndOnExit.map { true } : .just(false)
            
            // Focuses the first List text field when board editing ends if the flow step is beyond finishBoard
            let stepsBoardEditEndingShouldFocusFirstList: [FlowStep] = [.nameLists, .finishListNaming]
            let boardTextFieldDidEndEditingPostBoardEditing: Observable<Bool> =
                input.boardNameEditingDidEndOnExit
                    .filter { _ in index == 0 }
                    .withLatestFrom(flowStep)
                    .map { stepsBoardEditEndingShouldFocusFirstList.contains($0) }
            
            return Observable
                .merge(focusFirstTextFieldOnlyOnListOverlayGoButtonTap,
                       input.listNameOverlaySkipButtonsTap.map { false },
                       didEndOnExitEventsOfPreviousIndex,
                       boardTextFieldDidEndEditingPostBoardEditing,
                       listViewModel.editingDidEndOnExit.map { false })
                .asDriver(onErrorJustReturn: false)
        }
    }
    
    /// Describes when the List text fields should become visible: only after the flow has reached Finished Board state
    private func listNameTextFieldsVisible(_ flowStep: Observable<FlowStep>) -> Driver<Bool> {
        return flowStep.map { $0 >= FlowStep.finishBoardNaming }.asDriver(onErrorJustReturn: true)
    }
    
    // Describes when the List text field should select the entire default string: only the first time it is focused
    private func listNameTextFieldsSelectAllText(_ input: Input) -> [Driver<Void>] {
        return input.listViewModels.enumerated().map { (index, listViewModel) -> Driver<Void> in
            return listViewModel.editingDidBegin.take(1)
                .asDriver(onErrorJustReturn: ())
        }
    }
    
    /// Describes whether each list name text field should show the active border
    private func listNameTextFieldsShowActiveBorders(_ input: Input) -> [Driver<Bool>] {
        return input.listViewModels.enumerated().map { (index, listViewModel) -> Driver<Bool> in
            return Observable.merge(
                listViewModel.editingDidBegin.map { true },
                listViewModel.editingDidEnd.map { false },
                listViewModel.editingDidEndOnExit.map { false }
                ).asDriver(onErrorJustReturn: false)
        }
    }
    
    /// Describes whether the first list name text field should show the hint border
    private func firstListNameTextFieldShowHintBorder(_ flowStep: Observable<FlowStep>) -> Driver<Bool> {
        return flowStep
            .map { [.finishBoardNaming, .nameLists].contains($0) }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
    }

    /// Describes the events that should cause a list to hide its cards
    /// Rules:
    ///     1. Cards are shown at the beginning
    ///     2. When we get to the editing cards step, only the first list shows cards
    private func listShouldHideCards(_ input: Input, _ flowStep: Observable<FlowStep>) -> [Driver<Bool>] {
        return input.listViewModels.enumerated().map { (index, listViewModel) -> Driver<Bool> in
            if index == 0 {
                // The first list always shows its cards
                return Observable<Bool>
                    .just(false)
                    .asDriver(onErrorJustReturn: false)
            } else {
                return flowStep.map { $0 >= FlowStep.finishListNaming }.asDriver(onErrorJustReturn: false)
            }
        }
    }

    /// A collection of validated Card title sequences
    /// Validation rules:
    ///     1. Cannot exceed 35 characters
    private func cardTitleDisplayTexts(_ input: Input, _ flowStep: Observable<FlowStep>) -> [Driver<String>] {
        let cardMaxCharacters = self.cardMaxCharacters
        
        return input.cardViewModels.map { (cardViewModel: CardViewModelType) in
            // Constrain card name text to max characters
            let validRealTimeCardTitle: Observable<String> = cardViewModel.editingChanged
                .withLatestFrom(cardViewModel.cardTitleText)
                .scan("") { (previous, next) in
                    if next.count > cardMaxCharacters {
                        return previous
                    }
                    return next
                }
                .map { $0 }
                .startWith("")
            
            // Just trim the card title, there is not default card text to fall back to
            let validFinalCardTitle: Observable<String> = cardViewModel.editingDidEnd
                .withLatestFrom(validRealTimeCardTitle)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // If the user taps the Skip nav button revert to empty card name, unless it's the Finish button.
            // This is because the Overlay Skip Button is repurposed once we reach finishCards to complete the entire flow.
            let skipCardNaming = input.cardTitleOverlaySkipButtonsTap
                .withLatestFrom(flowStep)
                .filter { step in step < .finishCardNaming }
                .map { _ in return "" }
            
            // There is no default fallback name for cards. Let it clear to show the placeholder instead.
            let displayCardTitleText = Observable
                .merge(validRealTimeCardTitle, validFinalCardTitle, skipCardNaming)
                .asDriver(onErrorJustReturn: "")
            return displayCardTitleText
        }
    }
    
    /// Describes the events that should cause the each card text field to become or resign first responder
    /// Rules:
    ///     1. The third overlay's Go button tap should only focus the first card textfield once, and no others
    private func focusCardTitleTextFields(_ input: Input, _ flowStep: Observable<FlowStep>) -> [Driver<Bool>] {
        return input.cardViewModels.enumerated().map { (index, cardViewModel) -> Driver<Bool> in
            
            // Focus the first Card text field if hitting Card Overlay Go button
            let focusFirstTextFieldOnlyOnCardOverlayGoButtonTap = input.cardTitleOverlayGoButtonsTap.map {
                return index == 0
            }
            
            // Move focus to the next Card
            let didEndOnExitEventsOfPreviousIndex: Observable<Bool> = (index > 0) ?
                input.cardViewModels[index - 1].editingDidEndOnExit.map { true } : .just(false)

            // Focuses the first Card text field when board name editing ends if the flow step is nameCards
            let boardNameTextFieldDidEndEditingDuringNamingCards: Observable<Bool> =
                input.boardNameEditingDidEndOnExit
                    .filter { _ in index == 0 }
                    .withLatestFrom(flowStep)
                    .map { $0 == .nameCards }
            
            // Focuses the first Card text field when last List editing ends if the flow step is beyond finishLists
            let stepsListEditEndingShouldFocusFirstCard: [FlowStep] = [.nameCards]
            let lastListTextFieldDidEndEditingOnExitPostListEditing: Observable<Bool> =
                input.listViewModels.last?.editingDidEndOnExit
                    .filter { _ in index == 0 }
                    .withLatestFrom(flowStep)
                    .map { stepsListEditEndingShouldFocusFirstCard.contains($0) }
            ?? .just(false)
            
            return Observable
                .merge(focusFirstTextFieldOnlyOnCardOverlayGoButtonTap,
                       input.cardTitleOverlaySkipButtonsTap.map { false },
                       didEndOnExitEventsOfPreviousIndex,
                       boardNameTextFieldDidEndEditingDuringNamingCards,
                       lastListTextFieldDidEndEditingOnExitPostListEditing,
                       cardViewModel.editingDidEndOnExit.map { false })
                .asDriver(onErrorJustReturn: false)
        }
    }
    
    /// Describes when the Card text fields should become enabled: only after the flow has reached Finished Lists state
    private func cardTitleTextFieldsEnabled(_ flowStep: Observable<FlowStep>) -> Driver<Bool> {
        return flowStep.map { $0 >= FlowStep.finishListNaming }.asDriver(onErrorJustReturn: true)
    }
    
    /// Describes whether each card title text field should show the active border
    private func cardTitleTextFieldsShowActiveBorders(_ input: Input) -> [Driver<Bool>] {
        return input.cardViewModels.enumerated().map { (index, cardViewModel) -> Driver<Bool> in
            return Observable.merge(
                cardViewModel.editingDidBegin.map { true },
                cardViewModel.editingDidEnd.map { false },
                cardViewModel.editingDidEndOnExit.map { false }
                ).asDriver(onErrorJustReturn: false)
        }
    }

    /// Describes whether the first card title text field should show the hint border
    private func firstCardTitleTextFieldShowHintBorder(_ flowStep: Observable<FlowStep>) -> Driver<Bool> {
        return flowStep
            .map { [.finishListNaming, .nameCards].contains($0) }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
    }
    
    /// This is bound to the Flow Controller to tell it when to move to signup
    private func createBoard(_ flowStep: Observable<FlowStep>,
                                        _ displayBoardNameText: Driver<String>,
                                        _ displayListNameTexts: [Driver<String>],
                                        _ displayCardTitleTexts: [Driver<String>]) -> Maybe<BoardTemplate.Board> {

        // Represents an edit of the board. We'll map changes in view state to these edits to apply to a board object
        enum Action {
            case editBoardName(name: String)
            case editListName(name: String, listPos: Int)
            case editCardName(name: String, listPos: Int, cardPos: Int)
        }

        // Lets us know when we are ready to move on to sign up.
        // This emits one next when the user taps the "Create Board" button.
        let createBoardStep = flowStep.filter{ $0 == .createBoard }

        // Make Actions to edit the board model from the changes being made in the UI. We'll apply those to the template board
        // and produce a customized board.

        // When we are at the create account step, make a board edit action from the last board name
        let boardNameEditAction: Observable<Action> = createBoardStep
            .withLatestFrom(displayBoardNameText)
            .map { Action.editBoardName(name: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .take(1)

        // When we are at the create account step, make a set of edit actions from all of the last list names

        // To make it, we map all of the list name observables into an editListName Action. Then, we
        // merge all of them together into an observable of each list's edit action. There is one next per list.
        let listNameEditActions: Observable<Action> =
            Observable.merge(
                displayListNameTexts.enumerated().map { (listPos, listNameText) in
                    // We make one of these for each list
                    return createBoardStep
                        .withLatestFrom(listNameText)
                        .map { Action.editListName(name: $0.trimmingCharacters(in: .whitespacesAndNewlines), listPos: listPos) }
                        .take(1)
                }
            )

        // When we are at the create account step, make a set of edit actions from all of the last card names

        // To make it, we map all of the card title observables into an editCardName Action. Then, we
        // merge all of them together into an observable of each card's edit action. There is one next per card.
        let cardNameEditActions: Observable<Action> =
            Observable.merge(
                displayCardTitleTexts.enumerated().map { (cardIndex, cardNameText) -> Observable<Action> in
                    // We have a overall index of the card on the board, but we need (listPos, cardPos)
                    let cardIndexPath = self.board.cardIndexPath(cardIndex: cardIndex)
                    let listPos = cardIndexPath.section
                    let cardPos = cardIndexPath.row

                    // We make one of these for each card
                    return createBoardStep
                        .withLatestFrom(cardNameText)
                        .map { Action.editCardName(name: $0.trimmingCharacters(in: .whitespacesAndNewlines), listPos: listPos, cardPos: cardPos) }
                        .take(1)
                }
        )

        // The customized board is the template board with the edits applied to it.

        // To make it, we merge the board name, list names, and card names edit action observables into a single observable that will emit all of the edit actions.
        // Then each edit is applied to self.board and the entire chain completes with the final board value.
        // We convert to a Maybe at the end. We could not use Maybe throughout the process because they aren't mergeable.
        let customizedBoard: Maybe<BoardTemplate.Board> =
            // All of these actions in the merge will complete then the merge completes when all edits are applied
            Observable.merge(boardNameEditAction, listNameEditActions, cardNameEditActions)
            // Apply the edit action to the board
            .scan(self.board, accumulator: { board, action in
                var newBoard = board
                switch action {
                case .editBoardName(let name):
                    newBoard.customBoardName = name
                case .editListName(let name, let listPos):
                    newBoard.lists[listPos].customListName = name
                case .editCardName(let name, let listPos, let cardPos):
                    if name == "" {
                        newBoard.lists[listPos].cards[cardPos].customCardName = nil
                    } else {
                        newBoard.lists[listPos].cards[cardPos].customCardName = name
                    }
                }
                return newBoard
            })
            // When it completes, take the last one
            .takeLast(1)
            .asMaybe()

        return customizedBoard
    }

    // MARK: - Analytics Helpers

    // Return a Maybe that succeeds the first time a specific overlay is shown
    private func seesOverlay(specificStep: OverlayStep, in overlayStep: Observable<OverlayStep>) -> Maybe<Void> {
        return overlayStep
            .filter {
                $0 == specificStep
            }
            .map { _ in () }
            .take(1)
            .asMaybe()
    }

    // Converts the first tap of a button into a Maybe
    private func tapsButtonOnce(buttonTap: Observable<Void>) -> Maybe<Void> {
        return buttonTap
            .take(1)
            .asMaybe()
    }

    // MARK: - Analytics inputs for text typing events

    // Succeeds when it's time to send a "types board name" event
    private func typesBoardName(_ input: Input) -> Maybe<Void> {
        // Succeed when the user finishes editing the board name with anything different than a blank name or the default name.
        let defaultName = self.board.defaultName
        return input.boardNameEditingDidEnd
            .withLatestFrom(input.boardNameText)
            .filter { name in
                name != defaultName && !name.isEmpty
            }
            .map { _ in () }
            .take(1)
            .asMaybe()
    }

    // Sends one next for each list the first time it is edited.
    // This is a merge of the observables on each list.
    private func typesListName(_ input: Input) -> Observable<Int> {

        // Map each list view model into an observable that tells you when it is edited (to be merged)
        let listWithIndexEdited: [Observable<Int>] =
            input.listViewModels.enumerated().map({ (index, listViewModel) -> Observable<Int> in
                let defaultName = listViewModel.list.defaultName

                // When the list editing ends with a non-blank/non-default, emit a next with the list number and complete
                let editedListWithIndex: Observable<Int> = listViewModel.editingDidEnd
                    .withLatestFrom(listViewModel.listNameText)
                    .filter { name in
                        name != defaultName && !name.isEmpty
                    }
                    .map { _ in index }
                    .take(1)

                return editedListWithIndex
            })

        // The final observable emits the list index the first time a list is edited.
        return Observable<Int>.merge(listWithIndexEdited)
    }

    // Sends one next for each card the first time it is edited.
    // This is a merge of the observables on each card.
    // NOTE: cards do not have default names.
    private func typesCardName(_ input: Input) -> Observable<Int> {

        // Map each card view model into an observable that tells you when it is edited (to be merged)
        let cardWithIndexEdited: [Observable<Int>] =
            input.cardViewModels.enumerated().map({ (index, cardViewModel) -> Observable<Int> in
                // When the card editing ends with a non-blank, emit a next with the card number and complete
                let editedCardWithIndex: Observable<Int> = cardViewModel.editingDidEnd
                    .withLatestFrom(cardViewModel.cardTitleText)
                    .filter { name in
                        !name.isEmpty
                    }
                    .map { _ in index }
                    .take(1)

                return editedCardWithIndex
            })

        // The final observable emits the card index the first time a card is edited.
        return Observable<Int>.merge(cardWithIndexEdited)
    }

    /// Describes what the right nav button text should be when editing a board, list, card.
    private func rightNavForEditingButtonText(_ input: Input) -> Driver<String> {
        
        let nextListText = "next_list_button".localized
        let nextCardText = "next_card_button".localized
        let doneText = "default_board_list_done".localized

        let allListEditingDidBegin: Observable<String> = Observable.merge(
            input.listViewModels.map { $0.editingDidBegin }.enumerated().map { (index, editingDidBegin) -> Observable<String> in
                switch index {
                case input.listViewModels.count - 1:
                    return editingDidBegin.map { doneText }
                default:
                    return editingDidBegin.map { nextListText }
                }
            }
        )
        
        let allCardEditingDidBegin: Observable<String> = Observable.merge(
            input.cardViewModels.map { $0.editingDidBegin }.enumerated().map { (index, editingDidBegin) -> Observable<String> in
                switch index {
                case input.cardViewModels.count - 1:
                    return editingDidBegin.map { doneText }
                default:
                    return editingDidBegin.map { nextCardText }
                }
            }
        )
        
        let allListEditingDidEnd = Observable.merge(input.listViewModels.map { return $0.editingDidEnd.map { "" } })

        let allCardEditingDidEnd = Observable.merge(input.cardViewModels.map { return $0.editingDidEnd.map { "" } })

        return Observable.merge(
            input.boardNameEditingDidBegin.map { doneText },
            input.boardNameEditingDidEnd.map { "" },
            allListEditingDidBegin,
            allListEditingDidEnd,
            allCardEditingDidBegin,
            allCardEditingDidEnd)
            .startWith("")
            .asDriver(onErrorJustReturn: "")
    }
    
    /// Describes when the right nav button for editing should be hidden: only if the button title is non-empty
    private func rightNavForEditingButtonHidden(_ rightNavForEditingButtonText: Observable<String>) -> Driver<Bool> {
        return rightNavForEditingButtonText
            .map { $0.isEmpty }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
    }
    
    /// Describes the action that should take place when the right nav button for editing is tapped
    private func rightNavForEditingButtonAction(_ input: Input) -> Driver<Void> {
        return input.rightNavForEditingButtonTap.asDriver(onErrorJustReturn: ())
    }

    private func accessibilityScreenChanged(_ flowStep: Observable<FlowStep>) -> Driver<FlowStep> {
        return flowStep.asDriver(onErrorJustReturn: .begin)
    }

    /// Describes what the right nav button text should be when editing a board, list, card.
    private func rightNavForOverlaySkipButtonText(_ flowStep: Observable<FlowStep>) -> Driver<String> {
        let stepsThatStaySkipInsteadOfFinish: [FlowStep] = [.begin, .finishBoardNaming, .finishListNaming]

        return flowStep.map {
            return stepsThatStaySkipInsteadOfFinish.contains($0) ? "skip_button".localized : "finish_button".localized
            }
            .distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: "")
    }

    /// Describes when the right nav button for overlay skipping should be hidden: only shown at overlay start and if not editing
    private func rightNavForOverlaySkipButtonHidden(_ flowStep: Observable<FlowStep>, editHidden: Observable<Bool>) -> Driver<Bool> {
        let stepsThatShowSkip: [FlowStep] = [.begin, .finishBoardNaming, .finishListNaming, .finishCardNaming]
        
        return Observable
            .combineLatest(flowStep, editHidden) { step, editButtonIsHidden -> Bool in
                // If we are editing, don't show the skip button
                if !editButtonIsHidden {
                    return true
                }
                return !stepsThatShowSkip.contains(step)
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: true)
    }
}
