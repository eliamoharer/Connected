//
//  Models.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//

import Foundation
import UIKit

struct Message: Identifiable, Codable {
    let id = UUID()
    var text: String = ""
    let isUser: Bool
    
    var images: [UIImage]?
    var thinkingText: String = ""
    var visibleMarkdown: String = ""
    var stream: ChatStream?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case isUser
    }
}

extension Message {
       // Returns what should be displayed in the bubble's text area
       var currentResponseText: String {
           guard let stream = stream else { return text }
           switch stream.curState {
           case .thinking:  return stream.thinkingText
           case .responding: return stream.visibleMarkdown
           case .idle:      return ""
           }
       }
   }

extension UIImage {
    func resizeMax(maxDim: CGFloat) -> UIImage? {
        let currentMax = max(size.width, size.height)
        
        if currentMax <= maxDim {
            return self
        }
        
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDim, height: maxDim / aspectRatio)
        } else {
            newSize = CGSize(width: maxDim * aspectRatio, height: maxDim)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}



struct LLMProfile: Identifiable, Codable {
    var id = UUID()
    
    var type: String?
    var temperature: Double?
    var max_tokens: Int?
    var top_p: Double?
    var top_k: Int?
    var min_p: Double?
    var presence_penalty: Double?
    var repetition_penalty: Double?
    var thinking: Bool
}

struct SavedChat: Identifiable, Codable {
    let id: UUID
    
    var messages: [Message]
    var title: String
    
    // Initialize a new chat and automatically generate the title from the first message
    init(id: UUID = UUID(), messages: [Message]) {
        self.id = id
        self.messages = messages
        
        if let firstText = messages.first?.text {
            let trimmed = firstText.trimmingCharacters(in: .whitespaces)
            self.title = trimmed.isEmpty ? "Empty Chat" : (trimmed.count > 16 ? String(trimmed.prefix(16)) + "..." : trimmed)
        } else {
            self.title = "Empty Chat"
        }
    }
    
    // Initialize for manual edits (like renaming)
    init(id: UUID = UUID(), messages: [Message], title: String) {
        self.id = id
        self.messages = messages
        self.title = title
    }
}
