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
    
    @Published var buttonEnabled: Int = 0 {
        didSet {
            UserDefaults.standard.set(buttonEnabled, forKey: buttonKey)
        }
    }
    @Published var profiles: [LLMProfile] = [] {
        didSet {
            saveProfileToUserDefaults()
        }
    }
    
    @Published var isFolderOpen = false
    @Published var disableEdit = false
    @Published var drawerPosition: CGFloat?
    var isDragging = false
    let threshold = CGFloat(10) * .pi / 180
    
    private let buttonKey = "buttonKey"
    private let profilesKey = "profilesKey"
    
    init() {
        loadProfileFromUserDefaults()
        buttonEnabled = UserDefaults.standard.integer(forKey: buttonKey)
    }
    
    func createProfile(type: String, temperature: Double?, max_tokens: Int?, top_p: Double?, top_k: Int?, min_p: Double?, presence_penalty: Double?, repetition_penalty: Double?, thinking: Bool) -> LLMProfile {
        return LLMProfile(type: type.isEmpty ? "Profile \(profiles.count + 1)" : type, temperature: temperature, max_tokens: max_tokens, top_p: top_p, top_k: top_k, min_p: min_p, presence_penalty: presence_penalty, repetition_penalty: repetition_penalty, thinking: thinking)
    }
    
    func FolderGesture(drawerWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { [self] value in
                if !isDragging && !isFolderOpen && value.startLocation.x > 80 { return }
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
                withAnimation(.interactiveSpring(response: 0.30, dampingFraction: 0.85)) {
                    if value.translation.width > 8 {
                        isFolderOpen = true
                        drawerPosition = 0
                    } else {
                        isFolderOpen = false
                        drawerPosition = -drawerWidth
                    }
                }
                isDragging = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
    
    private func saveProfileToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(profiles)
            UserDefaults.standard.set(encoded, forKey: profilesKey)
        } catch {
        }
    }
    
    private func loadProfileFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            do {
                let decoder = JSONDecoder()
                self.profiles = try decoder.decode([LLMProfile].self, from: data)
            } catch {
            }
        } else {
            self.profiles = []
        }
    }
}

