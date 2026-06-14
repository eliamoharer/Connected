//
//  ChatBubble.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//
import SwiftUI

struct ChatBubble: View {
    let message: Message
    let vm: ChatViewModel
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing) {
                    if let images = message.images, !images.isEmpty {
                        LazyVGrid(columns: [GridItem(.fixed(64)), GridItem(.fixed(64)), GridItem(.fixed(64)), GridItem(.fixed(64))], alignment: .trailing) {
                            ForEach(images.indices, id: \.self) { index in
                                Image(uiImage: images[index])
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(maxWidth: 300)
                        .padding(.horizontal, 16)
                    }
                    
                    if !message.text.isEmpty {
                        Text(LocalizedStringKey(message.text))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 11)
                            .foregroundStyle(Color("UserText"))
                            .background(Color("UserBG").opacity(0.9), in: .rect(cornerRadius: 24))
                            .font(.system(size: 17))
                            .padding(.horizontal, 16)
                    }
                }
            } else if let stream = message.stream {
                StreamingMessageView(stream: stream, message: message, vm: vm)
            } else {
                HistoryMessageView(message: message, vm: vm)
            }
        }
    }
}

private struct ThinkingText: View {
    @ObservedObject var stream: ChatStream
    
    var body: some View {
        Text(LocalizedStringKey(stream.thinkingText))
            .padding(.horizontal, 24)
            .foregroundStyle(Color.gray)
            .font(.system(size: 12))
    }
}

private struct StreamingMessageView: View {
    @ObservedObject var stream: ChatStream
    let message: Message
    let vm: ChatViewModel
    var body: some View {
        VStack(alignment: .leading) {
            if stream.showThinking != nil {
                Button(action: {
                    withAnimation(.snappy) {
                        stream.showThinking = stream.showThinking != true
                    }
                }) {
                    Text(stream.showThinking == true ? "Close Thinking" : "Show Thinking")
                }
                .padding(10)
                .glassEffect()
                .padding(.horizontal, 14)
                .foregroundStyle(Color.gray)
                
                if stream.showThinking == true {
                    ThinkingText(stream: stream)
                        .transition(.blurReplace)
                }
            }
            
            StreamingMarkdownWebView(markdown: stream.visibleMarkdown, height: $stream.streamHeight)
                .frame(minHeight: stream.streamHeight)
                .padding(.horizontal, 24)
                .animation(.none, value: stream.showThinking)
            
            if stream.curState == .idle && !stream.visibleMarkdown.isEmpty {
                MessageActions(text: stream.visibleMarkdown) {
                    vm.report(message: message)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HistoryMessageView: View {
    let message: Message
    let vm: ChatViewModel
    @State private var height: CGFloat = 10
    
    var body: some View {
        VStack(alignment: .leading) {
            StreamingMarkdownWebView(markdown: message.text, height: $height)
                .frame(minHeight: height)
                .padding(.horizontal, 24)
            
            if !message.text.isEmpty {
                MessageActions(text: message.text) {
                    vm.report(message: message)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct MessageActions: View {
    let text: String
    let onReport: () -> Void
    @State private var showReport = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                UIPasteboard.general.string = text
            }) {
                Image(systemName: "document.on.document")
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .padding(-12)
            
            Button(action: {
                showReport = true
            }) {
                Image(systemName: "flag")
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .padding(-12)
        }
        .foregroundStyle(Color("AIText"))
        .padding(.horizontal, 24)
        .padding(.top, -10)
        .alert("Are you sure you want to report this message?", isPresented: $showReport) {
            Button("Cancel", role: .cancel) { }
            Button("Report & Hide", role: .destructive) {
                onReport()
            }
        } message: {
            Text("This will hide it from your view and permanently delete the message from your device.")
        }
    }
}
