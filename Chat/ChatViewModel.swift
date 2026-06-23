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
    private var localSessionSysPrompt = ""
    
    private var activeTask: Task<Void, Never>?
    
    private let endpointKey = "lastSelectedEndpoint"
    private let modelKey = "lastSelectedModel"
    private let tailKey = "ifSelectedTail"
    private let profileKey = "lastSelectedProfile"
    private let historyKey = "persistedSavedChats"
    private let systemPromptKey = "lastSystemPrompt"
    private let systemPromptIsEnabledKey = "lastSystemPromptIsEnabled"
    private let APIKeyKey = "lastSelectedAPIKey"
    
    var isLocal: Bool {
        localModel.isAvailable && model.isEmpty
    }
    
    @Published var systemPrompt: String = "" {
        didSet {
            UserDefaults.standard.set(systemPrompt, forKey: systemPromptKey)
        }
    }
    @Published var sysPromptIsEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(sysPromptIsEnabled, forKey: systemPromptIsEnabledKey)
            if isLocal {
                localSession = makeLocal(from: messages)
            }
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
        guard !prompt.isEmpty || !selectedImages.isEmpty else { return }
        guard isLocal || !model.isEmpty else {
            messages.append(Message(text: "No model available", isUser: false))
            return
        }
        
        activeTask?.cancel()
        
        if isLocal {
            let sys = sysPromptIsEnabled ? systemPrompt : ""
            if sys != localSessionSysPrompt || messages.last?.stream != nil {
                localSession = makeLocal(from: messages)
            }
        }
        
        if let previous = messages.indices.last, let previousMessage = messages[previous].stream {
            messages[previous].text = previousMessage.fullResponse
            messages[previous].stream = nil
        }
        
        isResponding = true
        
        let userText = prompt
        let userImages = selectedImages
        prompt = ""
        selectedImages.removeAll()
        
        let stream = ChatStream()
        
        messages.append(Message(text: userText, isUser: true, images: userImages))
        
        let response = Message(text: "", isUser: false, stream: stream)
        
        messages.append(response)
        let responseID = response.id
        
        if isLocal {
            activeTask = Task { await runLocal(userText, stream: stream, responseID: responseID) }
            return
        }
        
        let conversation = Array(messages.dropLast())
        
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
        activeTask?.cancel()
        
        if let last = messages.last, !last.isUser {
            messages.removeLast()
        }
        
        guard messages.last?.isUser == true else {
            isResponding = false
            return
        }
        
        isResponding = true
        
        let stream = ChatStream()
        let response = Message(text: "", isUser: false, stream: stream)
        
        messages.append(response)
        let responseID = response.id
        
        if isLocal {
            guard let lastUserIndex = messages.lastIndex(where: { $0.isUser && $0.stream == nil }) else {
                isResponding = false
                return
            }
            let userText = messages[lastUserIndex].text
            localSession = makeLocal(from: Array(messages[..<lastUserIndex].filter { $0.stream == nil || !$0.text.isEmpty }))
            activeTask = Task { await runLocal(userText, stream: stream, responseID: responseID) }
            return
        }
        
        let conversation = Array(messages.dropLast())
        
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
    
    func report(message: Message) {
        messages.removeAll { $0.id == message.id }
        
        if isLocal {
            localSession = makeLocal(from: messages)
        }
    }
    
    func edit(text: String, editmessage: Message) {
        if let index = messages.firstIndex(where: { $0.id == editmessage.id }) {
            messages[index].text = text
            messages[index].stream = nil
        }
        editingMessageID = nil
        
        if isLocal {
            localSession = makeLocal(from: messages)
        }
    }
    
    func abort() {
        activeTask?.cancel()
        
        if let last = messages.indices.last, let stream = messages[last].stream {
            messages[last].text = stream.fullResponse
            stream.finish()
            messages[last].stream = nil
        }
        
        if isLocal {
            localSession = makeLocal(from: messages)
        }
        
        isResponding = false
    }
    
    func resetLocal() {
        localSessionSysPrompt = sysPromptIsEnabled ? systemPrompt : ""
        if sysPromptIsEnabled && !systemPrompt.isEmpty {
            localSession = LanguageModelSession(instructions: systemPrompt)
        } else {
            localSession = LanguageModelSession()
        }
    }
    
    func syncLocal() {
        guard isLocal else { return }
        localSession = makeLocal(from: messages)
    }
    
    private func makeLocal(from messages: [Message]) -> LanguageModelSession {
        var entries: [Transcript.Entry] = []
        
        if sysPromptIsEnabled, !systemPrompt.isEmpty {
            entries.append(.instructions(Transcript.Instructions(segments: [.text(Transcript.TextSegment(content: systemPrompt))], toolDefinitions: [])))
        }
        
        for message in messages where message.stream == nil || !message.text.isEmpty {
            if message.isUser, !message.text.isEmpty {
                entries.append(.prompt(Transcript.Prompt(segments: [.text(Transcript.TextSegment(content: message.text))])))
            } else if !message.isUser, !message.text.isEmpty {
                entries.append(.response(Transcript.Response(assetIDs: [], segments: [.text(Transcript.TextSegment(content: message.text))])))
            }
        }
        
        localSessionSysPrompt = sysPromptIsEnabled ? systemPrompt : ""
        
        if entries.isEmpty {
            if sysPromptIsEnabled, !systemPrompt.isEmpty {
                return LanguageModelSession(instructions: systemPrompt)
            }
            return LanguageModelSession()
        }
        
        return LanguageModelSession(transcript: Transcript(entries: entries))
    }
    
    private func runLocal(_ userText: String, stream: ChatStream, responseID: Message.ID) async {
        defer { if !Task.isCancelled { isResponding = false } }
        do {
            for try await snapshot in localSession.streamResponse(to: Prompt(userText)) {
                try Task.checkCancellation()
                stream.updateLocal(text: String(snapshot.content))
            }
            stream.finish()
            if let index = messages.firstIndex(where: { $0.id == responseID }) {
                messages[index].text = stream.fullResponse
                messages[index].stream = nil
            }
        } catch is CancellationError {
            stream.finish()
            if let index = messages.firstIndex(where: { $0.id == responseID }),
               messages[index].stream != nil {
                if !stream.fullResponse.isEmpty {
                    messages[index].text = stream.fullResponse
                }
                messages[index].stream = nil
            }
        } catch {
            stream.finish()
            if let index = messages.firstIndex(where: { $0.id == responseID }) {
                messages[index].text = error.localizedDescription
                messages[index].stream = nil
            }
        }
    }
}
