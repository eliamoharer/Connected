//
//  ChatBubble.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//
import SwiftUI
import SwiftStreamingMarkdown

// ai generated
private let markdownConfig: MarkdownRenderConfig = {
    let text = UIColor(named: "AIText") ?? .label
    let surface = UIColor(named: "UserBG") ?? .secondarySystemBackground
    let d = MarkdownRenderConfig.default

    return d
        .withParagraphStyle(value: .init(textFonts: d.paragraphStyle.textFonts, textColor: text))
        .withHeadingStyle(value: .init(
            h1Font: d.headingStyle.h1Font, h2Font: d.headingStyle.h2Font,
            h3Font: d.headingStyle.h3Font, h4Font: d.headingStyle.h4Font,
            h5Font: d.headingStyle.h5Font, h6Font: d.headingStyle.h6Font,
            textColor: text
        ))
        .withBlockQuoteStyle(value: .init(textFonts: d.blockQuoteStyle.textFonts, textColor: text))
        .withOrderedListStyle(value: .init(textFonts: d.orderedListStyle.textFonts, textColor: text))
        .withTableStyle(value: .init(
            textFonts: d.tableStyle.textFonts,
            headerTextColor: text,
            regularTextColor: text,
            headerBackgroundColor: surface.withAlphaComponent(0.15),
            borderColor: surface.withAlphaComponent(0.3),
            actionButtonColor: .systemBlue
        ))
        .withInlineStyle(value: .init(
            boldTextColor: text,
            linkTextFont: d.inlineStyle.linkTextFont,
            linkTextColor: .systemBlue,
            codeTextFont: d.inlineStyle.codeTextFont,
            codeTextColor: text,
            codeBackgroundColor: surface.withAlphaComponent(0.15),
            codeUnderlineColor: surface.withAlphaComponent(0.3)
        ))
}()

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
        .padding(.vertical, 8)
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
                HStack {
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
                    
                    Spacer()
                }
                if stream.showThinking == true {
                    ThinkingText(stream: stream)
                        .transition(.blurReplace)
                }
            }
            
            StreamedMarkdownView(source: stream, config: markdownConfig)
                .padding(.horizontal, 24)
            
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
        //.fixedSize(horizontal: false, vertical: true)
    }
}

private struct HistoryMessageView: View {
    let message: Message
    let vm: ChatViewModel
    let isLast: Bool
        
    var body: some View {
        VStack(alignment: .leading) {
            MarkdownView(text: message.text, config: markdownConfig)
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
        //.fixedSize(horizontal: false, vertical: true)
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
            .offset(y: -2)
            
            if showRetry {
                Button(action: {
                    onRetry()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .padding(-12)
                .offset(y: -1)
            }
        }
        .foregroundStyle(Color("AIText"))
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .alert("Hide this message?", isPresented: $showReport) {
            Button("Cancel", role: .cancel) { }
            Button("Hide", role: .destructive) {
                onReport()
            }
        } message: {
            Text("This removes and hides the message from your chat on this device.")
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
