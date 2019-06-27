//
//  RoundedBorderedTextField.swift
//  Trellis
//
//  Created by Andrew Frederick on 4/26/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RoundedBorderedTextField: UITextField {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    let insetDelta: CGFloat = 8
    let disposeBag = DisposeBag()

    init(borderColor: UIColor) {
        super.init(frame: .zero)
        self.layer.cornerRadius = 6.0;
        self.layer.borderColor = borderColor.cgColor
        self.tintColor = borderColor
        
        // Fixes a bug where the text bounces when resignFirstResponder occurs in combination with the custom text rects in this class
        // if there's an animation block running elsewhere when resignFirstResponder is called.
        // See https://stackoverflow.com/questions/33544054/why-is-uitextfield-animating-on-resignfirstresponder
        self.rx.controlEvent(.editingDidEnd).asDriver().drive(onNext: { [weak self] _ in
            self?.layoutIfNeeded()
        }).disposed(by: disposeBag)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: insetDelta, dy: insetDelta)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: insetDelta, dy: insetDelta)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: insetDelta, dy: insetDelta)
    }

    func showHintBorder() {
        guard self.layer.borderWidth != 1.0 else { return }
        
        UIView.animate(
            withDuration: 0.15,
            delay: 0.0,
            options: [.curveEaseOut],
            animations: {
                self.layer.borderWidth = 1.0
        })
    }
    
    func hideHintBorder() {
        guard self.layer.borderWidth == 1.0 else { return }
        
        UIView.animate(
            withDuration: 0.15,
            delay: 0.0,
            options: [.curveEaseOut],
            animations: {
                self.layer.borderWidth = 0.0
        })
    }
    
    func showBorder() {
        guard self.layer.borderWidth != 2.0 else { return }
        
        UIView.animate(
            withDuration: 0.15,
            delay: 0.0,
            options: [.curveEaseOut],
            animations: {
                self.layer.borderWidth = 2.0
        })
    }
    
    func hideBorder() {
        guard self.layer.borderWidth == 2.0 else { return }

        UIView.animate(
            withDuration: 0.15,
            delay: 0.0,
            options: [.curveEaseInOut],
            animations: {
                self.layer.borderWidth = 0.0
        })
    }
}

extension Reactive where Base: RoundedBorderedTextField {
    
    // Whether the text field should be showing a border
    var showBorder: Binder<Bool> {
        return Binder(self.base) { textField, showBorder in
            if showBorder {
                textField.showBorder()
            } else {
                textField.hideBorder()
            }
        }
    }
    
    // When the text field should be showing the hint border
    var showHintBorder: Binder<Bool> {
        return Binder(self.base) { textField, showBorder in
            if showBorder {
                textField.showHintBorder()
            } else {
                textField.hideHintBorder()
            }
        }
    }
    
}
