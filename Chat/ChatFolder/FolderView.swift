//
//  FolderView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-26.
//

import SwiftUI

struct FolderView: View {
    enum Field: Hashable {
            case prompt
            case search
        }
    
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
    
    @FocusState private var focusedField: Field?
    
    private var filteredChats: [SavedChat] {
        guard !searchText.isEmpty else { return vm.savedChats }
        
        let search = searchText.lowercased()
        return vm.savedChats.filter { chat in
            return chat.title.lowercased().contains(search)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
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
            TextEditor(text: $vm.systemPrompt)
                .focused($focusedField, equals: .prompt)
                .background(.clear, in: .rect(cornerRadius: 12))
                .overlay(.primary, in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
                .clipShape(.rect(cornerRadius: 12))
                .frame(minHeight: 100)
            Divider()
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(filteredChats.reversed()) { chat in
                    HStack {
                        Button(chat.title) {
                            vm.messages = chat.messages
                        }
                        .padding(.vertical, 2)
                        
                        Spacer()
                        
                        Menu("...") {
                            
                            Button("Rename", systemImage: "pencil") {
                                tempChat = chat
                                renameString = chat.title
                                showRename = true
                            }
                            Button("Delete…", systemImage: "trash", role: .destructive) {
                                tempChat = chat
                                showDelete = true
                            }
                        }
                    }
                }
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
            HStack() {
                if focusedField != .search {
                    Button {
                        //guard !vm.messages.isEmpty else { return }
                        let newChat = SavedChat(messages: vm.messages)
                        vm.savedChats.append(newChat)
                        vm.messages = []
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color("AIText"))
                    }
                    .padding()
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: .circle)
                }
                TextField("Search chats...", text: $searchText)
                    .focused($focusedField, equals: .search)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .padding()
                    .frame(height: 44)
                    .background(.ultraThinMaterial, in: .capsule)
                
                if focusedField != .search {
                    Button("Help", systemImage: "questionmark") {
                        showHelp = true
                    }
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: .circle)
                } else {
                    Button("Close", systemImage: "xmark") {
                        searchText = ""
                        focusedField = nil
                    }
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: .circle)
                }
            }
            .padding()
            
        }
        .padding(.horizontal, 16)
        .safeAreaPadding(.top, 75)
        .glassEffect(.regular, in: .rect)
        .ignoresSafeArea(focusedField == .search ? .container : .all, edges: .all)
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
