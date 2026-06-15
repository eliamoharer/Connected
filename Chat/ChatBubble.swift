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
    let isEditing: Bool
    let isLast: Bool
    
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
                            .contextMenu {
                                Button("Copy to Clipboard", systemImage: "document.on.document") {
                                    UIPasteboard.general.string = message.text
                                }
                            }
                    }
                }
            } else if isEditing {
                ResponseEditor(text: message.text, onEdited: { vm.edit(text: $0, editmessage: message) })
            } else if let stream = message.stream {
                StreamingMessageView(stream: stream, message: message, vm: vm, isLast: isLast)
            } else {
                HistoryMessageView(message: message, vm: vm, isLast: isLast)
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
    let isLast: Bool
    
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
                MessageActions(text: stream.visibleMarkdown, showRetry: isLast, onEdit: {
                    vm.editingMessageID = message.id
                }, onReport: {
                    vm.report(message: message)
                }, onRetry: {
                    vm.resendMessage()
                })
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HistoryMessageView: View {
    let message: Message
    let vm: ChatViewModel
    let isLast: Bool
    
    @State private var height: CGFloat = 10
    
    var body: some View {
        VStack(alignment: .leading) {
            StreamingMarkdownWebView(markdown: message.text, height: $height)
                .frame(minHeight: height)
                .padding(.horizontal, 24)
            
            if !message.text.isEmpty {
                MessageActions(text: message.text, showRetry: isLast, onEdit: {
                    vm.editingMessageID = message.id
                }, onReport: {
                    vm.report(message: message)
                }, onRetry: {
                    vm.resendMessage()
                })
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct MessageActions: View {
    let text: String
    let showRetry: Bool
    
    let onEdit: () -> Void
    let onReport: () -> Void
    let onRetry: () -> Void
    
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
            
            Button(action: {
                onEdit()
            }) {
                Image(systemName: "bubble.and.pencil")
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .padding(-12)
            .padding(.top, -4)
            
            if showRetry {
                Button(action: {
                    onRetry()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .padding(-12)
                .padding(.top, -3)
            }
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

private struct ResponseEditor: View {
    let text: String
    let onEdited: (String) -> Void
    
    @State var editedText: String = ""
    
    init(text: String, onEdited: @escaping (String) -> Void) {
        self.text = text
        self.onEdited = onEdited
        _editedText = State(initialValue: text)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            TextEditor(text: $editedText)
                .padding(4)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .frame(minHeight: 100)
                .frame(maxHeight: 300)
                .padding(.horizontal, 24)
                .scrollContentBackground(.hidden)
            Button("Save") {
                onEdited(editedText)
            }
            .frame(minWidth: 44, minHeight: 44)
            .padding(.vertical, -2)
            .padding(.horizontal, 8)
            .glassEffect(.clear, in: .capsule)
            .padding(.horizontal, 24)
        }
    }
}
