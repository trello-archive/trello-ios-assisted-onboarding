//
//  CardView.swift
//  Trellis
//
//  Created by Lou Franco on 4/15/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// A view for showing a Trello-like card front on the onboarding UI.
class CardView: UIView {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    let stylesheet = Stylesheet()
    let cardTitleTextField = RoundedBorderedTextField(borderColor: .trelloBlue500)
    let cardPlaceholderText: String
    let disposeBag = DisposeBag()
    var heightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        self.cardPlaceholderText = ""
        super.init(frame: frame)
        self.backgroundColor = stylesheet.cardBackgroundColor
        self.layer.cornerRadius = stylesheet.cardCornerRadius
    }
    
    /// Creates a list with a given name and number of cards
    /// - Parameters:
    ///     - name: the name of the list
    ///     - numCards: the number of cards to create for the list
    init(_ card: BoardTemplate.Card) {
        self.cardPlaceholderText = card.placeholderName
        super.init(frame: .zero)

        self.backgroundColor = stylesheet.listBackgroundColor
        self.layer.cornerRadius = stylesheet.listCornerRadius
        
        self.addAutoLaidOutSubview(self.cardTitleTextField)
        self.cardTitleTextField.accessibilityLabel = "card_title_text_field_accessibility".localized
        self.cardTitleTextField.backgroundColor = .white
        self.cardTitleTextField.textColor = stylesheet.listTextColor
        self.cardTitleTextField.textAlignment = .natural
        self.cardTitleTextField.adjustsFontForContentSizeCategory = true
        self.cardTitleTextField.returnKeyType = .done
        self.cardTitleTextField.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.cardTitleTextField.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.cardTitleTextField.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.cardTitleTextField.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        self.heightConstraint = self.cardTitleTextField.heightAnchor.constraint(equalToConstant: stylesheet.gridUnit * 11)
        self.heightConstraint?.isActive = true
        let layer = self.cardTitleTextField.layer
        layer.shadowColor = stylesheet.shadowColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        
        self.configureFonts()
        
        NotificationCenter.default.rx.notification(UIContentSizeCategory.didChangeNotification)
            .subscribe(onNext: { [weak self] _ in self?.configureFonts() })
            .disposed(by: self.disposeBag)
    }
    
    func configureFonts() {
        self.cardTitleTextField.font = stylesheet.cardTitleFont
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: stylesheet.cardHeight)
    }
}

extension Reactive where Base: CardView {
    
    // Whether the text field should be showing a border
    var isActive: Binder<Bool> {
        return Binder(self.base) { cardView, isActive in
            if isActive {
                if let constraint = cardView.heightConstraint {
                    constraint.isActive = false
                    UIView.animate(
                        withDuration: cardView.stylesheet.standardAnimationDuration,
                        delay: 0.0,
                        options: [.curveEaseOut],
                        animations: {
                            cardView.superview?.superview?.superview?.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    // When the placeholder text should be applied into the text field
    var setPlaceholderText: Binder<Bool> {
        return Binder(self.base) { cardView, setPlaceholderText in
            if setPlaceholderText {
                UIView.animate(
                    withDuration: cardView.stylesheet.standardAnimationDuration,
                    delay: 0.3,
                    options: [.curveEaseOut],
                    animations: {
                        cardView.cardTitleTextField.placeholder = cardView.cardPlaceholderText
                })
            }
        }
    }
    
}
