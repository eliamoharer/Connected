//
//  ChatStream.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-20.
//

import Foundation
internal import Combine
import SwiftStreamingMarkdown

enum StreamState {
    case idle
    case thinking
    case responding
}

class ChatStream: ObservableObject {
    @Published var thinkingText: String = ""
    @Published var visibleMarkdown: String = ""
    @Published var curState: StreamState = .idle
    @Published var showThinking: Bool?
    
    private var accumulatedThinking: String = ""
    private var accumulatedResponse: String = ""
    private var displayUpdateTimer: Timer?
    private var pendingResponseUpdate = false
    private let throttleInterval: TimeInterval = 0.06
    
    var fullResponse: String { accumulatedResponse }
    
    init() {
        startThrottler()
    }
    
    func appendToken(_ token: String, isReasoning: Bool) {
        if isReasoning {
            if curState == .idle || curState == .responding {
                curState = .thinking
                showThinking = false
            }
            accumulatedThinking += token
        } else {
            if curState != .responding {
                curState = .responding
            }
            accumulatedResponse += token
        }
        pendingResponseUpdate = true
    }
    
    func finish() {
        displayUpdateTimer?.invalidate()
        displayUpdateTimer = nil
        flush()
        curState = .idle
    }
    
    private func flush() {
        if thinkingText != accumulatedThinking {
            thinkingText = accumulatedThinking
        }
        if visibleMarkdown != accumulatedResponse {
            visibleMarkdown = accumulatedResponse
        }
        pendingResponseUpdate = false
    }
    
    private func startThrottler() {
        displayUpdateTimer = Timer.scheduledTimer(withTimeInterval: throttleInterval, repeats: true) { [weak self] _ in
            guard let self, self.pendingResponseUpdate else { return }
            self.flush()
        }
        
        RunLoop.main.add(displayUpdateTimer!, forMode: .common)
    }
    
    func updateLocal(text: String) {
        guard text != accumulatedResponse else { return }
        if curState != .responding {
            curState = .responding
        }
        accumulatedResponse = text
        pendingResponseUpdate = true
    }
    
    deinit {
        displayUpdateTimer?.invalidate()
    }
}

extension ChatStream: StreamedMarkdownSource {
    var text: AsyncStream<String> {
        AsyncStream { continuation in
            let cancellable = $visibleMarkdown.sink { continuation.yield($0) }
            continuation.onTermination = { _ in cancellable.cancel() }
        }
    }
}


