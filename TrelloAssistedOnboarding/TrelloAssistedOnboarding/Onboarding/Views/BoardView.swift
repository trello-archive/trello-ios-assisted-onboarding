//
//  BoardView.swift
//  Trellis
//
//  Created by Lou Franco on 4/11/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// The scrollable content view of a BoardView.
class BoardContentView: UIView {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var listTopAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor>?
    var listViews = [ListView]()
    var firstListViewWidthConstraint = NSLayoutConstraint()

    private let stylesheet = Stylesheet()
    private let viewModel: OnboardingViewModel
    
    init(_ viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if self.superview != nil, let listTopAnchor = self.listTopAnchor {
            prepareSubviews(listTopAnchor: listTopAnchor)
        }
    }

    private func prepareSubviews(listTopAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor>) {
        var previousListView: ListView?
        
        for list in self.viewModel.board.lists {
            let listView = ListView(list)
            listViews.append(listView)
            self.addAutoLaidOutSubview(listView)
            listView.topAnchor |== listTopAnchor |+ stylesheet.gridUnit * 2

            if let previousListView = previousListView {
                listView.leadingAnchor |== previousListView.trailingAnchor |+ stylesheet.listSpacing
                listView.widthAnchor |== previousListView.widthAnchor |* 1
            } else {
                listView.leadingAnchor |== self.leadingAnchor |+ stylesheet.listOuterMargin
                self.firstListViewWidthConstraint = listView.widthAnchor |== stylesheet.listZoomedInWidth
            }
            previousListView = listView

            // Make the board big enough to show each list
            self.bottomAnchor |>= listView.bottomAnchor |+ stylesheet.gridUnit
        }
        
        if let previousListView = previousListView {
            previousListView.trailingAnchor |== self.trailingAnchor |- stylesheet.listOuterMargin
        }
    }

}

/// A view to show a Trello-like board in the Mad Libs UI.
class BoardView: UIScrollView {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    let nameTextField = RoundedBorderedTextField(borderColor: .white)
    let tapGesture = UITapGestureRecognizer()

    private let stylesheet = Stylesheet()
    let boardContentView: BoardContentView
    private let viewModel: OnboardingViewModel
    private let disposeBag = DisposeBag()
    
    init(_ viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        self.boardContentView = BoardContentView(viewModel)
        super.init(frame: .zero)
        prepareBoardView()
    }
    
    private func prepareBoardView() {
        self.isDirectionalLockEnabled = true

        self.layer.cornerRadius = stylesheet.boardCornerRadius
        self.backgroundColor = viewModel.board.backgroundColor.uiColor

        self.addGestureRecognizer(self.tapGesture)
        
        self.contentInset = UIEdgeInsets(top: 0, left: stylesheet.gridUnit, bottom: 0, right: stylesheet.gridUnit)

        // Board name field
        self.addAutoLaidOutSubview(nameTextField)
        self.nameTextField.textColor = .white
        self.nameTextField.textAlignment = .natural
        self.nameTextField.returnKeyType = .done
        self.nameTextField.accessibilityLabel = "board_name_text_field_accessibility".localized

        self.nameTextField.topAnchor |== self.topAnchor |+ (stylesheet.gridUnit * 2)
        
        // nameTextField tries to stay in place as the board scrolls
        self.nameTextField.leadingAnchor |== self.frameLayoutGuide.leadingAnchor |+ stylesheet.boardNameMargin
        
        // nameTextField shouldn't be wider than his parents width
        self.nameTextField.widthAnchor |== self.frameLayoutGuide.widthAnchor |- stylesheet.boardNameMargin * 2
        
        // Set the top of the lists to under the name
        self.boardContentView.listTopAnchor = self.nameTextField.bottomAnchor

        // The board needs to be first in the view hierarchy, but we need the name added first to get its bottom anchor in place for lists
        self.insertAutoLaidOutSubview(self.boardContentView, at: 0)

        // The lists will set the size of the board. Use that to set the content size.
        self.boardContentView.topAnchor |== self.contentLayoutGuide.topAnchor
        self.boardContentView.bottomAnchor |== self.contentLayoutGuide.bottomAnchor

        self.boardContentView.leadingAnchor |== self.contentLayoutGuide.leadingAnchor
        self.boardContentView.trailingAnchor |== self.contentLayoutGuide.trailingAnchor

        // Set the name to scroll with the board if forced.
        self.nameTextField.leadingAnchor |== self.frameLayoutGuide.leadingAnchor |+ stylesheet.boardNameMargin
        
        self.configureFonts()
        
        NotificationCenter.default.rx.notification(UIContentSizeCategory.didChangeNotification)
            .subscribe(onNext: { [weak self] _ in self?.configureFonts() })
            .disposed(by: self.disposeBag)
    }
    
    func zoomIn() {
        self.boardContentView.firstListViewWidthConstraint.constant = stylesheet.listZoomedInWidth
        UIView.animate(
            withDuration: stylesheet.standardAnimationDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.layoutIfNeeded()
        })
    }
    
    func zoomOut() {
        self.boardContentView.firstListViewWidthConstraint.constant = stylesheet.listZoomedOutWidth
        UIView.animate(
            withDuration: stylesheet.standardAnimationDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.layoutIfNeeded()
        })
    }
    
    func configureFonts() {
        self.nameTextField.font = stylesheet.boardNameFont
    }
    
}

extension Reactive where Base: BoardView {
    
    // Whether the board view should zoom out and shrink the lists, or zoom back in to normal
    var zoomOut: Binder<Bool> {
        return Binder(self.base) { boardView, shouldZoomOut in
            if shouldZoomOut {
                boardView.zoomOut()
            } else {
                boardView.zoomIn()
            }
        }
    }
    
    // When the board view should reset its contentOffset to 0
    var zeroContentOffsetWithSpringAnimation: Binder<Void> {
        return Binder(self.base) { boardView, _ in
            if boardView.contentOffset.x > 0.0 {
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0.25,
                    usingSpringWithDamping: 0.85,
                    initialSpringVelocity: 0.1,
                    options: [],
                    animations: { boardView.contentOffset = .zero },
                    completion: nil)
            }
        }
    }
    
}
