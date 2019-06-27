//
//  BoardTemplate.swift
//  Trellis
//
//  Created by Andrew Frederick on 4/13/19.
//  Copyright © 2019 Atlassian. All rights reserved.
//

import Foundation
import UIKit

struct BoardTemplate {
    
    enum TemplateType: String {
        case planEvent
        case trackGoal
        case manageProject
        case increaseProductivity
        case somethingElse
    }

    enum BoardBackgroundColor {
        case purple
        case blue
        case green
        case orange
        case gray

        var uiColor: UIColor {
            switch self {
            case .purple:
                return UIColor.nachosPurple500
            case .blue:
                return UIColor.nachosBlue500
            case .green:
                return UIColor.nachosGreen500
            case .orange:
                return UIColor.nachosOrange500
            case .gray:
                return UIColor.nachosShades400
            }
        }

        var uiColorForTrelloBoard: UIColor {
            // These colors match what the official Trello background colors are when you
            // pick a color background.  If you don't use these, when we make the board, you
            // will see the color switch to them after the board is synced.
            switch self {
            case .purple:
                return UIColor.nachosPurple700
            case .blue:
                return UIColor.nachosBlue500
            case .green:
                return UIColor.nachosGreen700
            case .orange:
                return UIColor.nachosOrange700
            case .gray:
                return UIColor.nachosShades400
            }
        }

        var trelloBackgroundKey: String {
            switch self {
            case .purple:
                return "purple"
            case .blue:
                return "blue"
            case .green:
                return "green"
            case .orange:
                return "orange"
            case .gray:
                return "grey" // This is correct (not gray)
            }
        }
    }

    struct Overlay {
        let title: String
        let subtitle: String
    }

    // Represents a board with its lists and cards.
    struct Board {
        let backgroundColor: BoardBackgroundColor
        let defaultName: String
        var lists: [List]
        var customBoardName: String? = nil

        let overlays: [Overlay]

        var boardName: String {
            return customBoardName ?? defaultName
        }

        /// Calculates the list (section) and card (row) that the cardIndex represents.
        /// - parameter cardIndex: the overall index of the card on the board
        /// - returns: An index path with the section set to the list pos and the row set to the card pos within that list
        func cardIndexPath(cardIndex: Int) -> IndexPath {
            var listPos = 0
            var cardPos = cardIndex

            for l in self.lists {
                if cardPos < l.cards.count {
                    break
                } else {
                    listPos += 1
                    cardPos -= l.cards.count
                }
            }
            return IndexPath(row: cardPos, section: listPos)
        }
    }

    // Represents a single list and its cards.
    struct List {
        let defaultName: String
        var cards: [Card]
        var customListName: String? = nil

        var listName: String {
            return customListName ?? defaultName
        }
    }

    /// Represents a single card. There is no default card name. If a card has no custom name, we don't make it.
    struct Card {
        let placeholderName: String
        var customCardName: String? = nil
    }

    let type: TemplateType
    let name: String
    let board: Board

    static var defaultBoard: Board {
        return Board(backgroundColor: .green,
                     defaultName: "default_board_title".localized,
                     lists: [
                        List(defaultName: "default_board_list_to_do".localized,
                             cards: [Card(placeholderName: "default_board_card_untitled".localized, customCardName: "default_board_card_untitled".localized)],
                             customListName: nil
                        ),
                        List(defaultName: "default_board_list_doing".localized, cards: [],
                             customListName: nil
                        ),
                        List(defaultName: "default_board_list_done".localized, cards: [],
                             customListName: nil
                        ),
                     ],
                     customBoardName: nil,
                     // Unused in the default board
                     overlays: [])
    }
    
    // Creates all the default starter projects
    init(type: TemplateType) {
        self.type = type
        switch type {
        case .planEvent:
            self.name = "project_plan_an_event".localized
            self.board = Board(backgroundColor: .purple,
                               defaultName: "project_plan_an_event_board_name".localized,
                               lists: [
                                List(defaultName: "project_plan_an_event_list_1_name".localized,
                                     cards: [
                                        Card(placeholderName: "project_plan_an_event_card_1_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_plan_an_event_card_2_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_plan_an_event_card_3_name".localized, customCardName: nil),
                                        ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_plan_an_event_list_2_name".localized, cards: [
                                    Card(placeholderName: "", customCardName: nil),
                                    Card(placeholderName: "", customCardName: nil),
                                    ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_plan_an_event_list_3_name".localized, cards: [
                                    ],
                                     customListName: nil
                                ),
                                ],
                               customBoardName: nil,
                               overlays: [
                                Overlay(title: "project_plan_an_event_board_overlay_title".localized, subtitle: "project_plan_an_event_board_overlay_subtitle".localized),
                                Overlay(title: "project_plan_an_event_list_overlay_title".localized, subtitle: "project_plan_an_event_list_overlay_subtitle".localized),
                                Overlay(title: "project_plan_an_event_card_overlay_title".localized, subtitle: "project_plan_an_event_card_overlay_subtitle".localized),
                                Overlay(title: "project_plan_an_event_create_overlay_title".localized, subtitle: "project_plan_an_event_create_overlay_subtitle".localized),
                               ])
        case .trackGoal:
            self.name = "project_track_a_goal".localized
            self.board = Board(backgroundColor: .blue,
                               defaultName: "project_track_a_goal_board_name".localized,
                               lists: [
                                List(defaultName: "project_track_a_goal_list_1_name".localized,
                                     cards: [
                                        Card(placeholderName: "project_track_a_goal_card_1_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_track_a_goal_card_2_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_track_a_goal_card_3_name".localized, customCardName: nil),
                                    ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_track_a_goal_list_2_name".localized, cards: [
                                    Card(placeholderName: "", customCardName: nil),
                                    Card(placeholderName: "", customCardName: nil),
                                    ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_track_a_goal_list_3_name".localized, cards: [
                                    ],
                                     customListName: nil
                                ),
                               ],
                               customBoardName: nil,
                               overlays: [
                                Overlay(title: "project_track_a_goal_board_overlay_title".localized, subtitle: "project_track_a_goal_board_overlay_subtitle".localized),
                                Overlay(title: "project_track_a_goal_list_overlay_title".localized, subtitle: "project_track_a_goal_list_overlay_subtitle".localized),
                                Overlay(title: "project_track_a_goal_card_overlay_title".localized, subtitle: "project_track_a_goal_card_overlay_subtitle".localized),
                                Overlay(title: "project_track_a_goal_create_overlay_title".localized, subtitle: "project_track_a_goal_create_overlay_subtitle".localized),
                               ])
        case .manageProject:
            self.name = "project_manage_a_project".localized
            self.board = Board(backgroundColor: .green,
                               defaultName: "project_manage_a_project_board_name".localized,
                               lists: [
                                List(defaultName: "project_manage_a_project_list_1_name".localized,
                                     cards: [
                                        Card(placeholderName: "project_manage_a_project_card_1_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_manage_a_project_card_2_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_manage_a_project_card_3_name".localized, customCardName: nil),
                                    ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_manage_a_project_list_2_name".localized, cards: [
                                    Card(placeholderName: "", customCardName: nil),
                                    Card(placeholderName: "", customCardName: nil),
                                    ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_manage_a_project_list_3_name".localized, cards: [
                                    ],
                                     customListName: nil
                                ),
                               ],
                               customBoardName: nil,
                               overlays: [
                                Overlay(title: "project_manage_a_project_board_overlay_title".localized, subtitle: "project_manage_a_project_board_overlay_subtitle".localized),
                                Overlay(title: "project_manage_a_project_list_overlay_title".localized, subtitle: "project_manage_a_project_list_overlay_subtitle".localized),
                                Overlay(title: "project_manage_a_project_card_overlay_title".localized, subtitle: "project_manage_a_project_card_overlay_subtitle".localized),
                                Overlay(title: "project_manage_a_project_create_overlay_title".localized, subtitle: "project_manage_a_project_create_overlay_subtitle".localized),
                               ])
        case .increaseProductivity:
            self.name = "project_increase_productivity".localized
            self.board = Board(backgroundColor: .orange,
                               defaultName: "project_increase_productivity_board_name".localized,
                               lists: [
                                List(defaultName: "project_increase_productivity_list_1_name".localized,
                                     cards: [
                                        Card(placeholderName: "project_increase_productivity_card_1_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_increase_productivity_card_2_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_increase_productivity_card_3_name".localized, customCardName: nil),
                                    ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_increase_productivity_list_2_name".localized, cards: [
                                    Card(placeholderName: "", customCardName: nil),
                                    Card(placeholderName: "", customCardName: nil),
                                    ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_increase_productivity_list_3_name".localized, cards: [
                                    ],
                                     customListName: nil
                                ),
                               ],
                               customBoardName: nil,
                               overlays: [
                                Overlay(title: "project_increase_productivity_board_overlay_title".localized, subtitle: "project_increase_productivity_board_overlay_subtitle".localized),
                                Overlay(title: "project_increase_productivity_list_overlay_title".localized, subtitle: "project_increase_productivity_list_overlay_subtitle".localized),
                                Overlay(title: "project_increase_productivity_card_overlay_title".localized, subtitle: "project_increase_productivity_card_overlay_subtitle".localized),
                                Overlay(title: "project_increase_productivity_create_overlay_title".localized, subtitle: "project_increase_productivity_create_overlay_subtitle".localized),
                               ])
        case .somethingElse:
            self.name = "project_something_else".localized
            self.board = Board(backgroundColor: .gray,
                               defaultName: "project_something_else_board_name".localized,
                               lists: [
                                List(defaultName: "project_something_else_list_1_name".localized,
                                     cards: [
                                        Card(placeholderName: "project_something_else_card_1_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_something_else_card_2_name".localized, customCardName: nil),
                                        Card(placeholderName: "project_something_else_card_3_name".localized, customCardName: nil),
                                    ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_something_else_list_2_name".localized, cards: [
                                    Card(placeholderName: "", customCardName: nil),
                                    Card(placeholderName: "", customCardName: nil),
                                    ],
                                     customListName: nil
                                ),
                                List(defaultName: "project_something_else_list_3_name".localized, cards: [
                                    ],
                                     customListName: nil
                                ),
                               ],
                               customBoardName: nil,
                               overlays: [
                                Overlay(title: "project_something_else_board_overlay_title".localized, subtitle: "project_increase_productivity_board_overlay_subtitle".localized),
                                Overlay(title: "project_something_else_list_overlay_title".localized, subtitle: "project_increase_productivity_list_overlay_subtitle".localized),
                                Overlay(title: "project_something_else_card_overlay_title".localized, subtitle: "project_increase_productivity_card_overlay_subtitle".localized),
                                Overlay(title: "project_something_else_create_overlay_title".localized, subtitle: "project_increase_productivity_create_overlay_subtitle".localized),
                               ])
        }
    }
    
}
