//
//  HyperparamMenu.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//

import SwiftUI

struct ParamMenuView: View {
    @ObservedObject var vm: ChatViewModel
    
    var body: some View {
        Menu("Model Settings..") {
            VStack(spacing: 12) {
                ControlGroup(content: {
                    Button(action: {
                        vm.curLLMProfile = LLMProfile(type: "Fast", temperature: 0.7, top_p: 0.80, top_k: 20, presence_penalty: 1.5, thinking: false)
                        vm.isThinking = false
                    }, label: {
                        Text("Fast")
                        Image(systemName: "bolt")
                    })
                    
                    Button(action: {
                        vm.curLLMProfile = LLMProfile(type: "General", temperature: 1.0, top_p: 0.95, top_k: 20, presence_penalty: 1.5, thinking: true)
                        vm.isThinking = true
                    }, label: {
                        Text("General")
                        Image(systemName: "text.book.closed")
                    })
                    
                    Button(action: {
                        vm.curLLMProfile = LLMProfile(type: "Smart", temperature: 0.6, top_p: 0.95, top_k: 20, presence_penalty: 0.0, thinking: true)
                        vm.isThinking = true
                    }, label: {
                        Text("Smart")
                        Image(systemName: "brain")
                    })
                }, label: {
                    Text("Qwen 3.6 35B A3B")
                })
                .tint(.purple.opacity(0.7))
                
                ControlGroup(content: {
                    Button(action: {
                        vm.curLLMProfile = LLMProfile(type: "Fast", temperature: 1.0, top_p: 0.95, top_k: 64, presence_penalty: 0.0, thinking: false)
                        vm.isThinking = false
                    }, label: {
                        Text("Fast")
                        Image(systemName: "bolt")
                    })
                    
                    Button(action: {
                        vm.curLLMProfile = LLMProfile(type: "General", temperature: 1.0, top_p: 0.95, top_k: 64, presence_penalty: 0.0, thinking: true)
                        vm.isThinking = true
                    }, label: {
                        Text("General")
                        Image(systemName: "text.book.closed")
                    })
                    
                    Button(action: {
                        vm.curLLMProfile = LLMProfile(type: "Smart", temperature: 1.0, top_p: 0.95, top_k: 64, presence_penalty: 0.0, thinking: true)
                        vm.isThinking = true
                    }, label: {
                        Text("Smart")
                        Image(systemName: "brain")
                    })
                }, label: {
                    Text("Gemma 31B")
                })
                .tint(.green.opacity(0.7))
            }
        }
    }
}
