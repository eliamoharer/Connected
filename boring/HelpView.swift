//
//  HelpView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-06-10.
//
import SwiftUI
import StoreKit

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Setup")) {
                    DisclosureGroup {
                        Text("1. Ensure your server is running on a valid port. (find the list under **My endpoint isn't showing up!**) \n\n2. Make sure that your host is on 0.0.0.0. This is so your device can access and connect to your phone.\n\n3. Press the brain button (under the send button) and scan. It should automatically pick up your computer.\n\n4. Click the IP, and you should see your downloaded models!\n\n5. Chat with your model and configure parameters at the top of the side menu.")
                        Text("You have access to a system prompt, which acts as hidden instructions behind your chat with the model. You also have access to profiles, which lets you finetune specific parameters.\n\nFor noobs, temperature and thinking will be your primary toggles. Higher temperature increases unpredictability and creativeness.")
                        Text(LegalContent.aiDisclaimer)
                    } label: {
                        Label {
                            Text("Guide to Connected")
                        } icon: {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                    
                    DisclosureGroup {
                        Text("Personally, I use oMLX for macOS, and LM Studio for Windows. Both have very easy setups. Your biggest challenge will be starting your server and finding a model.\n\nTo start your server, make sure it is enabled on your **local network**. There is usually a button to set it and start.\n\nTerminal commands can be preferable. For LM Studio, use\n*lms server start --bind 0.0.0.0*\n\nFor ollama, use\nOLLAMA_HOST=0.0.0.0 ollama serve\n\n**Careful on public WiFi!**\n\n")
                        Text("On both platforms, you will have the option to freely download models. I will provide a list of recommendations.\n\n**Entry Level** (2-8GB VRAM)\nGemma 4 E2B and E4B\nQwen 3.5 2B and 4B\n\n**Mid-tier** (8-16GB VRAM)\nQwen 3.5 9B\nGemma 4 12B\n\n**High-End** (16-32GB VRAM)\nGemma 26B A4B or 31B\nQwen 3.6 35B A3B or 27B\nNemotron 3 Nano Omni 30B A3B\n\nI'd always recommend Q4-bit for speed and general use.")
                    } label: {
                        Label {
                            Text("What do I install?")
                        } icon: {
                            Image(systemName: "arrowshape.down.fill")
                        }
                    }
                }
                
                Section(header: Text("Troubleshooting")) {
                    DisclosureGroup {
                        Text("Ports may cause trouble. This app only scans over several. **If you have no models downloaded, it will not pick up your server.**\n\nHere are the supported ports. Make sure it matches with one of these:\n\n7590, 11434, 1234, 8000, 8080, 5000\n\nIf it still doesn't show up, make sure your server is running, and that your endpoint is accessible on the local network (set host to 0.0.0.0, especially with Ollama).\n\nIf you set your server to require an authentication key (password), make sure it's set in the menu before you scan.\n\nSometimes, running the scan one or two more times can work too.")
                    } label: {
                        Text("My endpoint isn't showing up!")
                    }
                    
                    DisclosureGroup {
                        Text("Is the model fit for your computer? Ensure its within memory constraints, and that it's actually loaded and ready to run.\n\nSometimes, models can take anywhere from 5 seconds to a minute to load.")
                    } label: {
                        Text("It's not typing!")
                    }
                    
                    DisclosureGroup {
                        Text("Some models don't have vision capabilities. Check to make sure before downloading!")
                    } label: {
                        Text("It can't see my pictures!")
                    }
                    
                    DisclosureGroup {
                        Text("If you are using Apple Intelligence, you will not have access to custom profiles or personal instructions. This is a compatibility issue.")
                    } label: {
                        Text("Personal instructions greyed out?")
                    }
                }
                
                Section(header: Text("Support")) {
                    Link(destination: URL(string: "mailto:\(LegalContent.supportEmail)")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    
                    Button("Restore Purchases") {
                        Task {
                            try? await AppStore.sync()
                        }
                    }
                }
                
                Section(header: Text("Legal & Compliance")) {
                    DisclosureGroup {
                        Text(LegalContent.privacyPolicy)
                    } label: {
                        Label {
                            Text("Privacy Policy")
                        } icon: {
                            Image(systemName: "lock.shield")
                        }
                    }
                    
                    DisclosureGroup {
                        Text(LegalContent.termsOfService)
                    } label: {
                        Label {
                            Text("Terms of Service")
                        } icon: {
                            Image(systemName: "doc.text")
                        }
                    }
                }
                Text("Special thank you to:\n\nMicrosoft for SwiftStreamingMarkdown")
                    .font(.caption)
            }
            .navigationTitle("Help & Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
