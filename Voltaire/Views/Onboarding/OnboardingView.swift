//
//  OnboardingView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/4/24.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    Image("brain.gear")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                    
                    VStack(spacing: 4) {
                        Text("Voltaire")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Chat with private and local large language models")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                                
                VStack(alignment: .leading, spacing: 24) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Fast")
                                .font(.headline)
                            Text("Optimized for Apple Silicon")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 8)
                    }
                    
                    Label {
                        VStack(alignment: .leading) {
                            Text("Private")
                                .font(.headline)
                            Text("Runs locally on your device")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "checkmark.shield")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 8)
                    }
                    
                    Label {
                        VStack(alignment: .leading) {
                            Text("Open Source")
                                .font(.headline)
                            Text("View and contribute to the source code")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                Spacer()
                
                NavigationLink(destination: OnboardingInstallModelView(showOnboarding: $showOnboarding)) {
                    Text("Get started")
                        #if os(iOS) || os(visionOS)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        #endif
                        #if os(iOS)
                        .foregroundStyle(.background)
                        #endif
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.horizontal)
            }
            .padding()
            .modifier(CustomNavTitle(title: "Welcome"))
            .toolbar(.hidden)
        }
        #if os(macOS)
        .frame(width: 420, height: 520)
        #endif
    }
}

struct DeviceNotSupportedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.gen2.slash")
                .font(.system(size: 64))
                .foregroundStyle(.primary, .tertiary)
            
            VStack(spacing: 4) {
                Text("Unsupported Device")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("Sorry, Voltaire can only run on devices that support Metal 3.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
