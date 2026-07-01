//
//  LLMCall.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-14.
//
import Foundation
import UIKit

func fetchLLMResponse(for messages: [Message],
                      model: String,
                      endpoint: String,
                      profile: LLMProfile?,
                      sysPromptIsEnabled: Bool,
                      systemPrompt: String,
                      APIKey: String,
                      onToken: @escaping (String, Bool) -> Void) async {
    guard let url = URL(string: "http://" + endpoint + "/v1/chat/completions") else { return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    request.addValue("Bearer \(APIKey)", forHTTPHeaderField: "Authorization")
    
    var conversation = messages.map { msg -> [String: Any] in
        if msg.isUser, let images = msg.images, !images.isEmpty {
            var content: [[String: Any]] = [["type": "text", "text": msg.text]]
            for image in images {
                if let imageData = image.resizeMax(maxDim: 512).jpegData(compressionQuality: 0.5) {
                    let base64 = imageData.base64EncodedString()
                    content.append(["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]])
                }
            }
            return ["role": "user", "content": content]
        }
        else {
            return ["role": msg.isUser ? "user" : "assistant", "content": msg.text]
        }
    }
    
    if sysPromptIsEnabled && !systemPrompt.isEmpty {
        let systemMessage: [String: Any] = [
            "role": "system",
            "content": systemPrompt
        ]
        conversation.insert(systemMessage, at: 0)
    }
    
    var body: [String: Any] = [
        "model": model,
        "messages": conversation,
        "stream": true,
    ]
    
    if let curProfile = profile {
        if let temperature = curProfile.temperature { body["temperature"] = temperature }
        if let maxTokens = curProfile.max_tokens { body["max_tokens"] = maxTokens }
        if let topP = curProfile.top_p { body["top_p"] = topP }
        if let topK = curProfile.top_k { body["top_k"] = topK }
        if let minP = curProfile.min_p { body["min_p"] = minP }
        if let presencePenalty = curProfile.presence_penalty { body["presence_penalty"] = presencePenalty }
        if let repetitionPenalty = curProfile.repetition_penalty { body["repetition_penalty"] = repetitionPenalty }
        
        body["chat_template_kwargs"] = [
            "enable_thinking": curProfile.thinking
        ]
    }
    
    do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // Use async bytes to read the stream as it comes in
            let (asyncBytes, _) = try await URLSession.shared.bytes(for: request)
            
            for try await line in asyncBytes.lines {
                try Task.checkCancellation()
                guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
                let jsonString = line.dropFirst(6)
                
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let delta = choices.first?["delta"] as? [String: Any] {
                    try Task.checkCancellation()
                    
                    
                    
                    if let reasoning = delta["reasoning"] as? String ?? delta["reasoning_content"] as? String ?? delta["thinking"] as? String {
                        onToken(reasoning, true)
                    }
                    if let content = delta["content"] as? String {
                        onToken(content, false)
                    }
                }
            }
        } catch {
            if !(error is CancellationError) {
                onToken("\n\n**[Error: \(error.localizedDescription)]**", false)
            }
        }
}
