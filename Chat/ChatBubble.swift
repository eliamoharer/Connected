//
//  ChatBubble.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//
import SwiftUI

struct ChatBubble: View {
    @ObservedObject var stream: ChatStream
    @ObservedObject var vm: ChatViewModel
    
    @State private var showReport = false
    
    let message: Message
    
    init(message: Message, vm: ChatViewModel) {
        self.message = message
        self.vm = vm
        self.stream = message.stream ?? ChatStream()
        
        if self.stream.visibleMarkdown.isEmpty && !message.text.isEmpty {
                self.stream.visibleMarkdown = message.text
            }
    }
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing) {
                    if let images = message.images, !images.isEmpty {
                    
                        LazyVGrid(columns: [GridItem(.fixed(64)), GridItem(.fixed(64)), GridItem(.fixed(64)), GridItem(.fixed(64))], alignment: .trailing) {
                            ForEach(images.indices, id: \.self) { index in
                                Image(uiImage: images[index].resizeMax(maxDim: 128)!)
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
            } else {
                    VStack(alignment: .leading) {
                        if stream.showThinking != nil {
                            Button(action: {
                                withAnimation(.snappy) {
                                    stream.showThinking = stream.showThinking == true ? false : true
                                }
                            }) {
                                Text(stream.showThinking! ? "Close Thinking" : "Show Thinking")
                            }
                            .padding(10)
                            .glassEffect()
                            .padding(.horizontal, 14)
                            .foregroundStyle(Color.gray)
                            .padding(.bottom, 0)
                            
                            // Show thinking text only when this message's toggle is on
                            if stream.showThinking == true {
                                ThinkingText(stream: stream)
                                    .transition(.blurReplace)
                            }
                        }
                        
                        StreamObserverView(stream: stream)
                            .padding(.horizontal, 24)
                            .font(.system(size: 18))
                        
                        if stream.curState == .idle {
                            HStack(spacing: 16) {
                                Button(action: {
                                    UIPasteboard.general.string = stream.visibleMarkdown
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
                            .padding(.horizontal, 24)
                            .padding(.top, -10)
                            .alert("Are you sure you want to report this message?", isPresented: $showReport) {
                                Button("Cancel", role: .cancel) { }
                                Button("Report & Hide", role: .destructive) {
                                    vm.report(message: message)
                                }
                            } message: {
                                Text("This will hide it from your view and permanently delete the message from your device.")
                            }
                        }
                        
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    struct ThinkingText: View {
        @ObservedObject var stream: ChatStream
        
        var body: some View {
            Text(LocalizedStringKey(stream.thinkingText))
                .padding(.horizontal, 24)
                .foregroundStyle(Color.gray)
                .font(.system(size: 12))
        }
    }
    
    struct StreamObserverView: View {
        @ObservedObject var stream: ChatStream
        @State private var webViewHeight: CGFloat = 0
        
        var body: some View {
            StreamingMarkdownWebView(markdown: $stream.visibleMarkdown, height: $webViewHeight, showThinking: stream.showThinking)
                .frame(height: webViewHeight)
        }
    }
