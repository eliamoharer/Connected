//
//  ChatViewModel.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//

import SwiftUI
internal import Combine
import FoundationModels
import StoreKit

@MainActor
class ChatViewModel: ObservableObject {
    let scanner = FindEndpoints()
    
    @Published var localModel = SystemLanguageModel.default
    
    private var localSession = LanguageModelSession()
    
    private var activeTask: Task<Void, Never>?
    
    private let endpointKey = "lastSelectedEndpoint"
    private let modelKey = "lastSelectedModel"
    private let tailKey = "ifSelectedTail"
    private let profileKey = "lastSelectedProfile"
    private let historyKey = "persistedSavedChats"
    private let systemPromptKey = "lastSystemPrompt"
    private let systemPromptIsEnabledKey = "lastSystemPromptIsEnabled"
    private let APIKeyKey = "lastSelectedAPIKey"
    
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
    
    @Published var APIKey: String = "" {
        didSet {
            UserDefaults.standard.set(APIKey, forKey: APIKeyKey)
        }
    }
    
    @Published var editingMessageID: Message.ID? = nil
    
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
    
    @Published var isCustomUnlocked: Bool = false
    
    init() {
        loadHistoryFromUserDefaults()
        loadProfileFromUserDefaults()
        
        systemPrompt = UserDefaults.standard.string(forKey: systemPromptKey) ?? ""
        sysPromptIsEnabled = UserDefaults.standard.bool(forKey: systemPromptIsEnabledKey)
        APIKey = UserDefaults.standard.string(forKey: APIKeyKey) ?? ""
        
        if let savedEndpoint = UserDefaults.standard.string(forKey: endpointKey) {
            isTail = UserDefaults.standard.bool(forKey: tailKey)
            
            let parts = savedEndpoint.split(separator: ":")
            if parts.count == 2, let port = Int(parts[1]) {
                Task {
                    let result = await scanner.check(ip: String(parts[0]), port: port, key: APIKey)
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
        
        Task {
            for await result in StoreKit.Transaction.currentEntitlements(for: "eliamoharer.connect.customunlocked") {
                if case .verified(let transaction) = result {
                    self.isCustomUnlocked = transaction.revocationDate == nil
                }
            }
            
            for await result in StoreKit.Transaction.updates {
                if case .verified(let transaction) = result {
                    self.isCustomUnlocked = transaction.revocationDate == nil
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
        
        let userMessage = Message(text: userText, isUser: true, images: userImages)
        let stream = ChatStream()
        
        messages.append(userMessage)
        
        let response = Message(text: "", isUser: false, stream: stream)
        
        messages.append(response)
        
        let conversation = Array(messages.dropLast())
        let responseID = response.id
        
        let curModel = model
        let curEndpoint = endpoint
        let curProfile = curLLMProfile
        let sysEnabled = sysPromptIsEnabled
        let sysPrompt = systemPrompt
        let key = APIKey
        
        activeTask = Task.detached(priority: .userInitiated) {
            _ = await fetchLLMResponse(for: conversation,
                                       model: curModel,
                                       endpoint: curEndpoint,
                                       profile: curProfile,
                                       sysPromptIsEnabled: sysEnabled,
                                       systemPrompt: sysPrompt,
                                       APIKey: key) { token, isReasoning in
                Task { @MainActor in
                    stream.appendToken(token, isReasoning: isReasoning)
                    
                }
            }
            Task { @MainActor in
                stream.finish()
                
                if let index = self.messages.firstIndex(where: { $0.id == responseID }) {
                    self.messages[index].text = stream.fullResponse
                }
                
                if !Task.isCancelled {
                    self.isResponding = false
                }
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
    
    func resendMessage() {
        messages.removeLast()
        activeTask?.cancel()
        
        isResponding = true
        
        let stream = ChatStream()
        let response = Message(text: "", isUser: false, stream: stream)
        
        messages.append(response)
        
        
        let conversation = Array(messages.dropLast())
        let responseID = response.id
        
        let curModel = model
        let curEndpoint = endpoint
        let curProfile = curLLMProfile
        let sysEnabled = sysPromptIsEnabled
        let sysPrompt = systemPrompt
        let key = APIKey
        
        activeTask = Task.detached(priority: .userInitiated) {
            _ = await fetchLLMResponse(for: conversation,
                                       model: curModel,
                                       endpoint: curEndpoint,
                                       profile: curProfile,
                                       sysPromptIsEnabled: sysEnabled,
                                       systemPrompt: sysPrompt,
                                       APIKey: key) { token, isReasoning in
                Task { @MainActor in
                    stream.appendToken(token, isReasoning: isReasoning)
                    
                }
            }
            Task { @MainActor in
                stream.finish()
                
                if let index = self.messages.firstIndex(where: { $0.id == responseID }) {
                    self.messages[index].text = stream.fullResponse
                }
                
                if !Task.isCancelled {
                    self.isResponding = false
                }
            }
        }
    }
    
    func sendLocalMessage() async {
        do {
            messages.append(Message(text: prompt, isUser: true, images: selectedImages))
            let userText = prompt
            prompt = ""
            let response = try await localSession.respond(to: userText)
            
            await MainActor.run {
                messages.append(Message(text: response.content, isUser: false))
            }
        } catch {
            messages.append(Message(text: error.localizedDescription, isUser: false))
        }
    }
    
    func report(message: Message) {
        messages.removeAll { $0.id == message.id }
    }
    
    func edit(text: String, editmessage: Message) {
        if let index = messages.firstIndex(where: { $0.id == editmessage.id }) {
            messages[index].text = text
            messages[index].stream = nil
        }
        editingMessageID = nil
    }
    
    func abort() {
        activeTask?.cancel()
        isResponding = false
    }
}
