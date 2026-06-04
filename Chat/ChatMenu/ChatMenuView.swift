//
//  ChatMenuView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//

import SwiftUI

struct ChatMenuView: View {
    @ObservedObject var vm: ChatViewModel
    @ObservedObject var scanner: FindEndpoints
    @State private var showPrompt = false
    @State private var tailEndpoint: String = ""
    
    var body: some View {
        Menu {
            Section(header: Text("Endpoints")) {
                if vm.scanner.isScanning {
                    Button("Scanning...") { }
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
            
            Section(header: Text("Models")) {
//                if !vm.model.isEmpty {
//                    ParamMenuView(vm: vm)
//                }
                
                if !vm.models.isEmpty {
                    Picker("Model", selection: $vm.model) {
                        ForEach(vm.models, id: \.self) { endModel in
                            Text(endModel)
                                .tag(endModel)
                        }
                    }
                }
            }
            
            Divider()
            
            Button {
                Task { await vm.scanner.scan() }
            } label: {
                Text(vm.endpoint.isEmpty ? "Find Endpoints.." : "Refresh Endpoints..")
                
                if !vm.endpoint.isEmpty && !vm.isTail {
                    Text("@ \(vm.endpoint)")
                }
            }
            .menuActionDismissBehavior(.disabled)
            
            Button {
                showPrompt = true
            } label: {
                Text("Tailscale")
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
        .alert("Use Tailscale", isPresented: $showPrompt) {
            TextField("IP:Port", text: $tailEndpoint)
                .keyboardType(.numbersAndPunctuation)
                .autocapitalization(.none)
            Button("Cancel", role: .cancel) { tailEndpoint = "" }
            Button("Connect") {
                let parts = tailEndpoint.split(separator: ":")
                if parts.count == 2, let port = Int(parts[1]) {
                    Task {
                        let result = await scanner.check(ip: String(parts[0]), port: port)
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
            Text("Enter your Tailscale IP and desired port")
        }
    }
}
