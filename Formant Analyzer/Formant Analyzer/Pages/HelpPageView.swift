// Formant Analyzer
// (c) William Entriken
// See LICENSE

import SwiftUI
import WebKit

struct HelpPageView: View {
    var body: some View {
        WebView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let htmlURL = Bundle.main.url(forResource: "help", withExtension: "html")!
        let webView = WKWebView()
        webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op: the HTML will relayout itself and respond to color scheme changes
    }
}

#Preview {
    HelpPageView()
        .frame(width: 400, height: 600)
}
