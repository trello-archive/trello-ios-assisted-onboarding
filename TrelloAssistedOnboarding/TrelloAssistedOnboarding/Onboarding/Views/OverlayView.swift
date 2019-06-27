//
//  OverlayView.swift
//  Trellis
//
//  Created by Lou Franco on 4/17/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// A view that shows instructions to the user on what they need to do at a point in the onboarding process.
/// It looks like a round-rect white overlay that is approximately keyboard (or bigger sized) and meant to be flush
/// with the bottom of the device. Underneath, you can see the board you are building (BoardView).
class OverlayView: UIView {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    let step: OverlayStep
    private let stylesheet = Stylesheet()

    let contentView: ScrollableContentView

    private var panGestureController: OverlayViewGestureController?

    enum Style {
        case bottomOverlay
        case sidebar

        var maskedCorners: CACornerMask {
            switch self {
            case .bottomOverlay:
                return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            case .sidebar:
                return [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            }
        }

        func setShadow(layer: CALayer, stylesheet: Stylesheet) {
            switch self {
            case .bottomOverlay:
                layer.shadowColor = stylesheet.shadowColor
                layer.shadowOpacity = stylesheet.bottomOverlayShadowOpacity
                layer.shadowRadius = stylesheet.bottomOverlayShadowRadius
            case .sidebar:
                layer.shadowColor = stylesheet.shadowColor
                layer.shadowOpacity = stylesheet.shadowOpacity
                layer.shadowOffset = stylesheet.shadowOffset
            }
        }

        func panGestureController(view: UIView) -> OverlayViewGestureController? {
            switch self {
            case .bottomOverlay:
                return OverlayViewGestureController(view: view)
            case .sidebar:
                return nil
            }
        }

    }

    let style: Style

    init(step: OverlayStep, overlayTemplate: BoardTemplate.Overlay, style: Style) {
        self.step = step
        self.contentView = ScrollableContentView(step: step, overlayTemplate: overlayTemplate)
        self.style = style
        super.init(frame: .zero)

        self.panGestureController = style.panGestureController(view: self)

        self.accessibilityElements = [contentView.titleLabel, contentView.subtitleLabel, contentView.goButton]

        self.backgroundColor = stylesheet.overlayBackgroundColor
        self.layer.cornerRadius = stylesheet.overlayCornerRadius
        self.layer.maskedCorners = style.maskedCorners

        style.setShadow(layer: self.layer, stylesheet: self.stylesheet)

        // Add a vertical scrollview that is full-view in the overlay, below the rounded-rect top (overlay safe-area)
        let scrollView = UIScrollView(frame: .zero)
        self.addAutoLaidOutSubview(scrollView)
        scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: self.topAnchor, constant: (stylesheet.overlayCornerRadius + stylesheet.gridUnit)).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor).isActive = true

        scrollView.addAutoLaidOutSubview(self.contentView)
        scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    }
}

/// This view has the scrollable content to embed in the main overlay view
class ScrollableContentView: UIView {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    let step: OverlayStep
    let goButton = UIButton(type: .roundedRect)// FCTRoundedRectButton() TODO
    let skipButton = UIButton(type: .roundedRect)
    let titleLabel = UILabel(frame: .zero)
    let subtitleLabel = UILabel(frame: .zero)
    let disposeBag = DisposeBag()
    
    private let stylesheet = Stylesheet()

    init(step: OverlayStep, overlayTemplate: BoardTemplate.Overlay) {
        self.step = step
        super.init(frame: .zero)

        self.addAutoLaidOutSubview(titleLabel)
        titleLabel.accessibilityLabel = overlayTemplate.title
        titleLabel.text = overlayTemplate.title
        titleLabel.textColor = stylesheet.overlayTitleTextColor
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true

        titleLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: stylesheet.overlayOuterSideMargin).isActive = true

        self.addAutoLaidOutSubview(subtitleLabel)
        subtitleLabel.accessibilityLabel = overlayTemplate.subtitle
        subtitleLabel.text = overlayTemplate.subtitle
        subtitleLabel.textColor = stylesheet.overlaySubtitleTextColor
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: stylesheet.gridUnit).isActive = true
        subtitleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true

        self.addAutoLaidOutSubview(goButton)
        goButton.setTitle(step.goButtonText, for: .normal)
        goButton.setTitleColor(stylesheet.overlayGoButtonTextColor, for: .normal)
        goButton.setTitleColor(stylesheet.overlayDisabledGoButtonBackgroundColor, for: .disabled)
        goButton.backgroundColor = stylesheet.overlayGoButtonBackgroundColor
        goButton.layer.cornerRadius = 5.0;
        goButton.titleLabel?.numberOfLines = 0
        goButton.titleLabel?.textAlignment = .center
        goButton.titleLabel?.adjustsFontForContentSizeCategory = true

        goButton.rx
            .observeWeakly(Bool.self, #keyPath(UIButton.isEnabled))
            .subscribe(onNext: { [weak self] enabled in
                guard let enabled = enabled, let strongSelf = self else { return }
                if enabled {
                    strongSelf.goButton.backgroundColor = strongSelf.stylesheet.overlayGoButtonBackgroundColor
                    strongSelf.goButton.layer.borderWidth = 0.0
                    strongSelf.goButton.layer.borderColor = nil
                } else {
                    strongSelf.goButton.backgroundColor = UIColor.white
                    strongSelf.goButton.layer.borderWidth = 1.0
                    strongSelf.goButton.layer.borderColor = strongSelf.stylesheet.overlayDisabledGoButtonBackgroundColor.cgColor
                }
            })
            .disposed(by: self.disposeBag)

        goButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: (3 * stylesheet.gridUnit)).isActive = true
        goButton.centerXAnchor.constraint(equalTo: subtitleLabel.centerXAnchor).isActive = true
        goButton.leadingAnchor.constraint(equalTo: subtitleLabel.leadingAnchor).isActive = true
        goButton.titleLabel?.heightAnchor.constraint(equalTo: goButton.heightAnchor, constant: -(4 * stylesheet.gridUnit)).isActive = true

        if let skipButtonText = step.skipButtonText {
            self.addAutoLaidOutSubview(skipButton)
            skipButton.setTitle(skipButtonText, for: .normal)
            skipButton.setTitleColor(stylesheet.overlaySkipButtonTextColor, for: .normal)
            skipButton.backgroundColor = stylesheet.overlaySkipButtonBackgroundColor
            skipButton.titleLabel?.numberOfLines = 0
            skipButton.titleLabel?.textAlignment = .center
            skipButton.titleLabel?.adjustsFontForContentSizeCategory = true

            skipButton.topAnchor.constraint(equalTo: goButton.bottomAnchor, constant: stylesheet.gridUnit).isActive = true
            skipButton.centerXAnchor.constraint(equalTo: subtitleLabel.centerXAnchor).isActive = true
            skipButton.leadingAnchor.constraint(equalTo: subtitleLabel.leadingAnchor).isActive = true
            skipButton.titleLabel?.heightAnchor.constraint(equalTo: skipButton.heightAnchor, constant: -(4 * stylesheet.gridUnit)).isActive = true
            skipButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -stylesheet.gridUnit).isActive = true
        } else {
            goButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -stylesheet.gridUnit).isActive = true
        }
    
        self.configureFonts()
        
        NotificationCenter.default.rx.notification(UIContentSizeCategory.didChangeNotification)
            .subscribe(onNext: { [weak self] _ in self?.configureFonts() })
            .disposed(by: self.disposeBag)
    }

    func configureFonts() {
        self.titleLabel.font = stylesheet.overlayTitleFont
        self.subtitleLabel.font = stylesheet.overlaySubtitleFont
        self.goButton.titleLabel?.font = stylesheet.overlayGoButtonFont
        self.skipButton.titleLabel?.font = stylesheet.overlaySkipButtonFont
    }

}
