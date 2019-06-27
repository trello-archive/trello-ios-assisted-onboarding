//
//  FlowStates.swift
//  Trellis
//
//  Created by Lou Franco on 4/17/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import Foundation

// This represents the overall flow which should only go forward not backwards.
enum FlowStep: Int, CaseIterable, Comparable {
    case begin
    case nameBoard
    case finishBoardNaming
    case nameLists
    case finishListNaming
    case nameCards
    case finishCardNaming
    case createBoard
    
    static func < (lhs: FlowStep, rhs: FlowStep) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// All of the strings are placeholders -- we'll move to .strings when we get real copy (so we avoid translations)

/// This represents a step in the onboarding process that is requires an overlay to built to describe it.
enum OverlayStep: Int, CaseIterable, Comparable {
    case describeBoard
    case describeList
    case describeCard
    case createBoard

    static func < (lhs: OverlayStep, rhs: OverlayStep) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var goButtonText: String {
        switch self {
        case .describeBoard:
            return "overlay_name_your_board".localized
        case .describeList:
            return "overlay_name_your_lists".localized
        case .describeCard:
            return "overlay_add_cards".localized
        case .createBoard:
            return "overlay_go_to_board".localized
        }
    }

    var skipButtonText: String? {
        switch self {
        // We decided to remove overlay skip buttons, but leaving this in case we change our mind.
        case .describeBoard, .describeList, .describeCard, .createBoard:
            return nil
        }
    }
}
