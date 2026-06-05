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
    @State private var showHelp: Bool = false
    @State private var showSettings: Bool = false
    
    @State private var showAdd: Bool = false
    
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
                        for idx in fvm.buttonEnabled.indices {
                            fvm.buttonEnabled[idx] = false
                        }
                        fvm.buttonEnabled[0] = true
                    } label: {
                        (fvm.buttonEnabled[0] ? Color.white : Color.black.opacity(0.2))
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
                            for idx in fvm.buttonEnabled.indices {
                                fvm.buttonEnabled[idx] = false
                            }
                            fvm.buttonEnabled[index + 1] = true
                        } label: {
                            (fvm.buttonEnabled[index + 1] ? Color.white : Color.black.opacity(0.2))
                                .frame(width: 75, height: 50)
                                .clipShape(.rect(cornerRadius: 12))
                                .overlay(.black, in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
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
                            .overlay(.black.opacity(0.2), in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
                            .foregroundStyle(.black.opacity(0.2))
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
                .background(.clear, in: .rect(cornerRadius: 12))
                .overlay(.black, in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
            
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
                        // 4. Perform the mutation safely here after confirming
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
            
            HStack {
                Button {
                    //guard !vm.messages.isEmpty else { return }
                    let newChat = SavedChat(messages: vm.messages)
                    vm.savedChats.append(newChat)
                    vm.messages = []
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(.black)
                }
                .padding()
                .glassEffect(in: .circle)
                
                TextField("Search chats...", text: $searchText)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .padding()
                    .glassEffect(.clear, in: Capsule())
                
                Button("Help", systemImage: "questionmark") {
                    showHelp = true
                }
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .frame(width: 50, height: 50)
                .glassEffect(in: .circle)
            }
            .padding()
            
            
        }
        .padding(.horizontal, 16)
        .safeAreaPadding(.top, 75)
        .glassEffect(.regular, in: .rect)
        .ignoresSafeArea()
        .sheet(isPresented: $showAdd) {
            FolderButtonView(fvm: fvm, vm: vm)
                .presentationDetents([.medium])
        }
    }
}


#Preview {
    FolderView(vm: ChatViewModel(), fvm: FolderViewModel())
}
