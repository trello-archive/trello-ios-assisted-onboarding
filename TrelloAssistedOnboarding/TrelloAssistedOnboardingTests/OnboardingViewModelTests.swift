//
//  OnboardingViewModelTests.swift
//  TrelloTests
//
//  Created by Lou Franco on 4/11/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import XCTest
import RxSwift
import UIKit
@testable import TrelloAssistedOnboarding


// This value should mimic OnboardingViewModelTests except with PublishSubjects instead of Observables
struct PublishingListViewModel: ListViewModelType {
    let list: BoardTemplate.List
    var listNameText: Observable<String> { return self.listNameTextSubject.asObservable() }
    var editingDidBegin: Observable<Void> { return self.editingDidBeginSubject.asObservable() }
    var editingChanged: Observable<Void> { return self.editingChangedSubject.asObservable() }
    var editingDidEnd: Observable<Void> { return self.editingDidEndSubject.asObservable() }
    var editingDidEndOnExit: Observable<Void> { return self.editingDidEndOnExitSubject.asObservable() }

    let listNameTextSubject = PublishSubject<String>()
    let editingDidBeginSubject = PublishSubject<Void>()
    let editingChangedSubject = PublishSubject<Void>()
    let editingDidEndSubject = PublishSubject<Void>()
    let editingDidEndOnExitSubject = PublishSubject<Void>()
}

// This value should mimic CardViewModel except with PublishSubjects instead of Observables
struct PublishingCardViewModel: CardViewModelType {
    let card: BoardTemplate.Card
    var cardTitleText: Observable<String> { return self.cardTitleTextSubject.asObservable() }
    var editingDidBegin: Observable<Void> { return self.editingDidBeginSubject.asObservable() }
    var editingChanged: Observable<Void> { return self.editingChangedSubject.asObservable() }
    var editingDidEnd: Observable<Void> { return self.editingDidEndSubject.asObservable() }
    var editingDidEndOnExit: Observable<Void> { return self.editingDidEndOnExitSubject.asObservable() }

    let cardTitleTextSubject = PublishSubject<String>()
    let editingDidBeginSubject = PublishSubject<Void>()
    let editingChangedSubject = PublishSubject<Void>()
    let editingDidEndSubject = PublishSubject<Void>()
    let editingDidEndOnExitSubject = PublishSubject<Void>()
}

class OnboardingViewModelTests: XCTestCase {

    let viewModel = OnboardingViewModel(boardTemplate: BoardTemplate(type: .manageProject))
    let stylesheet = Stylesheet()
    let disposeBag = DisposeBag()
    var output: OnboardingViewModel.Output!

    /* The next properties should mirror OnboardingViewModel.Input */
    var boardViewTapped: PublishSubject<UITapGestureRecognizer>!
    // Board naming
    var boardNameText: PublishSubject<String>!
    var boardNameEditingDidBegin: PublishSubject<Void>!
    var boardNameEditingChanged: PublishSubject<Void>!
    var boardNameEditingDidEnd: PublishSubject<Void>!
    var boardNameEditingDidEndOnExit: PublishSubject<Void>!
    var boardNameOverlayGoButtonTap: PublishSubject<Void>!
    var listNameOverlayGoButtonTap: PublishSubject<Void>!
    var cardTitleOverlayGoButtonTap: PublishSubject<Void>!
    var boardNameOverlaySkipButtonTap: PublishSubject<Void>!
    var listNameOverlaySkipButtonTap: PublishSubject<Void>!
    var cardTitleOverlaySkipButtonTap: PublishSubject<Void>!
    var createBoardOverlayGoButtonTap: PublishSubject<Void>!
    var rightNavForEditingButtonTap: PublishSubject<Void>!
    // Lists
    var listViewModels: [PublishingListViewModel]!
    var cardViewModels: [PublishingCardViewModel]!
    // Size changes
    var viewSize: PublishSubject<CGSize>!
    var traitCollection: PublishSubject<UITraitCollection>!
    // Keyboard
    var keyboardHeight: PublishSubject<CGFloat>!

    override func setUp() {
        super.setUp()

        self.boardNameText = PublishSubject<String>()
        self.boardNameEditingDidBegin = PublishSubject<Void>()
        self.boardNameEditingChanged = PublishSubject<Void>()
        self.boardNameEditingDidEnd = PublishSubject<Void>()
        self.boardNameEditingDidEndOnExit = PublishSubject<Void>()
        self.boardNameOverlayGoButtonTap = PublishSubject<Void>()
        self.listNameOverlayGoButtonTap = PublishSubject<Void>()
        self.cardTitleOverlayGoButtonTap = PublishSubject<Void>()
        self.createBoardOverlayGoButtonTap = PublishSubject<Void>()
        self.boardNameOverlaySkipButtonTap = PublishSubject<Void>()
        self.listNameOverlaySkipButtonTap = PublishSubject<Void>()
        self.cardTitleOverlaySkipButtonTap = PublishSubject<Void>()
        self.rightNavForEditingButtonTap = PublishSubject<Void>()
        self.listViewModels = viewModel.board.lists.map {
            return PublishingListViewModel(list: $0)
        }
        self.cardViewModels = viewModel.board.lists.flatMap {
            $0.cards.map {
                return PublishingCardViewModel(card: $0)
            }
        }
        self.viewSize = PublishSubject<CGSize>()
        self.traitCollection = PublishSubject<UITraitCollection>()
        self.keyboardHeight = PublishSubject<CGFloat>()

        let input = OnboardingViewModel.Input(boardNameText: boardNameText.asObservable(),
                                           boardNameEditingDidBegin: boardNameEditingDidBegin.asObservable(),
                                           boardNameEditingChanged: boardNameEditingChanged.asObservable(),
                                           boardNameEditingDidEnd: boardNameEditingDidEnd.asObservable(),
                                           boardNameEditingDidEndOnExit: boardNameEditingDidEndOnExit.asObservable(),
                                           listViewModels: listViewModels,
                                           cardViewModels: cardViewModels,
                                           boardNameOverlayGoButtonsTap: boardNameOverlayGoButtonTap,
                                           listNameOverlayGoButtonsTap: listNameOverlayGoButtonTap,
                                           cardTitleOverlayGoButtonsTap: cardTitleOverlayGoButtonTap,
                                           createBoardOverlayGoButtonsTap: createBoardOverlayGoButtonTap,
                                           boardNameOverlaySkipButtonsTap: boardNameOverlaySkipButtonTap,
                                           listNameOverlaySkipButtonsTap: listNameOverlaySkipButtonTap,
                                           cardTitleOverlaySkipButtonsTap: cardTitleOverlaySkipButtonTap,
                                           rightNavForEditingButtonTap: rightNavForEditingButtonTap,
                                           viewSize: viewSize.asObservable(),
                                           traitCollection: traitCollection.asObservable(),
                                           keyboardHeight: keyboardHeight.asDriver(onErrorJustReturn: 0))
        self.output = self.viewModel.transform(input)
    }

    func testBoardViewContentOffsetReset() {
        let expectations = [expectation(description: "\(#function) 1"),
                            expectation(description: "\(#function) 2"),
                            expectation(description: "\(#function) 3")]
        expectations.forEach { $0.assertForOverFulfill = false }

        self.boardNameOverlayGoButtonTap.onNext(())

        output.boardZeroContentOffset.drive(onNext: { _ in
            expectations[0].fulfill()
        }).disposed(by: disposeBag)

        self.boardNameEditingDidBegin.onNext(())
        self.boardNameText.onNext("BoardName")
        self.boardNameEditingChanged.onNext(())
        self.boardNameEditingDidEnd.onNext(())

        self.listNameOverlayGoButtonTap.onNext(())

        output.boardZeroContentOffset.drive(onNext: { _ in
            expectations[1].fulfill()
        }).disposed(by: disposeBag)

        for (i, listViewModel) in self.listViewModels.enumerated() {
            // Change name
            listViewModel.editingDidBeginSubject.onNext(())
            listViewModel.listNameTextSubject.onNext("ListName \(i)")
            listViewModel.editingChangedSubject.onNext(())
            listViewModel.editingDidEndSubject.onNext(())
        }

        self.cardTitleOverlayGoButtonTap.onNext(())

        output.boardZeroContentOffset.drive(onNext: { _ in
            expectations[2].fulfill()
        }).disposed(by: disposeBag)

        for (i, cardViewModel) in self.cardViewModels.enumerated() {
            cardViewModel.editingDidBeginSubject.onNext(())
            cardViewModel.cardTitleTextSubject.onNext("CardName \(i)")
            cardViewModel.editingChangedSubject.onNext(())
            cardViewModel.editingDidEndSubject.onNext(())
        }

        waitForExpectations(timeout: 5.0) { (err) in
            XCTAssertNil(err)
        }

    }

    func testValidateRealTimeBoardName_doesNotExceedMaxCharacters() {
        var realTimeBoardName: String!

        let characters20 = String(repeating: "a", count: 20)
        let maxCharacters = String(repeating: "a", count: viewModel.boardMaxCharacters)
        let maxPlusOneCharacters = String(repeating: "a", count: viewModel.boardMaxCharacters + 1)

        output.boardNameDisplayText.drive(onNext: { boardName in
            realTimeBoardName = boardName
        }).disposed(by: disposeBag)

        // Starts with the board's default name
        XCTAssertEqual(realTimeBoardName, viewModel.board.defaultName)

        // Insert a 20 character string
        self.boardNameText.onNext(characters20)
        self.boardNameEditingChanged.onNext(())

        XCTAssertEqual(realTimeBoardName, characters20)

        // Try inserting max characters plus one directly, such as if pasting, it should remain at the previous 20 character value
        self.boardNameText.onNext(maxPlusOneCharacters)
        self.boardNameEditingChanged.onNext(())

        XCTAssertEqual(realTimeBoardName, characters20)

        // Insert the max character string, it should succeed, then add one more character, it should remain at max
        self.boardNameText.onNext(maxCharacters)
        self.boardNameEditingChanged.onNext(())
        self.boardNameText.onNext(maxPlusOneCharacters)
        self.boardNameEditingChanged.onNext(())

        XCTAssertEqual(realTimeBoardName, maxCharacters)
    }

    func testValidateFinalBoardName_fallsBackToDefaultBoardNameIfEmpty() {
        var finalBoardName: String!

        output.boardNameDisplayText.drive(onNext: { boardName in
            finalBoardName = boardName
        }).disposed(by: disposeBag)

        // Insert the empty string
        self.boardNameText.onNext("")
        self.boardNameEditingDidEnd.onNext(())

        XCTAssertEqual(finalBoardName, viewModel.board.defaultName)
    }

    func testValidateRealTimeListName_doesNotExceedMaxCharacters() {
        for (index, listViewModel) in self.listViewModels.enumerated() {
            var realTimeListName: String!

            let characters20 = String(repeating: "a", count: 20)
            let maxCharacters = String(repeating: "a", count: viewModel.listMaxCharacters)
            let maxPlusOneCharacters = String(repeating: "a", count: viewModel.boardMaxCharacters + 1)

            output.listNameDisplayTexts[index].drive(onNext: { listName in
                realTimeListName = listName
            }).disposed(by: disposeBag)

            // Starts with the list's default name
            XCTAssertEqual(realTimeListName, viewModel.board.lists[index].defaultName)

            // Insert a 20 character string
            listViewModel.listNameTextSubject.onNext(characters20)
            listViewModel.editingChangedSubject.onNext(())

            XCTAssertEqual(realTimeListName, characters20)

            // Try inserting characters plus one directly, such as if pasting, it should remain at the previous 20 character value
            listViewModel.listNameTextSubject.onNext(maxPlusOneCharacters)
            listViewModel.editingChangedSubject.onNext(())

            XCTAssertEqual(realTimeListName, characters20)

            // Insert a max character string, it should succeed, then add one more character, it should remain at max
            listViewModel.listNameTextSubject.onNext(maxCharacters)
            listViewModel.editingChangedSubject.onNext(())
            listViewModel.listNameTextSubject.onNext(maxPlusOneCharacters)
            listViewModel.editingChangedSubject.onNext(())

            XCTAssertEqual(realTimeListName, maxCharacters)
        }

    }

    func testValidateFinalListName_fallsBackToDefaultListNameIfEmpty() {
        for (index, listViewModel) in self.listViewModels.enumerated() {
            var finalListName: String!

            output.listNameDisplayTexts[index].drive(onNext: { listName in
                finalListName = listName
            }).disposed(by: disposeBag)

            // Insert the empty string
            listViewModel.listNameTextSubject.onNext("")
            listViewModel.editingDidEndSubject.onNext(())

            XCTAssertEqual(finalListName, listViewModel.list.defaultName)
        }
    }

    func testBoardNameOverlayGoButton_focusesBoardNameTextField() {
        var isFocused = false

        output.focusBoardNameTextField.drive(onNext: { (didFocus) in
            isFocused = didFocus
        }).disposed(by: disposeBag)

        // Tap the board name overlay Go button
        self.boardNameOverlayGoButtonTap.onNext(())

        XCTAssertTrue(isFocused)
    }

    func testListNameOverlayGoButton_focusesFirstNameTextField() {
        var isFocused = [false, false, false]

        for (index, focusListTextField) in output.focusListNameTextFields.enumerated() {
            focusListTextField.drive(onNext: { (didFocus) in
                isFocused[index] = didFocus
            }).disposed(by: disposeBag)
        }

        // Tap the list name overlay Go button
        self.listNameOverlayGoButtonTap.onNext(())

        XCTAssertTrue(isFocused[0])
        XCTAssertFalse(isFocused[1])
        XCTAssertFalse(isFocused[2])
    }

    func testSizeClassChangeHidesViews() {
        var compactUIHidden: Bool!
        var regularUIHidden: Bool!
        output.compactUIHidden.drive(onNext: { compactUIHidden = $0 }).disposed(by: disposeBag)
        output.regularUIHidden.drive(onNext: { regularUIHidden = $0 }).disposed(by: disposeBag)

        self.traitCollection.onNext(UITraitCollection(horizontalSizeClass: .compact))
        XCTAssertEqual(compactUIHidden, false)
        XCTAssertEqual(compactUIHidden, !regularUIHidden)

        self.traitCollection.onNext(UITraitCollection(horizontalSizeClass: .regular))
        XCTAssertEqual(compactUIHidden, true)
        XCTAssertEqual(compactUIHidden, !regularUIHidden)
    }

    func testSizeClassChangeMovesBoardOver() {
        var boardLeadingConstant: CGFloat!
        output.boardLeadingConstant.drive(onNext: { boardLeadingConstant = $0 }).disposed(by: disposeBag)

        self.traitCollection.onNext(UITraitCollection(horizontalSizeClass: .compact))
        XCTAssertEqual(boardLeadingConstant, 8.0)

        self.traitCollection.onNext(UITraitCollection(horizontalSizeClass: .regular))
        XCTAssertGreaterThan(boardLeadingConstant, self.stylesheet.overlayRegularWidth)
    }

    func testValidateRealTimeCardTitle_doesNotExceedMaxCharacters() {
        for (index, cardViewModel) in self.cardViewModels.enumerated() {
            var realTimeCardTitle: String!

            let characters20 = String(repeating: "a", count: 20)
            let maxCharacters = String(repeating: "a", count: viewModel.cardMaxCharacters)
            let maxPlusOneCharacters = String(repeating: "a", count: viewModel.boardMaxCharacters + 1)

            output.cardTitleDisplayTexts[index].drive(onNext: { cardTitle in
                realTimeCardTitle = cardTitle
            }).disposed(by: disposeBag)

            // Starts with the card's default name
            XCTAssertEqual(realTimeCardTitle, "")

            // Insert a 20 character string
            cardViewModel.cardTitleTextSubject.onNext(characters20)
            cardViewModel.editingChangedSubject.onNext(())

            XCTAssertEqual(realTimeCardTitle, characters20)

            // Try inserting characters plus one directly, such as if pasting, it should remain at the previous 20 character value
            cardViewModel.cardTitleTextSubject.onNext(maxPlusOneCharacters)
            cardViewModel.editingChangedSubject.onNext(())

            XCTAssertEqual(realTimeCardTitle, characters20)

            // Insert a max character string, it should succeed, then add one more character, it should remain at max
            cardViewModel.cardTitleTextSubject.onNext(maxCharacters)
            cardViewModel.editingChangedSubject.onNext(())
            cardViewModel.cardTitleTextSubject.onNext(maxPlusOneCharacters)
            cardViewModel.editingChangedSubject.onNext(())

            XCTAssertEqual(realTimeCardTitle, maxCharacters)
        }

    }

    func testSkipButtonMovesOverlay() {
        var leadingConstant: CGFloat!
        output.overlayLeadingConstraintConstant.drive(onNext: { leadingConstant = $0 }).disposed(by: disposeBag)

        let width: CGFloat = 100
        self.viewSize.onNext(CGSize(width: width, height: width * 10))

        XCTAssertEqual(leadingConstant, 0)

        self.boardNameOverlaySkipButtonTap.onNext(())
        XCTAssertEqual(leadingConstant, -width)

        self.listNameOverlaySkipButtonTap.onNext(())
        XCTAssertEqual(leadingConstant, -width * 2)

        self.cardTitleOverlaySkipButtonTap.onNext(())
        XCTAssertEqual(leadingConstant, -width * 3)
    }

    func testSkipButtonFadesOverlays() {
        var alpha: [CGFloat] = [0, 0, 0, 0]

        output.overlayFadeAnimations(.describeBoard).drive(onNext: { alpha[0] = $0 }).disposed(by: disposeBag)
        output.overlayFadeAnimations(.describeList).drive(onNext: { alpha[1] = $0 }).disposed(by: disposeBag)
        output.overlayFadeAnimations(.describeCard).drive(onNext: { alpha[2] = $0 }).disposed(by: disposeBag)
        output.overlayFadeAnimations(.createBoard).drive(onNext: { alpha[3] = $0 }).disposed(by: disposeBag)

        XCTAssertEqual(alpha[0], 1)
        XCTAssertEqual(alpha[1], 0)
        XCTAssertEqual(alpha[2], 0)
        XCTAssertEqual(alpha[3], 0)

        self.boardNameOverlaySkipButtonTap.onNext(())
        XCTAssertEqual(alpha[0], 0)
        XCTAssertEqual(alpha[1], 1)
        XCTAssertEqual(alpha[2], 0)
        XCTAssertEqual(alpha[3], 0)

        self.listNameOverlaySkipButtonTap.onNext(())
        XCTAssertEqual(alpha[0], 0)
        XCTAssertEqual(alpha[1], 0)
        XCTAssertEqual(alpha[2], 1)
        XCTAssertEqual(alpha[3], 0)

        self.cardTitleOverlaySkipButtonTap.onNext(())
        XCTAssertEqual(alpha[0], 0)
        XCTAssertEqual(alpha[1], 0)
        XCTAssertEqual(alpha[2], 0)
        XCTAssertEqual(alpha[3], 1)
    }

    func testBoardEdit(editFn: () -> ()) -> BoardTemplate.Board {
        var board: BoardTemplate.Board!

        output.createBoard.subscribe(onSuccess: { board = $0 }).disposed(by: disposeBag)

        editFn()

        return board
    }

    func testCustomizedBoardName() {

        let board = testBoardEdit {

            self.boardNameOverlayGoButtonTap.onNext(())

            self.boardNameEditingDidBegin.onNext(())
            self.boardNameText.onNext("BoardName")
            self.boardNameEditingChanged.onNext(())
            self.boardNameEditingDidEnd.onNext(())

            self.listNameOverlaySkipButtonTap.onNext(())
            self.cardTitleOverlaySkipButtonTap.onNext(())
            self.createBoardOverlayGoButtonTap.onNext(())
        }

        XCTAssertEqual(board.boardName, "BoardName")
    }

    func testCustomizedBoardNameReset() {
        let board = testBoardEdit {
            self.boardNameEditingDidBegin.onNext(())
            self.boardNameText.onNext("BoardName")
            self.boardNameEditingChanged.onNext(())
            self.boardNameEditingDidEnd.onNext(())

            // Go back to default
            self.boardNameEditingDidBegin.onNext(())
            self.boardNameText.onNext("")
            self.boardNameEditingChanged.onNext(())
            self.boardNameEditingDidEnd.onNext(())

            self.listNameOverlaySkipButtonTap.onNext(())
            self.cardTitleOverlaySkipButtonTap.onNext(())
            self.createBoardOverlayGoButtonTap.onNext(())
        }
        XCTAssertEqual(board.boardName, viewModel.board.defaultName)
    }

    func testCustomizedListName() {
        let board = testBoardEdit {

            self.boardNameOverlaySkipButtonTap.onNext(())

            for (i, listViewModel) in self.listViewModels.enumerated() {
                // Change name
                listViewModel.editingDidBeginSubject.onNext(())
                listViewModel.listNameTextSubject.onNext("ListName \(i)")
                listViewModel.editingChangedSubject.onNext(())
                listViewModel.editingDidEndSubject.onNext(())
            }

            self.cardTitleOverlaySkipButtonTap.onNext(())
            self.createBoardOverlayGoButtonTap.onNext(())
        }

        for i in 0..<self.listViewModels.count {
            XCTAssertEqual(board.lists[i].listName, "ListName \(i)")
        }
    }

    func testCustomizedListNameReset() {
        let board = testBoardEdit {

            self.boardNameOverlaySkipButtonTap.onNext(())

            for (i, listViewModel) in self.listViewModels.enumerated() {
                // Change name
                listViewModel.editingDidBeginSubject.onNext(())
                listViewModel.listNameTextSubject.onNext("ListName \(i)")
                listViewModel.editingChangedSubject.onNext(())
                listViewModel.editingDidEndSubject.onNext(())

                // Go back to default
                listViewModel.editingDidBeginSubject.onNext(())
                listViewModel.listNameTextSubject.onNext("")
                listViewModel.editingChangedSubject.onNext(())
                listViewModel.editingDidEndSubject.onNext(())
            }

            self.cardTitleOverlaySkipButtonTap.onNext(())
            self.createBoardOverlayGoButtonTap.onNext(())
        }

        for i in 0..<self.listViewModels.count {
            XCTAssertEqual(board.lists[i].listName, viewModel.board.lists[i].defaultName)
        }
    }

    func testCustomizedCardName() {
        // Keep track of all indexpaths so that we can check later that it matches the expected number of tests
        var testSet = Set<IndexPath>()

        let board = testBoardEdit {

            self.boardNameOverlaySkipButtonTap.onNext(())
            self.listNameOverlaySkipButtonTap.onNext(())

            for (i, cardViewModel) in self.cardViewModels.enumerated() {
                let cardIndexPath = viewModel.board.cardIndexPath(cardIndex: i)
                let listPos = cardIndexPath.section
                let cardPos = cardIndexPath.row

                XCTAssertLessThan(listPos, viewModel.board.lists.count)
                XCTAssertLessThan(cardPos, viewModel.board.lists[listPos].cards.count)
                testSet.insert(cardIndexPath)

                // Change name
                cardViewModel.editingDidBeginSubject.onNext(())
                cardViewModel.cardTitleTextSubject.onNext("CardName \(i)")
                cardViewModel.editingChangedSubject.onNext(())
                cardViewModel.editingDidEndSubject.onNext(())
            }

            self.createBoardOverlayGoButtonTap.onNext(())
        }

        for i in 0..<self.cardViewModels.count {
            let cardIndexPath = board.cardIndexPath(cardIndex: i)
            let listPos = cardIndexPath.section
            let cardPos = cardIndexPath.row
            XCTAssertEqual(board.lists[listPos].cards[cardPos].customCardName, "CardName \(i)")
        }

        XCTAssertEqual(testSet.count, cardViewModels.count)

    }

    func testCustomizedCardNameReset() {
        // Keep track of all indexpaths so that we can check later that it matches the expected number of tests
        var testSet = Set<IndexPath>()

        let board = testBoardEdit {

            self.boardNameOverlaySkipButtonTap.onNext(())
            self.listNameOverlaySkipButtonTap.onNext(())

            for (i, cardViewModel) in self.cardViewModels.enumerated() {
                let cardIndexPath = viewModel.board.cardIndexPath(cardIndex: i)
                let listPos = cardIndexPath.section
                let cardPos = cardIndexPath.row

                XCTAssertLessThan(listPos, viewModel.board.lists.count)
                XCTAssertLessThan(cardPos, viewModel.board.lists[listPos].cards.count)
                testSet.insert(cardIndexPath)

                // Change name
                cardViewModel.editingDidBeginSubject.onNext(())
                cardViewModel.cardTitleTextSubject.onNext("CardName \(i)")
                cardViewModel.editingChangedSubject.onNext(())
                cardViewModel.editingDidEndSubject.onNext(())

                // Go back to nil
                cardViewModel.editingDidBeginSubject.onNext(())
                cardViewModel.cardTitleTextSubject.onNext("")
                cardViewModel.editingChangedSubject.onNext(())
                cardViewModel.editingDidEndSubject.onNext(())
            }

            self.createBoardOverlayGoButtonTap.onNext(())
        }

        for i in 0..<self.cardViewModels.count {
            let cardIndexPath = board.cardIndexPath(cardIndex: i)
            let listPos = cardIndexPath.section
            let cardPos = cardIndexPath.row
            XCTAssertNil(board.lists[listPos].cards[cardPos].customCardName)
        }

        XCTAssertEqual(testSet.count, cardViewModels.count)
    }

    func testNavButtonHidesAndShowsForCorrectFlowStates() {
        var hidden = true

        output.rightNavForEditingButtonHidden.drive(onNext: { isHidden in
            hidden = isHidden
        }).disposed(by: disposeBag)

        // Should move to nameBoard step
        self.boardNameEditingDidBegin.onNext(())
        XCTAssertFalse(hidden)

        // Should move to finishBoard step
        self.boardNameEditingDidEnd.onNext(())
        XCTAssertTrue(hidden)

        // Should move to nameList step
        self.listViewModels[0].editingDidBeginSubject.onNext(())
        XCTAssertFalse(hidden)

        // Should move to finishList step
        self.listViewModels[0].editingDidEndSubject.onNext(())
        XCTAssertTrue(hidden)

        // Should move to nameCard step
        self.cardViewModels[0].editingDidBeginSubject.onNext(())
        XCTAssertFalse(hidden)

        // Should move to finishCard step
        self.cardViewModels[0].editingDidEndSubject.onNext(())
        XCTAssertTrue(hidden)
    }

    func testListTextFieldDidEndOnExitNextType_focusesNextListTextField() {
        var isFocused = [false, false, false]

        // Get the state to list editing
        self.boardNameOverlayGoButtonTap.onNext(())
        self.rightNavForEditingButtonTap.onNext(())
        self.listNameOverlayGoButtonTap.onNext(())

        // When the second list name text field should be focused
        output.focusListNameTextFields[1].drive(onNext: { focused in
            isFocused[1] = focused
        }).disposed(by: disposeBag)

        // When the third list name text field should be focused
        output.focusListNameTextFields[2].drive(onNext: { focused in
            isFocused[2] = focused
        }).disposed(by: disposeBag)

        // Simulate hitting the 'Next' keyboard return key on the first list text field
        self.listViewModels[0].editingDidEndOnExitSubject.onNext(())
        XCTAssertTrue(isFocused[1])

        // Simulate hitting the 'Next' keyboard return key on the second list text field
        self.listViewModels[1].editingDidEndOnExitSubject.onNext(())
        XCTAssertTrue(isFocused[2])
    }

    func testCardTextFieldDidEndOnExitNextType_focusesNextCardTextField() {
        var isFocused = [false, false, false, false, false]

        // Get the state to card editing
        self.boardNameOverlayGoButtonTap.onNext(())
        self.rightNavForEditingButtonTap.onNext(())
        self.listNameOverlayGoButtonTap.onNext(())
        self.rightNavForEditingButtonTap.onNext(())
        self.cardTitleOverlayGoButtonTap.onNext(())

        // When the second card title text field should be focused
        output.focusCardTitleTextFields[1].drive(onNext: { focused in
            isFocused[1] = focused
        }).disposed(by: disposeBag)

        // When the third card title text field should be focused
        output.focusCardTitleTextFields[2].drive(onNext: { focused in
            isFocused[2] = focused
        }).disposed(by: disposeBag)

        // When the fourth card title text field should be focused
        output.focusCardTitleTextFields[3].drive(onNext: { focused in
            isFocused[3] = focused
        }).disposed(by: disposeBag)

        // When the fifth card title text field should be focused
        output.focusCardTitleTextFields[4].drive(onNext: { focused in
            isFocused[4] = focused
        }).disposed(by: disposeBag)

        // Simulate hitting the 'Next' keyboard return key on the first card text field
        self.cardViewModels[0].editingDidEndOnExitSubject.onNext(())
        XCTAssertTrue(isFocused[1])

        // Simulate hitting the 'Next' keyboard return key on the second card text field
        self.cardViewModels[1].editingDidEndOnExitSubject.onNext(())
        XCTAssertTrue(isFocused[2])

        // Simulate hitting the 'Next' keyboard return key on the third card text field
        self.cardViewModels[2].editingDidEndOnExitSubject.onNext(())
        XCTAssertTrue(isFocused[3])

        // Simulate hitting the 'Next' keyboard return key on the fourth card text field
        self.cardViewModels[3].editingDidEndOnExitSubject.onNext(())
        XCTAssertTrue(isFocused[4])
    }

    func testFocusingBoardNameTextField_selectsAllTextOnlyOnce() {
        var didSelectAllText = false

        output.boardNameTextFieldSelectAllText.drive(onNext: { _ in
            didSelectAllText = true
        }).disposed(by: disposeBag)

        self.boardNameEditingDidBegin.onNext(())

        XCTAssertTrue(didSelectAllText)

        // The above portion tests if select all is called, the below portion makes sure it only happens once
        didSelectAllText = false

        self.boardNameEditingDidBegin.onNext(())

        XCTAssertFalse(didSelectAllText)
    }

    func testFocusingListNameTextFields_selectsAllTextOnlyOnce() {
        var didSelectAllText = [false, false, false]

        output.listNameTextFieldsSelectAllText[0].drive(onNext: { _ in
            didSelectAllText[0] = true
        }).disposed(by: disposeBag)

        output.listNameTextFieldsSelectAllText[1].drive(onNext: { _ in
            didSelectAllText[1] = true
        }).disposed(by: disposeBag)

        output.listNameTextFieldsSelectAllText[2].drive(onNext: { _ in
            didSelectAllText[2] = true
        }).disposed(by: disposeBag)

        self.listViewModels[0].editingDidBeginSubject.onNext(())
        self.listViewModels[1].editingDidBeginSubject.onNext(())
        self.listViewModels[2].editingDidBeginSubject.onNext(())

        XCTAssertEqual([true, true, true], didSelectAllText)

        // The above portion tests if select all is called, the below portion makes sure it only happens once per text field
        didSelectAllText = [false, false, false]

        self.listViewModels[0].editingDidBeginSubject.onNext(())
        self.listViewModels[1].editingDidBeginSubject.onNext(())
        self.listViewModels[2].editingDidBeginSubject.onNext(())

        XCTAssertEqual([false, false, false], didSelectAllText)
    }

    func waitForAsyncOrDebounce(interval: RxTimeInterval = 0.5) {
        let wait = expectation(description: "firstWait")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            wait.fulfill()
        }
        waitForExpectations(timeout: interval + 1.0)
    }

    func testKeyboardHidesOverlay() {
        var alpha: [CGFloat?] = [nil, nil, nil, nil]

        output.overlayFadeAnimations(.describeBoard).drive(onNext: { alpha[0] = $0 }).disposed(by: disposeBag)
        output.overlayFadeAnimations(.describeList).drive(onNext: { alpha[1] = $0 }).disposed(by: disposeBag)
        output.overlayFadeAnimations(.describeCard).drive(onNext: { alpha[2] = $0 }).disposed(by: disposeBag)
        output.overlayFadeAnimations(.createBoard).drive(onNext: { alpha[3] = $0 }).disposed(by: disposeBag)

        self.keyboardHeight.onNext(0)
        self.traitCollection.onNext(UITraitCollection(horizontalSizeClass: .compact))

        XCTAssertEqual(alpha[0], 1)
        XCTAssertEqual(alpha[1], 0)
        XCTAssertEqual(alpha[2], 0)
        XCTAssertEqual(alpha[3], 0)

        self.keyboardHeight.onNext(200)
        waitForAsyncOrDebounce()

        XCTAssertEqual(alpha[0], 0)
        XCTAssertEqual(alpha[1], 0)
        XCTAssertEqual(alpha[2], 0)
        XCTAssertEqual(alpha[3], 0)

        self.boardNameOverlaySkipButtonTap.onNext(())

        XCTAssertEqual(alpha[0], 0)
        XCTAssertEqual(alpha[1], 0)
        XCTAssertEqual(alpha[2], 0)
        XCTAssertEqual(alpha[3], 0)

        self.keyboardHeight.onNext(0)
        waitForAsyncOrDebounce()

        XCTAssertEqual(alpha[0], 0)
        XCTAssertEqual(alpha[1], 1)
        XCTAssertEqual(alpha[2], 0)
        XCTAssertEqual(alpha[3], 0)
    }

    func testKeyboardDrivesBottomOfBoard() {
        var bottomConstant: CGFloat? = nil

        output.boardBottomConstant.drive(onNext: { bottomConstant = $0 }).disposed(by: disposeBag)

        self.keyboardHeight.onNext(0)
        waitForAsyncOrDebounce()
        self.traitCollection.onNext(UITraitCollection(horizontalSizeClass: .compact))

        XCTAssertEqual(bottomConstant, -stylesheet.gridUnit)

        self.keyboardHeight.onNext(200)
        waitForAsyncOrDebounce()

        XCTAssertEqual(bottomConstant, -(200+stylesheet.gridUnit))
    }

    func testListsHideCardsAtEditingStep() {
        var hideCards: [Bool?] = [nil, nil, nil]

        for i in 0..<hideCards.count {
            output.listShouldHideCards[i].drive(onNext: { hideCards[i] = $0 }).disposed(by: disposeBag)
        }

        XCTAssertEqual(hideCards[0], false)
        XCTAssertEqual(hideCards[1], false)
        XCTAssertEqual(hideCards[2], false)

        self.boardNameOverlaySkipButtonTap.onNext(())

        XCTAssertEqual(hideCards[0], false)
        XCTAssertEqual(hideCards[1], false)
        XCTAssertEqual(hideCards[2], false)

        self.listNameOverlaySkipButtonTap.onNext(())

        XCTAssertEqual(hideCards[0], false)
        XCTAssertEqual(hideCards[1], true)
        XCTAssertEqual(hideCards[2], true)
    }

    func testSkipRightNavButtonState() {
        var hide: Bool? = nil
        var text: String? = nil

        output.rightNavForOverlaySkipButtonHidden.drive(onNext: { hide = $0 }).disposed(by: disposeBag)
        output.rightNavForOverlaySkipButtonText.drive(onNext: { text = $0 }).disposed(by: disposeBag)

        waitForAsyncOrDebounce(interval: 0.1)

        XCTAssertEqual(hide, false)
        XCTAssertEqual(text, "Skip")

        self.boardNameOverlaySkipButtonTap.onNext(())
        waitForAsyncOrDebounce(interval: 0.1)

        XCTAssertEqual(hide, false)
        XCTAssertEqual(text, "Skip")

        self.listNameOverlaySkipButtonTap.onNext(())
        waitForAsyncOrDebounce(interval: 0.1)

        XCTAssertEqual(hide, false)
        XCTAssertEqual(text, "Skip")

        self.cardTitleOverlaySkipButtonTap.onNext(())
        waitForAsyncOrDebounce(interval: 0.1)

        XCTAssertEqual(hide, false)
        XCTAssertEqual(text, "Finish")
    }

    func testSkipRightNavButtonStateWhenEditing() {
        var hide: Bool? = nil
        var text: String? = nil

        output.rightNavForOverlaySkipButtonHidden.drive(onNext: { hide = $0 }).disposed(by: disposeBag)
        output.rightNavForOverlaySkipButtonText.drive(onNext: { text = $0 }).disposed(by: disposeBag)

        self.boardNameOverlayGoButtonTap.onNext(())
        self.boardNameEditingDidBegin.onNext(())
        waitForAsyncOrDebounce(interval: 0.1)
        XCTAssertEqual(hide, true)

        self.boardNameOverlaySkipButtonTap.onNext(())
        self.boardNameEditingDidEnd.onNext(())
        waitForAsyncOrDebounce(interval: 0.1)
        XCTAssertEqual(hide, false)
        XCTAssertEqual(text, "Skip")

        self.listNameOverlayGoButtonTap.onNext(())
        for listViewModel in self.listViewModels {
            listViewModel.editingDidBeginSubject.onNext(())
            waitForAsyncOrDebounce(interval: 0.1)
            XCTAssertEqual(hide, true)
            listViewModel.editingDidEndSubject.onNext(())
        }
        waitForAsyncOrDebounce(interval: 0.1)
        XCTAssertEqual(hide, false)
        XCTAssertEqual(text, "Skip")

        for cardViewModel in self.cardViewModels {
            cardViewModel.editingDidBeginSubject.onNext(())
            waitForAsyncOrDebounce(interval: 0.1)
            XCTAssertEqual(hide, true)
            cardViewModel.editingDidEndSubject.onNext(())
        }
        waitForAsyncOrDebounce(interval: 0.1)
        XCTAssertEqual(hide, false)
        XCTAssertEqual(text, "Finish")
    }

    func testHintBorderShownOnBoardNameTextField() {
        var shown = true

        output.boardNameTextFieldShowHintBorder.drive(onNext: { (isShown) in
            shown = isShown
        }).disposed(by: disposeBag)

        self.boardNameOverlayGoButtonTap.onNext(())
        self.boardNameEditingDidBegin.onNext(())

        XCTAssertFalse(shown)
    }

    func testHintBorderShownOnListNameTextFields() {
        var shown = false

        output.firstListNameTextFieldShowHintBorder.drive(onNext: { (isShown) in
            shown = isShown
        }).disposed(by: disposeBag)

        self.boardNameOverlaySkipButtonTap.onNext(())

        XCTAssertTrue(shown)

        self.listNameOverlaySkipButtonTap.onNext(())

        XCTAssertFalse(shown)
    }

    func testHintBorderShownOnCardTitleTextFields() {
        var shown = false

        output.firstCardTitleTextFieldShowHintBorder.drive(onNext: { (isShown) in
            shown = isShown
        }).disposed(by: disposeBag)

        self.boardNameOverlaySkipButtonTap.onNext(())

        XCTAssertFalse(shown)

        self.listNameOverlaySkipButtonTap.onNext(())

        XCTAssertTrue(shown)

        self.cardTitleOverlaySkipButtonTap.onNext(())

        XCTAssertFalse(shown)
    }

    func testBoardNameOverlayButtonDisabledAfterBoardNamingStep() {
        var enabled = true

        output.boardNamingOverlayButtonEnabled.drive(onNext: { (isEnabled) in
            enabled = isEnabled
        }).disposed(by: disposeBag)

        self.boardNameOverlayGoButtonTap.onNext(())
        self.boardNameEditingDidBegin.onNext(())

        XCTAssertFalse(enabled)
    }

    func testListNameOverlayButtonDisabledAfterListNamingStep() {
        var enabled = true

        output.listNamingOverlayButtonEnabled.drive(onNext: { (isEnabled) in
            enabled = isEnabled
        }).disposed(by: disposeBag)

        self.boardNameOverlaySkipButtonTap.onNext(())

        XCTAssertTrue(enabled)

        self.listNameOverlayGoButtonTap.onNext(())
        self.listViewModels.first?.editingDidBeginSubject.onNext(())

        XCTAssertFalse(enabled)
    }

    func testCardTitleOverlayButtonDisabledAfterCardNamingStep() {
        var enabled = true

        output.cardNamingOverlayButtonEnabled.drive(onNext: { (isEnabled) in
            enabled = isEnabled
        }).disposed(by: disposeBag)

        self.boardNameOverlaySkipButtonTap.onNext(())
        self.listNameOverlaySkipButtonTap.onNext(())

        XCTAssertTrue(enabled)

        self.cardTitleOverlayGoButtonTap.onNext(())
        self.cardViewModels.first?.editingDidBeginSubject.onNext(())

        XCTAssertFalse(enabled)
    }


    func testOnlyOneRightNavShouldShow() {
        var hideEdit: Bool? = nil
        var hideSkip: Bool? = nil

        output.rightNavForOverlaySkipButtonHidden.drive(onNext: { hideSkip = $0 }).disposed(by: disposeBag)
        output.rightNavForEditingButtonHidden.drive(onNext: { hideEdit = $0 }).disposed(by: disposeBag)

        // One of these buttons is showing, but not both
        XCTAssertNotEqual(hideEdit!, hideSkip!)


        self.boardNameOverlayGoButtonTap.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        self.boardNameEditingDidBegin.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        self.boardNameOverlaySkipButtonTap.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        self.boardNameEditingDidEnd.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)

        self.listNameOverlayGoButtonTap.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        for listViewModel in self.listViewModels {
            XCTAssertFalse(!hideEdit! && !hideSkip!) // neither are showing or just one is showing
            listViewModel.editingDidBeginSubject.onNext(())
            XCTAssertNotEqual(hideEdit!, hideSkip!)
            listViewModel.editingDidEndSubject.onNext(())
            XCTAssertFalse(!hideEdit! && !hideSkip!) // neither are showing or just one is showing
        }
        XCTAssertNotEqual(hideEdit!, hideSkip!)

        for cardViewModel in self.cardViewModels {
            XCTAssertFalse(!hideEdit! && !hideSkip!) // neither are showing or just one is showing
            cardViewModel.editingDidBeginSubject.onNext(())
            XCTAssertNotEqual(hideEdit!, hideSkip!)
            cardViewModel.editingDidEndSubject.onNext(())
            XCTAssertFalse(!hideEdit! && !hideSkip!) // neither are showing or just one is showing
        }
        XCTAssertNotEqual(hideEdit!, hideSkip!)
    }

    func testOnlyOneRightNavShouldShowWhenEditingSkippedThings() {
        var hideEdit: Bool? = nil
        var hideSkip: Bool? = nil

        output.rightNavForOverlaySkipButtonHidden.drive(onNext: { hideSkip = $0 }).disposed(by: disposeBag)
        output.rightNavForEditingButtonHidden.drive(onNext: { hideEdit = $0 }).disposed(by: disposeBag)

        XCTAssertNotEqual(hideEdit!, hideSkip!)

        self.boardNameOverlaySkipButtonTap.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)

        // We are on list step, but we go back and edit board
        self.boardNameOverlayGoButtonTap.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        self.boardNameEditingDidBegin.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        self.rightNavForEditingButtonTap.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        self.boardNameEditingDidEnd.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)

        // We tap name lists
        self.listNameOverlayGoButtonTap.onNext(())

        // We are naming lists, but we go back and edit board
        self.boardNameOverlayGoButtonTap.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        self.boardNameEditingDidBegin.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        self.rightNavForEditingButtonTap.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
        self.boardNameEditingDidEnd.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)

        self.cardTitleOverlaySkipButtonTap.onNext(())
        XCTAssertNotEqual(hideEdit!, hideSkip!)
    }

}

