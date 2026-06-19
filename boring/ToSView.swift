//
//  TOSView.swift
//  Connected
//
//  Created by Elia Moharer on 2026-06-10.
//

import SwiftUI

struct ToSView: View {
    @AppStorage("validToS") private var validToS = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Connected.")
                .foregroundStyle(Color("AIText"))
                .font(.largeTitle)
                .bold()
                .italic()
                .padding(.bottom, -16)
            
            ScrollView(.vertical) {
                VStack {
                    Text("Privacy Policy")
                        .multilineTextAlignment(.center)
                        .font(.title2)
                    Text(LegalContent.privacyPolicy)
                }
                Divider()
                    .padding(16)
                VStack {
                    Text("Terms of Service")
                        .multilineTextAlignment(.center)
                        .font(.title2)
                    Text(LegalContent.termsOfService)
                }
            }
            .scrollContentBackground(.hidden)
            .padding()

            VStack(spacing: 16) {
                Text("By tapping Accept and Continue, you agree to the Terms of Service and verify that you have reviewed the Privacy Policy.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button {
                    validToS = true
                } label: {
                    Text("Accept and Continue")
                        .foregroundColor(Color("BackgroundColor"))
                        .padding(16)
                        .padding(.horizontal, 16)
                        .background(Color.primary)
                        .cornerRadius(16)
                }
            }
        }
        .background(Color("BackgroundColor").ignoresSafeArea())
    }
}

#Preview {
    ToSView()
}
