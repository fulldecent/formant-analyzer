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

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
#else
typealias PlatformViewRepresentable = UIViewRepresentable
#endif

struct WebView: PlatformViewRepresentable {
    #if os(macOS)
    func makeNSView(context: Context) -> WKWebView { makeView() }
    func updateNSView(_ view: WKWebView, context: Context) {}
    #else
    func makeUIView(context: Context) -> WKWebView { makeView() }
    func updateUIView(_ view: WKWebView, context: Context) {}
    #endif
    
    private func makeView() -> WKWebView {
        let htmlURL = Bundle.main.url(forResource: "help", withExtension: "html")!
        let webView = WKWebView()
        webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
        return webView
    }
}

#Preview {
    HelpPageView()
        .frame(width: 400, height: 600)
}
