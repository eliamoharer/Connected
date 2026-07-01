//
//  Models.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//

import Foundation
import UIKit

struct Message: Identifiable, Codable {
    var id = UUID()
    var text: String = ""
    let isUser: Bool
    
    private var imageData: [Data]?
    var stream: ChatStream?
    
    var images: [UIImage]? {
        imageData?.compactMap { UIImage(data: $0) }
    }
    
    init(id: UUID = UUID(), text: String = "", isUser: Bool, images: [UIImage]? = nil, stream: ChatStream? = nil) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.stream = stream
        self.imageData = images?.compactMap { $0.jpegData(compressionQuality: 0.7) }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, isUser, imageData
    }
}


extension UIImage {
    func resizeMax(maxDim: CGFloat) -> UIImage {
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
