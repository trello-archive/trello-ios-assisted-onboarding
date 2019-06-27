//
//  OverlayViewGestureController.swift
//  Trellis
//
//  Created by Lou Franco on 6/18/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

// The pan gesture, its state, and the constraints it makes
class OverlayViewGestureController {

    // Holds the constraint together with its initial constant so we can simply offset/reset it later in the pan
    struct PanConstraint {
        let constraint: NSLayoutConstraint
        let initialConstant: CGFloat

        init?(view: UIView, attribute: NSLayoutConstraint.Attribute) {
            guard let superview = view.superview, (attribute == .leading || attribute == .top) else { return nil }
            self.initialConstant = attribute == .leading ? view.frame.origin.x : view.frame.origin.y
            self.constraint = NSLayoutConstraint(item: view, attribute: attribute, relatedBy: .equal, toItem: superview, attribute: attribute, multiplier: 1, constant: initialConstant)
            constraint.priority = .required
            constraint.isActive = true
        }

        func deactivate() {
            self.constraint.isActive = false
        }

        func reset() {
            self.constraint.constant = initialConstant
        }

        func offset(_ offset: CGPoint) {
            if self.constraint.firstAttribute == .leading {
                // Allow pans to the left/right if we have a leading constraint
                // Dampen the pan a lot so that it really resists sliding
                if offset.x < 0 {
                    self.constraint.constant = initialConstant - pow(-offset.x, 0.75)
                } else {
                    self.constraint.constant = initialConstant + pow(offset.x, 0.75)
                }
            } else if self.constraint.firstAttribute == .top {
                // Allow downward pans if we have a top constraint
                if offset.y > 0 {
                    // Dampen the pan just a little so that it never hits the bottom
                    self.constraint.constant = initialConstant + pow(offset.y, 0.95)
                }
            }
        }
    }

    private var panConstraint: PanConstraint?
    private let gesture = UIPanGestureRecognizer(target: nil, action: nil)

    private let disposeBag = DisposeBag()

    init(view: UIView) {
        view.addGestureRecognizer(self.gesture)
        configure()
    }

    /// Connects a pan gesture to the overlay to let the user
    ///  1. Drag it down so that they can see more of what is behind it
    ///  2. Rubberband it left (dampened) so that they can see that this doesn't really slide (but still show some reaction)
    /// We detect if they are moving vertically or horizontally and act like isDirectionalLockEnabled (only move in first panned direction)
    func configure() {
        self.gesture.rx.event.subscribe(onNext: { [weak self] (pan) in
            guard let strongSelf = self else { return }

            switch pan.state {
            case .began:
                break
            case .changed:
                guard let view = pan.view, let superview = view.superview else { return }
                let panPos = pan.translation(in: superview)

                if let panConstraint = strongSelf.panConstraint {
                    // If we have set up the pan, offet it by the new pan position
                    panConstraint.offset(panPos)
                } else {
                    // If we haven't picked a direction yet, watch for it to get 2 pixels away, then set
                    // a constraint that overrides the ones on superview set and starts with it in the position it's currently in.
                    // We'll use this constraint to control the overlay by changing the constraint's constant
                    if panPos.y > 2 {
                        self?.panConstraint = PanConstraint(view: view, attribute: .top)
                    } else if abs(panPos.x) > 2 {
                        self?.panConstraint = PanConstraint(view: view, attribute: .leading)
                    }
                }
            case .ended, .failed, .cancelled:
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [.curveEaseOut],
                    animations: {
                        // Animate the overlay back to its original position
                        strongSelf.panConstraint?.reset()
                        pan.view?.superview?.layoutIfNeeded()
                    }, completion: { _ in
                        // Remove the pan constraints from the layout
                        strongSelf.panConstraint?.deactivate()
                        strongSelf.panConstraint = nil
                    }
                )
            case .possible:
                break
            }
        }).disposed(by: self.disposeBag)
    }

}
