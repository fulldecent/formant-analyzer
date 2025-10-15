// Vowel Practice
// (c) William Entriken
// See LICENSE

import SwiftUI

@main
struct Vowel_PracticeApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(viewModel)
        }
    }
}
