//
//  ChatMenuView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//

import SwiftUI
import StoreKit

struct ChatMenuView: View {
    @ObservedObject var vm: ChatViewModel
    @ObservedObject var scanner: FindEndpoints
    @State private var showPrompt = false
    @State private var showKey = false
    @State private var showPaywall = false
    @State private var tailEndpoint: String = ""
    @State private var APIKey: String = ""
 
    
    var body: some View {
        Menu {
            Section(header: Text("Models")) {
                if !vm.models.isEmpty {
                    Picker("Model", selection: $vm.model) {
                        ForEach(vm.models, id: \.self) { endModel in
                            Text(endModel)
                                .tag(endModel)
                        }
                    }
                }
            }
            
            Section(header: Text("Endpoints")) {
                if vm.scanner.isScanning {
                    Button("Scanning...") { }.disabled(true)
                }
                
                ForEach(Array(vm.scanner.endpoints.enumerated()), id: \.offset) { _, foundEndpoint in
                    
                    let tmpEndpoint = "\(foundEndpoint.ip):\(foundEndpoint.port)"
                    Button(tmpEndpoint) {
                        vm.endpoint = tmpEndpoint
                        vm.isTail = false
                        vm.models = foundEndpoint.models
                    }
                    .menuActionDismissBehavior(.disabled)
                }
            }
            
            Divider()
            
            Button {
                Task { await vm.scanner.scan(key: vm.APIKey) }
            } label: {
                Text(vm.endpoint.isEmpty ? "Find Endpoints.." : "Refresh Endpoints..")
                
                if !vm.endpoint.isEmpty && !vm.isTail {
                    Text("@ \(vm.endpoint)")
                }
            }
            .menuActionDismissBehavior(.disabled)
            
            Button {
                showKey = true
            } label: {
                Text("Auth Key")
                Text("\(vm.APIKey.isEmpty ? "Empty" : "\(vm.APIKey)")")
            }
            
            Button {
                if vm.isCustomUnlocked {
                    showPrompt = true
                } else {
                    showPaywall = true
                }
            } label: {
                Text(vm.isCustomUnlocked ? "Custom Endpoint" : "Custom Endpoint ($0.99)")
                
                if !vm.endpoint.isEmpty && vm.isTail {
                    Text("@ \(vm.endpoint)")
                }
            }

        } label: {
            Image(systemName: "brain")
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .padding(-12)
        .alert("Use Custom", isPresented: $showPrompt) {
            TextField("IP:Port", text: $tailEndpoint)
                .keyboardType(.numbersAndPunctuation)
                .autocapitalization(.none)
            Button("Cancel", role: .cancel) { tailEndpoint = "" }
            Button("Connect") {
                let parts = tailEndpoint.split(separator: ":")
                if parts.count == 2, let port = Int(parts[1]) {
                    Task {
                        let result = await scanner.check(ip: String(parts[0]), port: port, key: vm.APIKey)
                        await MainActor.run {
                            if (result != nil) {
                                vm.endpoint = tailEndpoint
                                vm.models = result?.2 ?? []
                                vm.isTail = true
                            }
                            
                        }
                    }
                }
            }
        } message: {
            Text("Enter your custom IP and desired port")
        }
        .alert("Authentication Key", isPresented: $showKey) {
            TextField("Auth Key", text: $APIKey)
                .keyboardType(.numbersAndPunctuation)
                .autocapitalization(.none)
            Button("Cancel", role: .cancel) { APIKey = "" }
            Button("Save") {
                vm.APIKey = APIKey
            }
        } message: {
            Text("Some local providers allow you to set an auth key (i.e a password).\n\nThis prevents others on your network from accessing your endpoint.")
        }
        .sheet(isPresented: $showPaywall) {
            VStack {
                Text("Custom Endpoints")
                    .font(.largeTitle.bold())
                    .padding(.top, 30)
                
                Text("Unlock to set a custom endpoint.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom)
                
                StoreView(ids: ["eliamoharer.connect.customunlocked"])
                    .storeButton(.visible, for: .restorePurchases)
            }
            .presentationDetents([.medium, .large])
        }
    }
}
