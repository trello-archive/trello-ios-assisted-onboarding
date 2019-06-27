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
        frameGuide.widthAnchor |== contentGuide.widthAnchor |* 1
        
        frameGuide.topAnchor |== view.safeAreaLayoutGuide.topAnchor
        frameGuide.leadingAnchor |== view.leadingAnchor
        frameGuide.trailingAnchor |== view.trailingAnchor
        frameGuide.bottomAnchor |== view.bottomAnchor
        
        welcomeLabel.topAnchor |== contentGuide.topAnchor |+ stylesheet.welcomeTopMargin
        welcomeLabel.centerXAnchor |== frameGuide.centerXAnchor
        welcomeLabel.widthAnchor |<= view.widthAnchor |* stylesheet.templateWelcomeLabelWidthRatio
        
        getStartedLabel.topAnchor |== welcomeLabel.bottomAnchor |+ stylesheet.getStartedTopMargin
        getStartedLabel.centerXAnchor |== frameGuide.centerXAnchor
        getStartedLabel.widthAnchor |<= frameGuide.widthAnchor |* stylesheet.templateGetStartedLabelWidthRatio

        boardTemplateButtonsStackView.topAnchor |== getStartedLabel.bottomAnchor |+ stylesheet.buttonGroupTopMargin
        boardTemplateButtonsStackView.widthAnchor |== getStartedLabel.widthAnchor |* stylesheet.templateButtonStackWidthRatio
        boardTemplateButtonsStackView.centerXAnchor |== getStartedLabel.centerXAnchor

        skipToTrelloButton.topAnchor |== boardTemplateButtonsStackView.bottomAnchor |+ stylesheet.skipToTrelloButtonTopMargin
        skipToTrelloButton.centerXAnchor |== frameGuide.centerXAnchor
        skipToTrelloButton.widthAnchor |== getStartedLabel.widthAnchor |* 1
        skipToTrelloButton.bottomAnchor |== contentGuide.bottomAnchor |- stylesheet.skipToTrelloButtonBottomMargin
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
        view.backgroundColor = .white
        
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
        templateNameLabel.topAnchor |== topAnchor |+ stylesheet.buttonOuterMargin
        templateNameLabel.leadingAnchor |== leadingAnchor |+ stylesheet.buttonOuterMargin
        templateNameLabel.trailingAnchor |== disclosure.leadingAnchor |- stylesheet.gridUnit
        templateNameLabel.bottomAnchor |== bottomAnchor |- stylesheet.buttonOuterMargin

        disclosure.trailingAnchor |== trailingAnchor |- stylesheet.buttonOuterMargin
        disclosure.centerYAnchor |== centerYAnchor
        disclosure.widthAnchor |== disclosure.heightAnchor |* 1
        
        arrowLabel.topAnchor |== disclosure.topAnchor
        arrowLabel.leadingAnchor |== disclosure.leadingAnchor
        arrowLabel.trailingAnchor |== disclosure.trailingAnchor
        arrowLabel.bottomAnchor |== disclosure.bottomAnchor
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
                }
            }
            .map {_ in ()}
    }
}
