//
//  Stylesheet.swift
//  Trellis
//
//  Created by Lou Franco on 4/15/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import UIKit

class Stylesheet {
    private static let gridUnit: CGFloat = 8.0
    
    let gridUnit = Stylesheet.gridUnit
    
    lazy var mainBackgroundColor = UIColor.trelloSky50
    
    lazy var standardAnimationDuration = 0.15
    
    lazy var boardNameMargin: CGFloat = 2 * gridUnit
    lazy var boardCornerRadius: CGFloat = 2 * gridUnit
    
    lazy var listCornerRadius: CGFloat = gridUnit
    lazy var listTextColor = UIColor.darkText
    lazy var listBackgroundColor = UIColor.trelloShade200
    lazy var listOuterMargin = 3 * gridUnit
    lazy var listSpacing = 2 * gridUnit
    lazy var listZoomedOutWidth: CGFloat = 140.0
    lazy var listZoomedInWidth: CGFloat = 280.0
    
    lazy var cardCornerRadius: CGFloat = gridUnit
    lazy var cardBackgroundColor = UIColor.white
    lazy var cardHeight: CGFloat = gridUnit * 6
    
    lazy var welcomeTopMargin = gridUnit * 4
    lazy var getStartedTopMargin = gridUnit * 3
    lazy var buttonGroupTopMargin = gridUnit * 4
    lazy var buttonGroupSpacing = gridUnit * 2
    lazy var buttonCornerRadius: CGFloat = 16.0
    lazy var buttonOuterMargin = gridUnit * 3
    lazy var skipToTrelloButtonTopMargin = gridUnit * 5
    lazy var skipToTrelloButtonBottomMargin = gridUnit * 6

    lazy var navTrelloLogoColor = UIColor.trelloBlue500
    
    lazy var textColor = UIColor.fct_darkTextColor
    lazy var darkTextColor = UIColor.fct_darkTextColor
    lazy var shadowColor = UIColor.trelloShade600.cgColor
    lazy var shadowOpacity: Float = 0.25
    lazy var shadowOffset = CGSize(width: 1.0, height: 1.0)
    
    lazy var bottomOverlayShadowRadius: CGFloat = 5.0
    lazy var bottomOverlayShadowOpacity: Float = 0.5
    
    lazy var overlayBackgroundColor = UIColor.white
    lazy var overlayCornerRadius: CGFloat = 2 * gridUnit
    lazy var overlayOuterSideMargin: CGFloat = 2 * gridUnit
    lazy var overlayTitleTextColor = UIColor.black
    lazy var overlaySubtitleTextColor = UIColor.trelloShade500
    
    lazy var overlayGoButtonTextColor = UIColor.white
    lazy var overlayGoButtonBackgroundColor = UIColor.trelloGreen700
    lazy var overlayDisabledGoButtonBackgroundColor = UIColor.trelloShade600
    
    lazy var overlaySkipButtonTextColor = UIColor.trelloShade500
    lazy var overlaySkipButtonBackgroundColor: UIColor? = nil
    
    lazy var overlaySlideDuration = 0.25
    lazy var overlayRegularWidth: CGFloat = 300

    lazy var templateWelcomeLabelWidthRatio: CGFloat = 0.96
    lazy var templateGetStartedLabelWidthRatio: CGFloat = 0.76
    lazy var templateButtonStackWidthRatio: CGFloat = 1.24

    var trelloLogoImageView: UIImageView {
        let trelloLogo = UIImage(named: "logo-trello")!.withRenderingMode(.alwaysTemplate)
        let logoImageView = UIImageView(image: trelloLogo)
        logoImageView.tintColor = self.navTrelloLogoColor
        return logoImageView
    }
    
    var boardNameFont:          UIFont { return UIFont.preferredFont(forTextStyle: .title1, withTraits: .traitBold) }
    var listNameFont:           UIFont { return UIFont.preferredFont(forTextStyle: .title3, withTraits: .traitBold) }
    var cardTitleFont:          UIFont { return UIFont.preferredFont(forTextStyle: .body, withTraits: .traitBold) }
    var welcomeFont:            UIFont { return UIFont.preferredFont(forTextStyle: .headline) }
    var getStartedFont:         UIFont { return UIFont.preferredFont(forTextStyle: .title1) }
    var skipToTrelloButtonFont: UIFont { return UIFont.preferredFont(forTextStyle: .footnote) }
    var boardTemplateNameFont:  UIFont { return UIFont.preferredFont(forTextStyle: .headline, withTraits: .traitBold) }
    var arrowFont:              UIFont { return UIFont.preferredFont(forTextStyle: .title1) }
    var backButtonFont:         UIFont { return UIFont.preferredFont(forTextStyle: .title3) }
    var rightNavButtonFont:     UIFont { return UIFont.preferredFont(forTextStyle: .title3, withTraits: .traitBold) }
    var overlayTitleFont:       UIFont { return UIFont.preferredFont(forTextStyle: .title1, withTraits: .traitBold) }
    var overlaySubtitleFont:    UIFont { return UIFont.preferredFont(forTextStyle: .body) }
    var overlayGoButtonFont:    UIFont { return UIFont.preferredFont(forTextStyle: .body, withTraits: .traitBold) }
    var overlaySkipButtonFont:  UIFont { return UIFont.preferredFont(forTextStyle: .body, withTraits: .traitBold) }

}
