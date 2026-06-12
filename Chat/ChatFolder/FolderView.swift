//
//  FolderView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-26.
//

import SwiftUI

struct FolderView: View {
    @ObservedObject var vm: ChatViewModel
    @ObservedObject var fvm: FolderViewModel
    @State private var searchText: String = ""
    @State private var showRename: Bool = false
    @State private var showDelete: Bool = false
    @State private var tempChat: SavedChat?
    @State private var renameString: String = ""
    @State private var showSettings: Bool = false
    
    @State private var showAdd: Bool = false
    @State private var showHelp: Bool = false
    @State private var showDeleteAll: Bool = false
    
    @State private var isSearching: Bool = false
    @FocusState private var editorFocus: Bool
    
    private var filteredChats: [SavedChat] {
        guard !searchText.isEmpty else { return vm.savedChats }
        
        let search = searchText.lowercased()
        return vm.savedChats.filter { chat in
            return chat.title.lowercased().contains(search)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if !isSearching {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                        VStack {
                            Button {
                                vm.curLLMProfile = nil
                                fvm.buttonEnabled = 0
                            } label: {
                                (fvm.buttonEnabled == 0 ? Color.white : Color.black.opacity(0.2))
                                    .frame(width: 75, height: 50)
                                    .clipShape(.rect(cornerRadius: 12))
                                    .overlay(.black, in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
                            }
                            
                            Text("Native")
                                .font(.caption)
                        }
                        
                        ForEach(fvm.profiles.indices, id: \.self) { index in
                            let profile = fvm.profiles[index]
                            
                            VStack {
                                Button {
                                    vm.curLLMProfile = profile
                                    fvm.buttonEnabled = index + 1
                                } label: {
                                    (fvm.buttonEnabled == index + 1 ? Color.white : Color.black.opacity(0.2))
                                        .frame(width: 75, height: 50)
                                        .clipShape(.rect(cornerRadius: 12))
                                        .overlay(.black, in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        fvm.profiles.remove(at: index)
                                        if fvm.buttonEnabled == index + 1 {
                                            fvm.buttonEnabled = 0
                                        } else if fvm.buttonEnabled != 0 {
                                            fvm.buttonEnabled -= 1
                                        }
                                    } label: {
                                        Label("Delete Profile", systemImage: "trash")
                                    }
                                } preview: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "info.circle")
                                            .imageScale(.large)
                                        Text(vm.profileInfo(profile: profile))
                                            .font(.body)
                                    }
                                    .padding()
                                }
                                Text(profile.type ?? "Profile \(fvm.profiles.count)")
                                    .font(.caption)
                            }
                        }
                        
                        VStack {
                            Button {
                                showAdd = true
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 75, height: 50)
                                    .clipShape(.rect(cornerRadius: 12))
                                    .overlay(.primary.opacity(0.5), in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
                                    .foregroundStyle(.primary.opacity(0.5))
                            }
                            
                            Text(" ")
                                .font(.caption)
                        }
                    }
                    
                    Toggle(isOn: $vm.sysPromptIsEnabled) {
                        Text("Personal Instructions")
                        Text("Customize how the model responds")
                    }
                    ZStack(alignment: .bottomTrailing) {
                        TextEditor(text: $vm.systemPrompt)
                            .scrollContentBackground(.hidden)
                            .background(.clear, in: .rect(cornerRadius: 12))
                            .overlay(.primary, in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
                            .clipShape(.rect(cornerRadius: 12))
                            .frame(minHeight: 100)
                            .focused($editorFocus)
                            .padding(.bottom, !editorFocus ? 0 : 16)
                        
                        if editorFocus {
                            HStack(spacing: -8) {
                                Button("Clear") {
                                    vm.systemPrompt = ""
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .padding(-10)
                                .padding(.bottom, 10)
                                .buttonStyle(.glass)
                                .padding()
                                
                                if UIPasteboard.general.string != nil {
                                    Button("Paste") {
                                        vm.systemPrompt = UIPasteboard.general.string ?? ""
                                    }
                                    .frame(minWidth: 44, minHeight: 44)
                                    .padding(-10)
                                    .padding(.bottom, 10)
                                    .buttonStyle(.glass)
                                    .padding()
                                }
                                Button("Dismiss") {
                                    editorFocus = false
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .padding(-10)
                                .padding(.bottom, 10)
                                .buttonStyle(.glassProminent)
                                .padding()
                            }
                        }
                    }
                    .animation(.bouncy, value: editorFocus)
                    Divider()
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        ForEach(filteredChats.reversed()) { chat in
                            HStack {
                                Button(chat.title) {
                                    vm.messages = chat.messages
                                }
                                .padding(.vertical, 2)
                                
                                Spacer()
                                
                                Menu {
                                    
                                    Button("Rename", systemImage: "pencil") {
                                        tempChat = chat
                                        renameString = chat.title
                                        showRename = true
                                    }
                                    Button("Delete…", systemImage: "trash", role: .destructive) {
                                        tempChat = chat
                                        showDelete = true
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .frame(width: 44, height: 44)
                                }
                                .padding(-12)
                                .padding(.horizontal, 4)
                                
                                //.background(in: .capsule)
                                .padding(.horizontal, 8)
                            }
                        }
                        if !vm.savedChats.isEmpty && !isSearching {
                            HStack {
                                Spacer()
                                Button("Delete All", systemImage: "trash", role: .destructive) {
                                    showDeleteAll = true
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                    .foregroundStyle(Color.aiText)
                }
                .alert(
                    "Rename \(tempChat?.title ?? "") to..",
                    isPresented: $showRename,
                    actions: {
                        TextField("New Name...", text: $renameString)
                        
                        Button("Cancel", role: .cancel) { }
                        
                        Button("Save") {
                            if let chat = tempChat,
                               let index = vm.savedChats.firstIndex(where: { $0.id == chat.id }) {
                                vm.savedChats[index].title = renameString
                            }
                        }
                    }
                )
                .alert(
                    "Delete \(tempChat?.title ?? "")?",
                    isPresented: $showDelete,
                    actions: {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            if let chat = tempChat,
                               let index = vm.savedChats.firstIndex(where: { $0.id == chat.id }) {
                                vm.savedChats.remove(at: index)
                            }
                        }
                    }
                )
                .alert(
                    "Delete all chats?",
                    isPresented: $showDeleteAll,
                    actions: {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            vm.savedChats = []
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .safeAreaPadding(.top, 75)
            .searchable(text: $searchText, isPresented: $isSearching)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("New Chat", systemImage: "square.and.pencil") {
                        let newChat = SavedChat(messages: vm.messages)
                        vm.savedChats.append(newChat)
                        vm.messages = []
                    }
                }
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("Help", systemImage: "questionmark") {
                        showHelp = true
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .ignoresSafeArea(isSearching ? .container : .all, edges: .all)
        }
        .glassEffect(.regular, in: .rect)
        .ignoresSafeArea()
        .sheet(isPresented: $showAdd) {
            FolderButtonView(fvm: fvm, vm: vm)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
    }
}


#Preview {
    FolderView(vm: ChatViewModel(), fvm: FolderViewModel())
}
