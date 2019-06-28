//
//  Utils.swift
//  TrelloAssistedOnboarding
//
//  Created by Lou Franco on 6/27/19.
//  Copyright © 2019 Trello. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension UIView {

    func addAutoLaidOutSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
    }

    func insertAutoLaidOutSubview(_ view: UIView, at index: Int) {
        view.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(view, at: index)
    }
}

extension UIColor {

    static let trelloSky50 = UIColor(red: 0.894, green: 0.969, blue: 0.980, alpha: 1)

    static let trelloShade200 = UIColor(red: 0.886, green: 0.894, blue: 0.902, alpha: 1)
    static let trelloShade300 = UIColor(red: 0.886, green: 0.894, blue: 0.902, alpha: 1)
    static let trelloShade500 = UIColor(red: 0.514, green: 0.549, blue: 0.569, alpha: 1)
    static let trelloShade600 = UIColor(red: 0.404, green: 0.427, blue: 0.439, alpha: 1)

    static let trelloBlue500 = UIColor(red: 0.000, green: 0.475, blue: 0.749, alpha: 1)

    static let trelloGreen700 = UIColor(red: 0.318, green: 0.596, blue: 0.224, alpha: 1)

    static let fct_darkTextColor = UIColor(red: 0.302, green: 0.302, blue: 0.302, alpha: 1)
    static let fct_textColor = UIColor(red: 0.224, green: 0.224, blue: 0.224, alpha: 1)

    static let nachosPurple500 = UIColor(red: 0.765, green: 0.467, blue: 0.878, alpha: 1)
    static let nachosPurple700 = UIColor(red: 0.537, green: 0.376, blue: 0.620, alpha: 1)

    static let nachosBlue500 = UIColor(red: 0.000, green: 0.475, blue: 0.749, alpha: 1)

    static let nachosGreen500 = UIColor(red: 0.380, green: 0.741, blue: 0.310, alpha: 1)
    static let nachosGreen700 = UIColor(red: 0.318, green: 0.596, blue: 0.224, alpha: 1)

    static let nachosOrange500 = UIColor(red: 1.000, green: 0.671, blue: 0.290, alpha: 1)
    static let nachosOrange700 = UIColor(red: 0.824, green: 0.565, blue: 0.204, alpha: 1)

    static let nachosShades300 = UIColor(red: 0.839, green: 0.855, blue: 0.863, alpha: 1)
    static let nachosShades400 = UIColor(red: 0.514, green: 0.549, blue: 0.569, alpha: 1)

}

extension String {

    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

}

extension UIFont {
    public class func preferredFont(forTextStyle style: UIFont.TextStyle, withTraits traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let font = UIFont.preferredFont(forTextStyle: style)
        guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return font }
        return UIFont(descriptor: descriptor, size: 0)
    }
}

public extension CaseIterable where Self: Equatable {

    // Increments an iterable enum to the next case statement if one exists
    var nextCase: Self? {
        guard let selfIndex = Self.allCases.firstIndex(of: self) else {
            return nil
        }

        let nextIndex = Self.allCases.index(after: selfIndex)
        let endIndex = Self.allCases.endIndex
        guard endIndex != nextIndex else {
            return nil
        }

        let next = type(of: self).allCases[nextIndex]
        return next
    }

}

public extension ObservableType where E == Bool {
    /// Inverts a boolean observable
    /// - returns: A new `Observable<Bool>` with inverted values to `self`
    func not() -> Observable<Bool> {
        return self.map({ !$0 })
    }
}

public extension SharedSequenceConvertibleType where Self.E == Bool {
    /// Inverts a boolean observable
    /// - returns: A new `Observable<Bool>` with inverted values to `self`
    func not() -> SharedSequence<Self.SharingStrategy, Bool> {
        return self.map({ !$0 })
    }
}

public extension Reactive where Base: UIViewController {
    var traitCollection: ControlEvent<UITraitCollection> {
        let source = base.rx.sentMessage(#selector(UIViewController.willTransition(to:with:)))
            .map { params in
                if params.count > 0, let traitCollection = (params[0] as? UITraitCollection) {
                    return traitCollection
                }
                return UITraitCollection(horizontalSizeClass: .regular)
            }
            .startWith(base.traitCollection)
        return ControlEvent(events: source)
    }

    var viewSize: ControlEvent<CGSize> {
        let source = base.rx.viewWillLayoutSubviews
            .map { [weak base] in
                base?.view.bounds.size ?? .zero
            }
            .startWith(base.view.bounds.size)
            .distinctUntilChanged()
        return ControlEvent(events: source)
    }

}

/// This defines SizeClassViewContainer, which you can subclass in inner classes of your VC to contain just
/// the compact or regular (size class) views of your VC.  Doing so lets you drive .isHidden for this class
/// and have it be directed to the views.
///
/// To use:
///  1. Make an inner class in your VC (e.g. `CompactUI`) and inherit from `SizeClassViewContainer`.
///  2. Override `views` to provide an array of views that are part of only the compact UI.
///  3. You can use the .isHidden binder on this class to hide/show all of those views.
extension UIViewController {
    class SizeClassViewContainer: ReactiveCompatible {
        var views: [UIView] { return [] }
    }
}

/// Rx Binders for a SizeClassViewContainer that bind to each of its views
extension Reactive where Base: UIViewController.SizeClassViewContainer {

    /// A Binder for isHidden that sets isHidden on each of the views this class contains
    var isHidden: Binder<Bool> {
        return Binder(self.base) { hasSizeClassViews, hidden in
            hasSizeClassViews.views.forEach { $0.isHidden = hidden }
        }
    }
}

extension Reactive where Base: UIView {

    // Whether the view should end editing for any first responders
    var endEditing: Binder<Void> {
        return Binder(self.base) { view, _ in
            view.endEditing(true)
        }
    }

    // Whether the view should be animated hidden or shown with alpha animation
    func isShownAnimated(duration: TimeInterval, delay: TimeInterval = 0.0, options: UIView.AnimationOptions = []) -> Binder<Bool> {
        return Binder(self.base) { view, shown in
            UIView.animate(
                withDuration: duration,
                delay: delay,
                options: options,
                animations: {
                    if shown {
                        view.alpha = 1.0
                    } else {
                        view.alpha = 0.0
                    }
            })
        }
    }

    // When a view should search its subviews for a first responder, and if it's a UIControl then send the .editingDidEndOnEdit event
    var forceEndOnExitEventForCurrentFirstResponderControl: Binder<Void> {
        return Binder(self.base) { view, _ in
            guard let control = view.findThatIsFirstResponder() as? UIControl else { return }

            control.sendActions(for: .editingDidEnd)
            control.sendActions(for: .editingDidEndOnExit)
        }
    }

}

// Taken from: http://stackoverflow.com/a/9874704
extension UIView {
    func findThatIsFirstResponder() -> UIView? {
        if self.isFirstResponder {
            return self
        }

        for subView in self.subviews {
            let firstResponder = subView.findThatIsFirstResponder()
            if let firstResponder = firstResponder {
                return firstResponder;
            }
        }

        return nil
    }
}

extension Reactive where Base: UIResponder {

    // Whether to become or resign first responder
    var isFirstResponder: Binder<Bool> {
        return Binder(self.base) { responder, shouldBeFirstResponder in
            if shouldBeFirstResponder && !responder.isFirstResponder {
                responder.becomeFirstResponder()
            } else if !shouldBeFirstResponder && responder.isFirstResponder {
                responder.resignFirstResponder()
            }
        }
    }

    // When it's necessary to select all (UIControl subclass vary on implementation; UITextField selects all the text)
    func selectAll<T: Any>(_ sender: T? = nil) -> Binder<T> {
        return Binder(self.base) { responder, _ in
            responder.selectAll(sender)
        }
    }

}


extension Reactive where Base: UIButton {

    // Change a button's title and make it resize.
    var updateTitleAndResize: Binder<String> {
        return Binder(self.base) { button, title in
            button.isAccessibilityElement = true
            button.accessibilityLabel = title

            button.setTitle(title, for: .normal)
            button.sizeToFit()
        }
    }

}
