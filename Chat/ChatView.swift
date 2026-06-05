//
//  ChatView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-05-15.
//

import SwiftUI
import PhotosUI

struct ChatView: View {
    @ObservedObject var vm: ChatViewModel
    @State private var sendTapped = false
    @State private var pics: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(spacing: 12) {
            if !vm.selectedImages.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(vm.selectedImages.indices, id: \.self) { image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: vm.selectedImages[image].resizeMax(maxDim: 100)!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: 100, maxHeight: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                Button { vm.selectedImages.remove(at: image)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .red)
                                        .padding(4)
                                        .frame(width: 44, height: 44)
                                        .contentShape(.rect)
                                }
                                .padding(-8)
                            }
                            .scrollTransition { content, phase in content.opacity(phase.isIdentity ? 1.0 : 0.7) }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: 125)
                Divider()
                    .padding(.vertical, -12)
            }
            HStack(spacing: 12) {
                TextField("Type...",  text: $vm.prompt, axis: .vertical)
                    .lineLimit(1...5)
                    .foregroundStyle(Color("AIText"))
                if !vm.isResponding {
                    Button(action: {
                        print("Sent: \(vm.prompt)")
                        sendTapped.toggle()
                        vm.sendMessage()
                    }) {
                        HStack {
                            Image(systemName: "arrow.up")
                                .foregroundStyle(.white)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .symbolEffect(.bounce.up.byLayer, options: .nonRepeating, value: sendTapped)
                        }
                        .background(!vm.prompt.isEmpty || !vm.selectedImages.isEmpty ? .blue : .blue.opacity(0.5), in: .rect(cornerRadius:32))
                        .frame(width: 44, height: 44, alignment: .center)
                        .contentShape(.rect)
                    }
                    .padding(-12)
                } else {
                    Button(action: {
                        sendTapped.toggle()
                        vm.abort()
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                                .symbolEffect(.bounce.up.byLayer, options: .nonRepeating, value: sendTapped)
                        }
                        .background(.red, in: .rect(cornerRadius: 8))
                        .padding(.horizontal, -2)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, vm.selectedImages.isEmpty ? 12 : -12)
            
            HStack {
                // Add in next update
//                Button(action: {
//                    print("test")
//                }) {
//                    Image(systemName: "plus")
//                        .frame(width: 44, height: 44)
//                        .contentShape(.rect)
//                }
//                .padding(-12)
                
                PhotosPicker(selection: $pics, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: "photo.badge.plus")
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                    
                }
                .padding(-12)
                .onChange(of: pics) { _, newPics in
                    Task {
                        for pic in newPics {
                            if let data = try? await pic.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                await MainActor.run { vm.selectedImages.append(uiImage) }
                            }
                        }
                        pics.removeAll()
                    }
                }
                
                Spacer()
                Text(vm.model.isEmpty ? "None" : "\(vm.model): \(vm.curLLMProfile?.type ?? "Native")")
                    .foregroundStyle(.gray)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .truncationMode(.middle)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                ChatMenuView(vm: vm, scanner: vm.scanner)
                
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .glassEffect(.regular.tint(.clear).interactive(), in: .rect(cornerRadius: 32))
        .clipShape(.rect(cornerRadius: 32))
        .padding(24)
        
    }
}
