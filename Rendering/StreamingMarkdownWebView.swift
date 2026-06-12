//
//  StreamingMarkdownWebView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-20.
//

import SwiftUI
import WebKit

struct StreamingMarkdownWebView: UIViewRepresentable {
    var markdown: String
    @Binding var height: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "heightChanged")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        
        if let filepath = Bundle.main.path(forResource: "chat", ofType: "html") {
            let url = URL(fileURLWithPath: filepath)
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
            context.coordinator.parent = self
            context.coordinator.render(markdown, in: uiView)
        }
        
        static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
            uiView.configuration.userContentController.removeScriptMessageHandler(forName: "heightChanged")
        }
        
        final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
            var parent: StreamingMarkdownWebView
            
            private var pageReady = false
            private var pendingMarkdown: String?
            private var lastRendered: String?
            
            init(_ parent: StreamingMarkdownWebView) {
                self.parent = parent
            }
            
            func render(_ markdown: String, in webView: WKWebView) {
                guard pageReady else {
                    pendingMarkdown = markdown
                    return
                }
                guard markdown != lastRendered else { return }
                lastRendered = markdown
                
                // JSON-encoding produces a valid, fully escaped JS string literal.
                guard let data = try? JSONEncoder().encode(markdown),
                      let literal = String(data: data, encoding: .utf8) else { return }
                
                webView.evaluateJavaScript("updateContent(\(literal));") { _, error in
                    if let error {
                        print("Error updating content: \(error.localizedDescription)")
                    }
                }
            }
            
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                pageReady = true
                if let markdown = pendingMarkdown {
                    pendingMarkdown = nil
                    render(markdown, in: webView)
                }
            }
            
            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                guard let value = message.body as? Double else { return }
                let newHeight = CGFloat(value)
                if parent.height != newHeight {
                    parent.height = newHeight
                }
            }
        }
}
