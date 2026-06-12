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
    @State private var position = ScrollPosition(idType: UUID.self)
    
    @FocusState private var chatFocus: Bool
    
    @AppStorage("validToS") private var validToS = false
    
    var body: some View {
        if validToS {
            let drawerWidth = UIScreen.main.bounds.width
                
                ZStack(alignment: .leading) {
                    Color("BackgroundColor")
                        .ignoresSafeArea()
                    
                    VStack {
                        ScrollView {
                            LazyVStack() {
                                ForEach(vm.messages) {
                                    currentMessage in ChatBubble(message: currentMessage, vm: vm)
                                }
                            }
                            .scrollTargetLayout()
                            .animation(.bouncy, value: vm.messages.count)
                        }
                        .scrollPosition($position)
                        .ignoresSafeArea(edges: .top)
                        .defaultScrollAnchor(.bottom, for: .initialOffset)
                        .defaultScrollAnchor(.bottom, for: .sizeChanges)
                        .defaultScrollAnchor(.top, for: .alignment)
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
                                    Spacer()
                                }
                                .font(.system(size: 17, design: .serif))
                                .transition(.blurReplace)
                            }
                        }
                        
                        .safeAreaInset(edge: .bottom) {
                                ChatView(vm: vm)
                                    .focused($chatFocus)
                                    .opacity(fvm.isFolderOpen ? 0 : 1)
                                    //.animation(.snappy, value: vm.prompt)
                            }
                        .ignoresSafeArea(.container, edges: .bottom)
                    }
                    .allowsHitTesting(!fvm.isFolderOpen)
                    .ignoresSafeArea(.keyboard, edges: fvm.isFolderOpen ? .bottom : [])
                    
                    FolderView(vm: vm, fvm: fvm)
                        .offset(x: fvm.drawerPosition ?? -drawerWidth)
                        .allowsHitTesting(fvm.isFolderOpen)
                    //.ignoresSafeArea()
                }
                .sensoryFeedback(.impact(weight: .light), trigger: fvm.isFolderOpen)
                .simultaneousGesture(fvm.FolderGesture(drawerWidth: drawerWidth))
            
        }  else {
            ToSView()
                .transition(.blurReplace)
        }
    }
}

#Preview {
    ContentView()
}
