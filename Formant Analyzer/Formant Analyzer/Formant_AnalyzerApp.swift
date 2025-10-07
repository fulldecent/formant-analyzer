// Formant Analyzer
// (c) William Entriken
// See LICENSE

import SwiftUI

@main
struct Formant_AnalyzerApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(viewModel)
        }
    }
}
