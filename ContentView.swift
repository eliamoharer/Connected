//
//  ContentView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ChatViewModel()
    @StateObject private var fvm = FolderViewModel()
    
    @AppStorage("validToS") private var validToS = false
    
    @State private var drawerWidth: CGFloat = UIScreen.main.bounds.width
    
    var body: some View {
        if validToS {
            ZStack(alignment: .leading) {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack() {
                                ForEach(vm.messages) {
                                    currentMessage in
                                    ChatBubble(message: currentMessage,
                                               vm: vm,
                                               isEditing: vm.editingMessageID == currentMessage.id,
                                               isLast: vm.messages.last?.id == currentMessage.id)
                                    .id(currentMessage.id)
                                }
                            }
                            .scrollTargetLayout()
                            //.animation(.bouncy, value: vm.messages.count)
                        }
                        .ignoresSafeArea(edges: .top)
                        .defaultScrollAnchor(.bottom, for: .sizeChanges)
                        .contentMargins(.top, 90, for: .scrollContent)
                        // interactively was breaking stuff
                        .scrollDismissesKeyboard(.immediately)
                        .onChange(of: vm.messages.count) {
                            if let lastMessageID = vm.messages.last?.id {
                                withAnimation(.smooth) {
                                    proxy.scrollTo(lastMessageID, anchor: .bottom)
                                }
                            }
                        }
                        
                        .overlay(alignment: .top) {
                            LinearGradient(
                                colors: [
                                    Color("BackgroundColor"),
                                    Color("BackgroundColor").opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 56)
                            .ignoresSafeArea(edges: .top)
                            .allowsHitTesting(false)
                        }
                        
                        .overlay {
                            if vm.messages.isEmpty {
                                VStack {
                                    Spacer()
                                    Text("Connected.")
                                        .foregroundStyle(Color("AIText"))
                                        .font(.largeTitle)
                                        .bold()
                                        .italic()
                                    Text("swipe right")
                                        .foregroundStyle(Color("AIText"))
                                        .font(.caption)
                                        .italic()
                                        .opacity(0.5)
                                        .keyframeAnimator(initialValue: 0.0, repeating: true) { content, xOffset in
                                            content.offset(x: xOffset)
                                        } keyframes: { _ in
                                            KeyframeTrack {
                                                let tempWidth = -drawerWidth/2
                                                LinearKeyframe(0, duration: 0.5)
                                                
                                                CubicKeyframe(-drawerWidth/2 + 40, duration: 0.4)
                                                LinearKeyframe(-drawerWidth/2 + 40, duration: 0.5)
                                                
//                                                CubicKeyframe(-drawerWidth/2 + 65, duration: 0.5)
//                                                CubicKeyframe(-drawerWidth/2 + 55, duration: 0.3)
//                                                CubicKeyframe(-drawerWidth/2 + 85, duration: 0.5)
//                                                CubicKeyframe(-drawerWidth/2 + 75, duration: 0.3)
                                                
                                                //CubicKeyframe(-drawerWidth/2 + 100, duration: 0.8, endVelocity: 0)
                                                
                                                CubicKeyframe(tempWidth + 80, duration: 1.2, endVelocity: 0)
                                                CubicKeyframe(tempWidth + 90, duration: 0.3, endVelocity: 0)
                                                CubicKeyframe(tempWidth + 100, duration: 0.9, endVelocity: 0)
                                                
                                                SpringKeyframe(0, duration: 0.7, spring: .bouncy)
                                            }
                                        }
                                    
                                    Spacer()
                                }
                                .font(.system(size: 17, design: .serif))
                                .transition(.blurReplace)
                            }
                        }
                        
                        .safeAreaInset(edge: .bottom) {
                            ChatView(vm: vm)
                                .opacity(fvm.isFolderOpen ? 0 : 1)
                            //.animation(.snappy, value: vm.prompt)
                        }
                        .ignoresSafeArea(.container, edges: .bottom)
                    }
                }
                .allowsHitTesting(!fvm.isFolderOpen)
                .ignoresSafeArea(.keyboard, edges: fvm.isFolderOpen ? .bottom : [])
                
                FolderView(vm: vm, fvm: fvm)
                    .offset(x: fvm.drawerPosition ?? -drawerWidth)
                    //.highPriorityGesture(fvm.FolderGesture(drawerWidth: drawerWidth))
                    //.allowsHitTesting(fvm.isFolderOpen)
                //.ignoresSafeArea()
            }
            .sensoryFeedback(.impact(weight: .light), trigger: fvm.isFolderOpen)
            .simultaneousGesture(fvm.FolderGesture(drawerWidth: drawerWidth))
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
            } action: { fullWidth in
                drawerWidth = fullWidth
                if !fvm.isDragging {
                    fvm.drawerPosition = fvm.isFolderOpen ? 0 : -fullWidth
                }
            }
            
        }  else {
            ToSView()
        }
    }
}

#Preview {
    ContentView()
}

