//
//  ChatViewModel.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//

import SwiftUI
internal import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @ObservedObject var scanner = FindEndpoints()
    
    private var activeTask: Task<Void, Never>?
    
    private let endpointKey = "lastSelectedEndpoint"
    private let modelKey = "lastSelectedModel"
    private let tailKey = "ifSelectedTail"
    private let profileKey = "lastSelectedProfile"
    private let historyKey = "persistedSavedChats"
    private let systemPromptKey = "lastSystemPrompt"
    private let systemPromptIsEnabledKey = "lastSystemPromptIsEnabled"
    
    @Published var systemPrompt: String = "" {
        didSet {
            UserDefaults.standard.set(systemPrompt, forKey: systemPromptKey)
        }
    }
    @Published var sysPromptIsEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(sysPromptIsEnabled, forKey: systemPromptIsEnabledKey)
        }
    }
    
    @Published var isResponding: Bool = false
    @Published var prompt: String = ""
    @Published var messages: [Message] = []
    @Published var selectedImages: [UIImage] = []
    @Published var isThinking: Bool = true
    @Published var models: [String] = []
    @Published var curLLMProfile: LLMProfile? {
        didSet {
            saveProfileToUserDefaults()
        }
    }
    
    @Published var endpoint: String = "" {
        didSet {
            UserDefaults.standard.set(endpoint, forKey: endpointKey)
        }
    }
    @Published var model: String = "" {
        didSet {
            UserDefaults.standard.set(model, forKey: modelKey)
        }
    }
    @Published var isTail: Bool = false {
        didSet {
            UserDefaults.standard.set(isTail, forKey: tailKey)
        }
    }
    @Published var savedChats: [SavedChat] = [] {
        didSet {
            saveHistoryToUserDefaults()
        }
    }
    
    init() {
        loadHistoryFromUserDefaults()
        loadProfileFromUserDefaults()
        
        systemPrompt = UserDefaults.standard.string(forKey: systemPromptKey) ?? ""
        sysPromptIsEnabled = UserDefaults.standard.bool(forKey: systemPromptIsEnabledKey)
        
        if let savedEndpoint = UserDefaults.standard.string(forKey: endpointKey) {
            isTail = UserDefaults.standard.bool(forKey: tailKey)
            
            let parts = savedEndpoint.split(separator: ":")
            if parts.count == 2, let port = Int(parts[1]) {
                Task {
                    let result = await scanner.check(ip: String(parts[0]), port: port)
                    await MainActor.run {
                        if result != nil {
                            endpoint = savedEndpoint
                            models = result?.2 ?? []
                            
                            if let savedModel = UserDefaults.standard.string(forKey: modelKey) {
                                if models.contains(savedModel) {
                                    model = savedModel
                                }
                            }
                        }
                        else {
                            endpoint = ""
                        }
                    }
                }
            }
        }
    }
    
    private func saveHistoryToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(savedChats)
            UserDefaults.standard.set(encoded, forKey: historyKey)
        } catch {
        }
    }
    
    private func loadHistoryFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: historyKey) {
            do {
                let decoder = JSONDecoder()
                self.savedChats = try decoder.decode([SavedChat].self, from: data)
            } catch {
            }
        } else {
            self.savedChats = []
        }
    }
    
    private func saveProfileToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(curLLMProfile)
            UserDefaults.standard.set(encoded, forKey: profileKey)
        } catch {
        }
    }
    
    private func loadProfileFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: profileKey) {
            do {
                let decoder = JSONDecoder()
                self.curLLMProfile = try decoder.decode(LLMProfile.self, from: data)
            } catch {
            }
        } else {
            self.curLLMProfile = nil
        }
    }
    
    func sendMessage() {
        guard !prompt.isEmpty || !selectedImages.isEmpty else {
            return
        }
        
        activeTask?.cancel()
        
        if let previous = messages.indices.last, let previousMessage = messages[previous].stream {
            messages[previous].text = previousMessage.fullResponse
        }
        
        isResponding = true
        
        let userText = prompt
        let userImages = selectedImages
        prompt = ""
        selectedImages.removeAll()
        
        messages.append(Message(text: userText, isUser: true, images: userImages))
        let stream = ChatStream()
        
        let response = Message(text: "", isUser: false, stream: stream)
        
        withAnimation(.bouncy()) {
            messages.append(response)
        }
        
        
        let conversation = Array(messages.dropLast())
        let responseID = response.id
        
        activeTask = Task {
            _ = await fetchLLMResponse(for: conversation,
                                       model: model,
                                       endpoint: endpoint,
                                       profile: curLLMProfile,
                                       sysPromptIsEnabled: sysPromptIsEnabled,
                                       systemPrompt: systemPrompt) { token, isReasoning in
                Task { @MainActor in stream.appendToken(token, isReasoning: isReasoning)
                    
                }
            }
            
            stream.finish()
            
            if let index = messages.firstIndex(where: { $0.id == responseID }) {
                messages[index].text = stream.fullResponse
            }
            
            if !Task.isCancelled {
                isResponding = false
            }
        }
        
    }
    
    func profileInfo(profile: LLMProfile) -> String {
        var text = ""
        
        text += "Thinking: \(profile.thinking ? "On" : "Off")"
        
        if let temperature = profile.temperature {
            text += "\nTemperature: \(temperature)"
        }
        
        if let maxTokens = profile.max_tokens {
            text += "\nMax Tokens: \(maxTokens)"
        }
        
        if let topP = profile.top_p {
            text += "\nTop P: \(topP)"
        }
        
        if let topK = profile.top_k {
            text += "\nTop K: \(topK)"
        }
        
        if let minP = profile.min_p {
            text += "\nMin P: \(minP)"
        }
        
        if let presencePenalty = profile.presence_penalty {
            text += "\nPresence Penalty: \(presencePenalty)"
        }
        
        if let repetitionPenalty = profile.repetition_penalty {
            text += "\nRepetition Penalty: \(repetitionPenalty)"
        }
        
        return text
    }
    
    func report(message: Message) {
        messages.removeAll { $0.id == message.id }
    }
    
    func abort() {
        activeTask?.cancel()
        isResponding = false
    }
}
