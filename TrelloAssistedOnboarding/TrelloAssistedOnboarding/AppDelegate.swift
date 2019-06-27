//
//  AppDelegate.swift
//  TrelloAssistedOnboarding
//
//  Created by Lou Franco on 6/27/19.
//  Copyright © 2019 Trello. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        self.window = UIWindow(frame: UIScreen.main.bounds)

        let flow = FlowController()

        self.window?.rootViewController = flow.navVC
        self.window?.makeKeyAndVisible()

        return true
    }
}
