//
//  FolderModels.swift
//  Connected
//
//  Created by Elia Moharer on 2026-06-03.
//
import SwiftUI
internal import Combine

struct Parameter {
    let id = UUID()
    
    let type: String
    var value: Double
    var isEnabled: Bool
}

struct FolderButtonView: View {
    @ObservedObject var fvm: FolderViewModel
    
    @State private var newThinking: Bool = true
    @State private var isEditing: Bool = false
    @State private var profileName: String = ""
    
    @State private var temperature = Parameter(type: "Temperature", value: 1, isEnabled: true)
    @State private var maxTok = Parameter(type: "Max Output", value: 8192, isEnabled: false)
    @State private var topP = Parameter(type: "Top P", value: 0.95, isEnabled: false)
    @State private var topK = Parameter(type: "Top K", value: 20, isEnabled: false)
    @State private var minP = Parameter(type: "Min P", value: 0.05, isEnabled: false)
    @State private var presPen = Parameter(type: "Presence Penalty", value: 1, isEnabled: false)
    @State private var repPen = Parameter(type: "Repetition Penalty", value: 1, isEnabled: false)
    
    @State private var showAdvanced: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    private var parameterArray: [Parameter] {
        [temperature, maxTok, topP, topK, minP, presPen, repPen]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    Toggle("Enable Thinking", isOn: $newThinking)
                    
                    ParamSlider(min: 0,
                                max: 2,
                                step: 0.05,
                                isInt: false,
                                param: $temperature)
                    Divider()
                    ParamSlider(min: 0,max: 16384,step: 256,isInt: true,param: $maxTok)
                    Divider()
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Profile Info")
                            
                            TextField("Enter Name..", text: $profileName)
                                .multilineTextAlignment(TextAlignment.center)
                                .autocorrectionDisabled(true)
                                .autocapitalization(.none)
                                .padding(.horizontal, 10)
                            
                                .padding(.vertical, 4)
                                .frame(width: 120)
                                .background(.gray.opacity(0.08), in: .capsule)
                                .padding(.leading, -8)
                        }
                        
                        Rectangle()
                            .fill(Color.primary.opacity(0.3))
                            .frame(width: 1) // Set explicit thickness
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Thinking:")
                                Spacer()
                                Text("\(newThinking ? "On" : "Off")")
                                    .foregroundStyle(newThinking ? .green : .red)
                            }
                            
                            ForEach(parameterArray, id: \.id) { param in
                                if param.isEnabled {
                                    HStack {
                                        Text("\(param.type)")
                                        Spacer()
                                        Text("\(param.value, format: .number)")
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .overlay(.black.opacity(0.3), in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
                    
                    HStack(alignment: .center) {
                        Toggle(!showAdvanced ? "Show Advanced Options" : "Hide Advanced Options", isOn: $showAdvanced)
                            .toggleStyle(.button)
                    }
                    
                    if showAdvanced {
                        ParamSlider(min: 0,max: 1,step: 0.01,isInt: false,param: $topP)
                        Divider()
                        ParamSlider(min: 0,max: 100,step: 1,isInt: true,param: $topK)
                        Divider()
                        ParamSlider(min: 0,max: 1,step: 0.01,isInt: false,param: $minP)
                        Divider()
                        ParamSlider(min: 0,max: 2,step: 0.05,isInt: false,param: $presPen)
                        Divider()
                        ParamSlider(min: 1,max: 2,step: 0.05,isInt: false,param: $repPen)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        let creation = fvm.createProfile(type: profileName, temperature: temperature.isEnabled ? temperature.value : nil,
                                                         max_tokens: maxTok.isEnabled ? Int(maxTok.value) : nil,
                                                         top_p: topP.isEnabled ? topP.value : nil,
                                                         top_k: topK.isEnabled ? Int(topK.value) : nil,
                                                         min_p: minP.isEnabled ? minP.value : nil,
                                                         presence_penalty: presPen.isEnabled ? presPen.value : nil,
                                                         repetition_penalty: repPen.isEnabled ? repPen.value : nil,
                                                         thinking: newThinking)
                        fvm.profiles.append(creation)
                        fvm.buttonCount += 1
                        for idx in fvm.buttonEnabled.indices {
                            fvm.buttonEnabled[idx] = false
                        }
                        fvm.buttonEnabled.append(true)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ParamSlider: View {
    let min: Double
    let max: Double
    let step: Double
    let isInt: Bool
    
    @Binding var param: Parameter
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(param.type)
                    .font(.body)
                    .foregroundStyle(param.isEnabled ? .primary : .secondary)
                
                Spacer()
                
                Toggle(param.isEnabled ? "Custom" : "Default", isOn: $param.isEnabled)
                    .toggleStyle(.button)
                    .tint(.blue)
            }
            
            HStack {
                Slider(value: $param.value, in: min...max, step: step)
                    .disabled(!param.isEnabled)
                
                if param.isEnabled {
                    TextField("", value: $param.value, format: .number)
                        .disabled(!param.isEnabled)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        .overlay(.black.opacity(0.2), in: .rect(cornerRadius: 12).stroke(lineWidth: 1))
                } else {
                    Text("Auto")
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .center)
                }
            }
        }
    }
}

#Preview {
    FolderButtonView(fvm: FolderViewModel())
}
