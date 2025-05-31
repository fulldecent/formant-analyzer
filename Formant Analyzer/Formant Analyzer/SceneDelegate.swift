//
//  SceneDelegate.swift
//  Formant Analyzer
//
//  Created by William Entriken on 10.09.2020.
//  Copyright © 2020 William Entriken. All rights reserved.
//

import UIKit
import SwiftUI

/// Handles scene lifecycle events for the formant analyzer app.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    /// Configures the window and sets the root view when the scene connects.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            NSLog("Failed to cast scene to UIWindowScene")
            return
        }
        
        let viewModel = FormantAnalyzerViewModel()
        let contentView = ContentView()
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: contentView.environmentObject(viewModel))
        self.window = window
        window.makeKeyAndVisible()
    }
}
