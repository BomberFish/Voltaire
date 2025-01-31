//
//  OnboardingDownloadingModelProgressView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/4/24.
//

import SwiftUI
import MLXLMCommon

struct DownloadIndicator: View {
    @Binding var progress: Double
    @Binding var complete: Bool
    var body: some View {
        ZStack {
            Image(systemName: complete ? "checkmark.circle.fill" : "arrow.down.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .foregroundStyle(.primary, .tertiary)
            if !complete {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 58, height: 58)
            }
        }
    }
}

struct OnboardingDownloadingModelProgressView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var appManager: AppManager
    @Binding var selectedModel: ModelConfiguration
    @Environment(LLMEvaluator.self) var llm
    @State var didSwitchModel = false
    @State var progress = 0.0
    @State var progressInt: Int = 0
    @State var installed = false
//    var installed: Bool {
//        llm.progress == 1 && didSwitchModel
//    }
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                DownloadIndicator(progress: $progress, complete: $installed)
                
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Text(installed ? "Installed" : "Installing (")
                        if !installed {
                            Text("\(progressInt)")
                                .contentTransition(.numericText())
                            Text("%)")
                        }
                    }
                        .font(.title)
                        .fontWeight(.semibold)
                    Text(appManager.modelDisplayName(selectedModel.name))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            if installed {
                Button(action: { showOnboarding = false }) {
                    Text("Done")
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
            } else {
                Text("Keep this screen open and wait for the installation to complete.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .modifier(CustomNavTitle(title: "Sit back and relax"))
        .toolbar(installed ? .hidden : .visible)
        .navigationBarBackButtonHidden()
        .task {
            await loadLLM()
        }
        #if os(iOS)
        .sensoryFeedback(.success, trigger: installed)
        #endif
        .onChange(of: installed) {
            addInstalledModel()
            #if os(iOS)
            if installed {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            #endif
        }
        .onChange(of: llm.progress) {
            progress = llm.progress
            withAnimation {
                progressInt = Int(progress * 100)
            }
#if os(iOS)
            if appManager.shouldPlayHaptics {
                Haptic.shared.play(.medium, intensity: max(0.3, CGFloat(progress)))
            }
#endif
            installed = llm.progress == 1 && didSwitchModel
        }
        .onChange(of: didSwitchModel) {
            installed = llm.progress == 1 && didSwitchModel
        }
        .interactiveDismissDisabled(!installed)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        #endif
        .animation(.default, value: installed)
    }
    
    func loadLLM() async {
        await llm.switchModel(selectedModel)
        didSwitchModel = true
    }
    
    func addInstalledModel() {
        if installed {
            print("added installed model")
            appManager.currentModelName = selectedModel.name
            appManager.addInstalledModel(selectedModel.name)
        }
    }
}

#Preview {
    OnboardingDownloadingModelProgressView(showOnboarding: .constant(true), selectedModel: .constant(ModelConfiguration.defaultModel))
        .environmentObject(AppManager())
        .environment(LLMEvaluator())
}
