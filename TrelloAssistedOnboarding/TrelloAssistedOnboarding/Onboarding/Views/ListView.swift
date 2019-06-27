//
//  ListView.swift
//  Trellis
//
//  Created by Lou Franco on 4/15/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// A view for showing a Trello-like list with cards in the Mad Libs onboarding UI.
class ListView: UIView {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let stylesheet = Stylesheet()
    let nameTextField = RoundedBorderedTextField(borderColor: .trelloBlue500)
    let namePlaceholder = UIView(frame: .zero)
    let cardViews: [CardView]
    let cardStackView = UIStackView(frame: .zero)
    let disposeBag = DisposeBag()

    // Whether the list view should hide its cards (remove them from the view so the list height changes)
    var shouldHideCards: Bool = false {
        didSet {
            setupCards()
        }
    }
    
    /// Creates a Mad Libs list with a given name and number of cards
    /// - Parameters:
    ///     - name: the name of the list
    ///     - numCards: the number of cards to create for the list
    init(_ list: BoardTemplate.List) {
        self.cardViews = list.cards.map { CardView($0) }
        super.init(frame: .zero)
        self.backgroundColor = stylesheet.listBackgroundColor
        self.layer.cornerRadius = stylesheet.listCornerRadius

        self.addAutoLaidOutSubview(self.nameTextField)
        self.nameTextField.accessibilityLabel = "list_name_text_field_accessibility".localized
        self.nameTextField.textColor = stylesheet.listTextColor
        self.nameTextField.textAlignment = .natural
        self.nameTextField.adjustsFontForContentSizeCategory = true
        self.nameTextField.returnKeyType = .done
        self.nameTextField.topAnchor |== self.topAnchor |+ stylesheet.gridUnit
        self.nameTextField.leadingAnchor |== self.leadingAnchor |+ stylesheet.gridUnit
        self.nameTextField.trailingAnchor |== self.trailingAnchor |- stylesheet.gridUnit

        self.addAutoLaidOutSubview(self.namePlaceholder)
        self.namePlaceholder.leadingAnchor |== self.nameTextField.leadingAnchor |+ self.nameTextField.insetDelta
        self.namePlaceholder.widthAnchor |== self.nameTextField.widthAnchor |* 0.40
        self.namePlaceholder.topAnchor |== self.nameTextField.topAnchor |+ self.nameTextField.insetDelta
        self.namePlaceholder.bottomAnchor |== self.nameTextField.bottomAnchor |- self.nameTextField.insetDelta
        self.namePlaceholder.backgroundColor = UIColor.nachosShades300
        self.namePlaceholder.layer.cornerRadius = 6.0

        self.addAutoLaidOutSubview(self.cardStackView)
        self.cardStackView.axis = .vertical
        self.cardStackView.spacing = stylesheet.gridUnit * 2

        self.cardStackView.leadingAnchor |== self.leadingAnchor |+ (stylesheet.gridUnit * 2)
        self.cardStackView.topAnchor |== self.nameTextField.bottomAnchor |+ stylesheet.gridUnit
        self.cardStackView.trailingAnchor |== self.trailingAnchor |- (stylesheet.gridUnit * 2)
        self.cardStackView.bottomAnchor |== self.bottomAnchor |- (stylesheet.gridUnit * 2)

        setupCards()

        // Make the gray listname placeholder have the opposite alpha of the name text field (shows when text field is hidden)
        self.nameTextField.rx
            .observeWeakly(Float.self, #keyPath(RoundedBorderedTextField.layer.opacity)) // alpha isn't observable
            .map { (opacity: Float?) -> CGFloat in CGFloat(1 - (opacity ?? 0)) }
            .bind(to: self.namePlaceholder.rx.alpha)
            .disposed(by: self.disposeBag)

        self.configureFonts()
        
        NotificationCenter.default.rx.notification(UIContentSizeCategory.didChangeNotification)
            .subscribe(onNext: { [weak self] _ in self?.configureFonts() })
            .disposed(by: self.disposeBag)
    }

    func configureFonts() {
        self.nameTextField.font = stylesheet.listNameFont
    }

    func setupCards() {
        if self.shouldHideCards {
            self.cardStackView.arrangedSubviews.forEach({ v in
                v.isHidden = true
            })
        } else {
            if self.cardStackView.arrangedSubviews.count == 0 {
                for c in self.cardViews {
                    self.cardStackView.addArrangedSubview(c)
                }
            }
        }
    }
}

extension Reactive where Base: ListView {

    // Whether the list view should hide its cards (remove them from the view so the list height changes)
    var shouldHideCards: Binder<Bool> {
        return Binder(self.base) { listView, shouldHideCards in
            listView.shouldHideCards = shouldHideCards
        }
    }

}
