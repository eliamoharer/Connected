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
                        ScrollView {
                            LazyVStack() {
                                ForEach(vm.messages) {
                                    currentMessage in ChatBubble(message: currentMessage, vm: vm, isEditing: vm.editingMessageID == currentMessage.id, isLast: ((vm.messages.last?.id == currentMessage.id) && !vm.model.isEmpty))
                                }
                            }
                            //.animation(.bouncy, value: vm.messages.count)
                        }
                        .ignoresSafeArea(edges: .top)
                        .defaultScrollAnchor(.bottom, for: .sizeChanges)
                        .contentMargins(.top, 90, for: .scrollContent)
                        .scrollDismissesKeyboard(.interactively)
                        
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
                    .allowsHitTesting(!fvm.isFolderOpen)
                    .ignoresSafeArea(.keyboard, edges: fvm.isFolderOpen ? .bottom : [])
                    
                    FolderView(vm: vm, fvm: fvm)
                        .offset(x: fvm.drawerPosition ?? -drawerWidth)
                        .highPriorityGesture(fvm.FolderGesture(drawerWidth: drawerWidth))
                        .allowsHitTesting(fvm.isFolderOpen)
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
                .transition(.blurReplace)
        }
    }
}

#Preview {
    ContentView()
}
