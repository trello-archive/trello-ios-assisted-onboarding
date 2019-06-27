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

/// A view that shows instructions to the user on what they need to do at a point in the Mad Libs onboarding process.
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
        scrollView.leadingAnchor |== self.leadingAnchor
        scrollView.trailingAnchor |== self.trailingAnchor
        scrollView.topAnchor |== self.topAnchor |+ (stylesheet.overlayCornerRadius + stylesheet.gridUnit)
        scrollView.bottomAnchor |== self.safeAreaLayoutGuide.bottomAnchor
        scrollView.widthAnchor |== scrollView.contentLayoutGuide.widthAnchor |* 1

        scrollView.addAutoLaidOutSubview(self.contentView)
        scrollView.contentLayoutGuide.leadingAnchor |== self.contentView.leadingAnchor
        scrollView.contentLayoutGuide.trailingAnchor |== self.contentView.trailingAnchor
        scrollView.contentLayoutGuide.topAnchor |== self.contentView.topAnchor
        scrollView.contentLayoutGuide.bottomAnchor |== self.contentView.bottomAnchor
    }
}

/// This view has the scrollable content to embed in the main overlay view
class ScrollableContentView: UIView {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    let step: OverlayStep
    let goButton = FCTRoundedRectButton()
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

        titleLabel.topAnchor |== self.topAnchor
        titleLabel.centerXAnchor |== self.centerXAnchor
        titleLabel.leadingAnchor |== self.leadingAnchor |+ stylesheet.overlayOuterSideMargin

        self.addAutoLaidOutSubview(subtitleLabel)
        subtitleLabel.accessibilityLabel = overlayTemplate.subtitle
        subtitleLabel.text = overlayTemplate.subtitle
        subtitleLabel.textColor = stylesheet.overlaySubtitleTextColor
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.topAnchor |== titleLabel.bottomAnchor |+ stylesheet.gridUnit
        subtitleLabel.centerXAnchor |== self.centerXAnchor
        subtitleLabel.leadingAnchor |== titleLabel.leadingAnchor

        self.addAutoLaidOutSubview(goButton)
        goButton.setTitle(step.goButtonText, for: .normal)
        goButton.setTitleColor(stylesheet.overlayGoButtonTextColor, for: .normal)
        goButton.tintColor = stylesheet.overlayGoButtonBackgroundColor
        goButton.titleLabel?.numberOfLines = 0
        goButton.titleLabel?.textAlignment = .center
        goButton.titleLabel?.adjustsFontForContentSizeCategory = true
        goButton.isProminent = true

        goButton.topAnchor |== subtitleLabel.bottomAnchor |+ (3 * stylesheet.gridUnit)
        goButton.centerXAnchor |== subtitleLabel.centerXAnchor
        goButton.leadingAnchor |== subtitleLabel.leadingAnchor
        goButton.titleLabel?.heightAnchor ?|== goButton.heightAnchor ?|- (4 * stylesheet.gridUnit)

        if let skipButtonText = step.skipButtonText {
            self.addAutoLaidOutSubview(skipButton)
            skipButton.setTitle(skipButtonText, for: .normal)
            skipButton.setTitleColor(stylesheet.overlaySkipButtonTextColor, for: .normal)
            skipButton.backgroundColor = stylesheet.overlaySkipButtonBackgroundColor
            skipButton.titleLabel?.numberOfLines = 0
            skipButton.titleLabel?.textAlignment = .center
            skipButton.titleLabel?.adjustsFontForContentSizeCategory = true

            skipButton.topAnchor |== goButton.bottomAnchor |+ stylesheet.gridUnit
            skipButton.centerXAnchor |== subtitleLabel.centerXAnchor
            skipButton.leadingAnchor |== subtitleLabel.leadingAnchor
            skipButton.titleLabel?.heightAnchor ?|== skipButton.heightAnchor ?|- (4 * stylesheet.gridUnit)
            skipButton.bottomAnchor |== self.bottomAnchor |- stylesheet.gridUnit
        } else {
            goButton.bottomAnchor |== self.bottomAnchor |- stylesheet.gridUnit
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
