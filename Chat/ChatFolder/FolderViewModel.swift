//
//  FolderViewModel.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-29.
//
import SwiftUI
internal import Combine

@MainActor
class FolderViewModel: ObservableObject {
    
    @Published var buttonEnabled: [Bool] = [true]
    @Published var profiles: [LLMProfile] = []
    @Published var buttonCount: Int = 0
    
    @Published var isFolderOpen = false
    @Published var drawerPosition: CGFloat?
    var isDragging = false
    let threshold = CGFloat(10) * .pi / 180
    
    func createProfile(type: String, temperature: Double?, max_tokens: Int?, top_p: Double?, top_k: Int?, min_p: Double?, presence_penalty: Double?, repetition_penalty: Double?, thinking: Bool) -> LLMProfile {
        return LLMProfile(type: type.isEmpty ? "Profile \(buttonCount + 1)" : type, temperature: temperature, max_tokens: max_tokens, top_p: top_p, top_k: top_k, min_p: min_p, presence_penalty: presence_penalty, repetition_penalty: repetition_penalty, thinking: thinking)
    }
    
    func FolderGesture(drawerWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { [self] value in
                guard abs(value.translation.height) < tan(threshold) * abs(value.translation.width) || isDragging else { return }
                
                isDragging = true
                
                if isFolderOpen {
                    drawerPosition = min(0, max(-drawerWidth, value.translation.width))
                } else {
                    drawerPosition = max(-drawerWidth, min(value.translation.width - drawerWidth, 0))
                }
                
                
            }
            .onEnded { [self] value in
                guard isDragging else { return }
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
                    if value.translation.width > 8 {
                        isFolderOpen = true
                        drawerPosition = 0
                    } else {
                        isFolderOpen = false
                        drawerPosition = -drawerWidth
                    }
                }
                isDragging = false
            }
    }
}
