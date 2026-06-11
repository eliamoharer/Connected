//
//  StreamingMarkdownWebView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-20.
//

import SwiftUI
import WebKit

struct StreamingMarkdownWebView: UIViewRepresentable {
    @Binding var markdown: String
    @Binding var height: CGFloat
    var showThinking: Bool?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setValue(false, forKey: "drawsBackground")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        
        if let filepath = Bundle.main.path(forResource: "chat", ofType: "html") {
            let url = URL(fileURLWithPath: filepath)
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let escapedMarkdown = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
                
        let jsCode = "updateContent(`\(escapedMarkdown)`);"
        
        uiView.evaluateJavaScript(jsCode) { _, error in
            if let error = error {
                print("Error updating content: \(error.localizedDescription)")
            }
            
            uiView.evaluateJavaScript("document.documentElement.scrollHeight") { result, _ in
                if let newHeight = result as? CGFloat, newHeight != self.height {
                    DispatchQueue.main.async {
                        self.height = newHeight
                    }
                }
            }
        }
    }
}
