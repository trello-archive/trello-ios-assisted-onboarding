//
//  Utils.swift
//  TrelloAssistedOnboarding
//
//  Created by Lou Franco on 6/27/19.
//  Copyright © 2019 Trello. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    func addAutoLaidOutSubview(_ view: UIView) {
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
    }

}
