//
//  ChatStream.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-20.
//

import Foundation
internal import Combine

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
    
    private var accumulatedResponse: String = ""
    private var displayUpdateTimer: Timer?
    private var pendingResponseUpdate = false
    private let throttleInterval: TimeInterval = 0.06
    
    init() {
        startThrottler()
    }
    
    func appendToken(_ token: String, isReasoning: Bool = false) {
        if isReasoning {
            if curState == .idle {
                curState = .thinking
                showThinking = false
            }
            thinkingText += token
            return
        }
        
        if curState == .thinking {
            curState = .responding
        }
        
        accumulatedResponse += token
        pendingResponseUpdate = true
    }
    
    private func startThrottler() {
        displayUpdateTimer = Timer.scheduledTimer(withTimeInterval: throttleInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.pendingResponseUpdate else { return }
            self.visibleMarkdown = self.accumulatedResponse
            self.pendingResponseUpdate = false
        }
        
        RunLoop.main.add(displayUpdateTimer!, forMode: .common)
    }
    
    func reset() {
        thinkingText = ""
        visibleMarkdown = ""
        accumulatedResponse = ""
        curState = .idle
        showThinking = nil
    }
    
    deinit {
        displayUpdateTimer?.invalidate()
    }
}
