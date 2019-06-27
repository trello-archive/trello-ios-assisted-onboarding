//
//  BoardTemplatePickerViewController.swift
//  Trellis
//
//  Created by Andrew Frederick on 4/13/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit
import RxSwift

class BoardTemplatePickerViewController: UIViewController {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let flowController: FlowController

    private let scrollView = UIScrollView()
    private let welcomeLabel = UILabel()
    private let getStartedLabel = UILabel()
    private let boardTemplateButtonsStackView = UIStackView()
    private let skipToTrelloButton = UIButton()
    private let disposeBag = DisposeBag()
    private let stylesheet = Stylesheet()

    init(_ flowController: FlowController) {
        self.flowController = flowController
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addViews()
        configureViews()
        constrainViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.accessibilityElements = [welcomeLabel, getStartedLabel, boardTemplateButtonsStackView, skipToTrelloButton]
        UIAccessibility.post(notification: .screenChanged, argument: welcomeLabel)
    }
    
    func addViews() {
        view.addAutoLaidOutSubview(scrollView)
        scrollView.addAutoLaidOutSubview(welcomeLabel)
        scrollView.addAutoLaidOutSubview(getStartedLabel)
        scrollView.addAutoLaidOutSubview(boardTemplateButtonsStackView)
        scrollView.addAutoLaidOutSubview(skipToTrelloButton)
        skipToTrelloButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.skipToTrelloButtonTapped()
        }).disposed(by: disposeBag)
        
        [BoardTemplate(type: .planEvent),
         BoardTemplate(type: .trackGoal),
         BoardTemplate(type: .manageProject),
         BoardTemplate(type: .increaseProductivity),
         BoardTemplate(type: .somethingElse)]
            .forEach { (boardTemplate) in
                let button = BoardTemplateButton(boardTemplate: boardTemplate)
                boardTemplateButtonsStackView.addArrangedSubview(button)

                Observable.merge(button.rx.tap.asObservable(), button.rx.arrowTap)
                    .subscribe(onNext: { [weak self] _ in
                        self?.boardTemplateButtonTapped(boardTemplate)
                    }).disposed(by: disposeBag)
        }
    }
    
    func configureViews() {
        let emptyImage = UIImage()
        let navBar = navigationController?.navigationBar
        navBar?.setBackgroundImage(emptyImage, for: .default)
        navBar?.shadowImage = emptyImage
        navBar?.isTranslucent = true
        navBar?.tintColor = UIColor.fct_textColor
        
        navigationItem.titleView = stylesheet.trelloLogoImageView
        navigationItem.isAccessibilityElement = false
        
        view.backgroundColor = stylesheet.mainBackgroundColor

        scrollView.alwaysBounceVertical = true
        
        welcomeLabel.font = stylesheet.welcomeFont
        welcomeLabel.adjustsFontForContentSizeCategory = true
        welcomeLabel.textColor = stylesheet.textColor
        welcomeLabel.textAlignment = .center
        welcomeLabel.numberOfLines = 0
        welcomeLabel.text = "welcome_label".localized

        getStartedLabel.font = stylesheet.getStartedFont
        getStartedLabel.adjustsFontForContentSizeCategory = true
        getStartedLabel.textColor = stylesheet.textColor
        getStartedLabel.textAlignment = .center
        getStartedLabel.numberOfLines = 0
        getStartedLabel.text = "get_started_label".localized
        
        boardTemplateButtonsStackView.axis = .vertical
        boardTemplateButtonsStackView.spacing = stylesheet.buttonGroupSpacing
        
        skipToTrelloButton.titleLabel?.adjustsFontForContentSizeCategory = true
        skipToTrelloButton.titleLabel?.numberOfLines = 0
        skipToTrelloButton.titleLabel?.textAlignment = .center
        skipToTrelloButton.setTitle("skip_to_trello_button".localized, for: .normal)
        skipToTrelloButton.titleLabel?.font = stylesheet.skipToTrelloButtonFont
        skipToTrelloButton.setTitleColor(stylesheet.textColor, for: .normal)
    }
    
    func constrainViews() {
        let frameGuide = scrollView.frameLayoutGuide
        let contentGuide = scrollView.contentLayoutGuide
        
        // While not required to ensure only vertical scrolling, this squashes a constraint ambiguity in the View Hierarchy Debugger
        frameGuide.widthAnchor.constraint(equalTo: contentGuide.widthAnchor).isActive = true
        
        frameGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        frameGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        frameGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        frameGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        welcomeLabel.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: stylesheet.welcomeTopMargin).isActive = true
        welcomeLabel.centerXAnchor.constraint(equalTo: frameGuide.centerXAnchor).isActive = true
        welcomeLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: stylesheet.templateWelcomeLabelWidthRatio).isActive = true
        
        getStartedLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: stylesheet.getStartedTopMargin).isActive = true
        getStartedLabel.centerXAnchor.constraint(equalTo: frameGuide.centerXAnchor).isActive = true
        getStartedLabel.widthAnchor.constraint(lessThanOrEqualTo: frameGuide.widthAnchor, multiplier: stylesheet.templateGetStartedLabelWidthRatio).isActive = true

        boardTemplateButtonsStackView.topAnchor.constraint(equalTo: getStartedLabel.bottomAnchor, constant: stylesheet.buttonGroupTopMargin).isActive = true
        boardTemplateButtonsStackView.widthAnchor.constraint(equalTo: getStartedLabel.widthAnchor, multiplier: stylesheet.templateButtonStackWidthRatio).isActive = true
        boardTemplateButtonsStackView.centerXAnchor.constraint(equalTo: getStartedLabel.centerXAnchor).isActive = true

        skipToTrelloButton.topAnchor.constraint(equalTo: boardTemplateButtonsStackView.bottomAnchor, constant: stylesheet.skipToTrelloButtonTopMargin).isActive = true
        skipToTrelloButton.centerXAnchor.constraint(equalTo: frameGuide.centerXAnchor).isActive = true
        skipToTrelloButton.widthAnchor.constraint(equalTo: getStartedLabel.widthAnchor).isActive = true
        skipToTrelloButton.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -stylesheet.skipToTrelloButtonBottomMargin).isActive = true
    }
    
    func boardTemplateButtonTapped(_ boardTemplate: BoardTemplate) {
        flowController.showBoard(boardTemplate)
    }
    
    func skipToTrelloButtonTapped() {
        flowController.goToTrello()
    }
}


class BoardTemplateButton: UIButton {
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let boardTemplate: BoardTemplate
    private let templateNameLabel = UILabel()
    private let disclosure = UIView()
    private let arrowLabel = UILabel()
    fileprivate let tap = UITapGestureRecognizer(target: nil, action: nil)
    private let stylesheet = Stylesheet()

    private let disposeBag = DisposeBag()
    
    init(boardTemplate: BoardTemplate) {
        self.boardTemplate = boardTemplate
        super.init(frame: .zero)
        
        addViews()
        configureViews()
        constrainViews()
        self.accessibilityLabel = boardTemplate.name
    }
    
    func addViews() {
        addAutoLaidOutSubview(templateNameLabel)
        addAutoLaidOutSubview(disclosure)
        disclosure.addAutoLaidOutSubview(arrowLabel)
    }
    
    func configureViews() {
        self.disclosure.addGestureRecognizer(tap)
        self.backgroundColor = .white
        
        layer.cornerRadius = stylesheet.buttonCornerRadius
        layer.shadowColor = stylesheet.shadowColor
        layer.shadowOpacity = stylesheet.shadowOpacity
        layer.shadowOffset = stylesheet.shadowOffset
        
        templateNameLabel.font = stylesheet.boardTemplateNameFont
        templateNameLabel.adjustsFontForContentSizeCategory = true
        templateNameLabel.textColor = stylesheet.darkTextColor
        templateNameLabel.numberOfLines = 0
        templateNameLabel.text = boardTemplate.name
        
        disclosure.backgroundColor = boardTemplate.board.backgroundColor.uiColor
        disclosure.isUserInteractionEnabled = true
        
        arrowLabel.font = stylesheet.arrowFont
        arrowLabel.textAlignment = .center
        arrowLabel.adjustsFontForContentSizeCategory = true
        arrowLabel.textColor = .white
        arrowLabel.text = "→"
    }
    
    func constrainViews() {
        templateNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: stylesheet.buttonOuterMargin).isActive = true
        templateNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: stylesheet.buttonOuterMargin).isActive = true
        templateNameLabel.trailingAnchor.constraint(equalTo: disclosure.leadingAnchor, constant: -stylesheet.gridUnit).isActive = true
        templateNameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -stylesheet.buttonOuterMargin).isActive = true

        disclosure.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -stylesheet.buttonOuterMargin).isActive = true
        disclosure.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        disclosure.widthAnchor.constraint(equalTo: disclosure.heightAnchor).isActive = true
        
        arrowLabel.topAnchor.constraint(equalTo: disclosure.topAnchor).isActive = true
        arrowLabel.leadingAnchor.constraint(equalTo: disclosure.leadingAnchor).isActive = true
        arrowLabel.trailingAnchor.constraint(equalTo: disclosure.trailingAnchor).isActive = true
        arrowLabel.bottomAnchor.constraint(equalTo: disclosure.bottomAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        disclosure.layer.cornerRadius = disclosure.bounds.width / 2.0
    }
}

extension Reactive where Base: BoardTemplateButton {
    var arrowTap: Observable<()> {
        return base.tap.rx.event
            .filter { tap in
                switch tap.state {
                case .ended:
                    return true
                case .possible, .began, .changed, .cancelled, .failed:
                    return false
                @unknown default:
                    fatalError()
                }
            }
            .map {_ in ()}
    }
}
