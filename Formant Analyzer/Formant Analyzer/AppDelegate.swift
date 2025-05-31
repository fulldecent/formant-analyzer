//
//  AppDelegate.swift
//  Formant Analyzer
//
//  Created by William Entriken on 10.09.2020.
//  Copyright © 2020 William Entriken. All rights reserved.
//

import UIKit

/// Handles application lifecycle events for the formant analyzer app.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    /// Called when the application finishes launching.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }

    /// Configures a new scene session.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
