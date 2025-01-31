//
//  ChatView.swift
//  fullmoon
//
//  Created by Jordan Singer on 12/3/24.
//

import SwiftUI
import MLXLMCommon

struct ChatView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(\.modelContext) var modelContext
    @Binding var currentThread: Thread?
    @Environment(LLMEvaluator.self) var llm
    @Namespace var bottomID
    @State var showModelPicker = false
    @State var prompt = ""
    @FocusState.Binding var isPromptFocused: Bool
    @Binding var showChats: Bool
    @Binding var showSettings: Bool
    
    @State var thinkingTime: TimeInterval?
    
    @State private var generatingThreadID: UUID?
    
    public var isPreview = false
    
    var isPromptEmpty: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    let platformBackgroundColor: Color = {
#if os(iOS)
        return Color(UIColor.secondarySystemBackground)
#elseif os(visionOS)
        return Color(UIColor.separator)
#elseif os(macOS)
        return Color(NSColor.secondarySystemFill)
#endif
    }()
    
    let platformLabelColor: Color = {
#if os(iOS) || os(visionOS)
        return Color(UIColor.label)
#elseif os(macOS)
        return Color(NSColor.labelColor)
#endif
    }()
    
    var chatTextField: some View {
        TextField((currentThread?.sortedMessages.count ?? 0) == 0 ? "Ask anything" : "Send a message", text: $prompt, axis: .vertical)
            .focused($isPromptFocused)
            .textFieldStyle(.plain)
#if os(iOS) || os(visionOS)
            .padding(.horizontal, 16)
            .lineLimit(3)
#elseif os(macOS)
            .padding(.horizontal, 12)
            .onSubmit {
                handleShiftReturn()
            }
            .submitLabel(.send)
#endif
            .padding(.vertical, 8)
#if os(iOS) || os(visionOS)
            .frame(minHeight: 48)
#else
            .frame(minHeight: 32)
#endif
#if os(iOS)
            .onSubmit {
                isPromptFocused = true
                generate()
            }
#endif
    }
    
    var chatInput: some View {
        HStack(alignment: .bottom, spacing: 0) {
            
            if #available(iOS 18.0, *) {
                chatTextField
                    .writingToolsBehavior(.disabled)
            } else {
                chatTextField
            }
            
            generateButton
        }
#if os(macOS)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(platformBackgroundColor)
        )
#elseif os(iOS)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
#else
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(platformBackgroundColor)
        )
#endif
    }
    
    var modelPickerButton: some View {
        Button {
#if os(iOS)
            if appManager.shouldPlayHaptics {
                Haptic.shared.play(.heavy)
            }
#endif
            showModelPicker.toggle()
        } label: {
            Group {
                Image(systemName: "brain")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
#if os(iOS) || os(visionOS)
                    .frame(width: 16)
#elseif os(macOS)
                    .frame(width: 12)
#endif
                    .tint(.primary)
            }
#if os(iOS) || os(visionOS)
            .frame(width: 48, height: 48)
#elseif os(macOS)
            .frame(width: 32, height: 32)
#endif
            .background(
                Circle()
                    .fill(platformBackgroundColor)
            )
        }
#if os(macOS) || os(visionOS)
        .buttonStyle(.plain)
#endif
    }
    
    var modelPickerMenu: some View {
        Menu(content: {
                
                if appManager.userInterfaceIdiom == .phone {
                    Section(chatTitle) {
                        Button("Rename", systemImage: "pencil") {
                            UIApplication.shared.alertWithTextField(title: "Rename Chat", body: "", placeholder: (currentThread?.title ?? ""), onOK: {new in
                                if !new.isEmpty {
                                    currentThread?.title = new
                                }
                            })
                        }
                    }
                }
                
                Section(appManager.userInterfaceIdiom == .phone ? "Models" : "Installed") {
                    ForEach(appManager.installedModels, id: \.self) { modelName in
                        Button {
                            Task {
                                if let model = ModelConfiguration.availableModels.first(where: {
                                    $0.name == modelName
                                }) {
                                    appManager.currentModelName = modelName
#if os(iOS)
                                    if appManager.shouldPlayHaptics {
                                        Haptic.shared.play(.medium)
                                    }
#endif
                                    await llm.switchModel(model)
                                }
                            }
                        } label: {
                            Label {
                                Text(appManager.modelDisplayName(modelName))
                                    .fontDesign(.serif)
                            } icon: {
                                Image(systemName: appManager.currentModelName == modelName ? "checkmark.circle.fill" : "circle")
                            }
                        }
                    }
                    
                    Button {
                        showModelPicker.toggle()
                    } label: {
                        Label("Download more models...", systemImage: "arrow.down.circle.dotted")
                    }
                }
#if os(macOS)
            .buttonStyle(.borderless)
#endif
        }, label: {
            if appManager.userInterfaceIdiom == .phone {
                HStack {
                    Text(ModelConfiguration.getModelByName(appManager.currentModelName ?? "")?.familyName ?? chatTitle)
                        .font(.system(.headline, design: .serif))
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.callout.weight(.medium))
                }
            } else {
                Image(systemName: "brain")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        })
        .tint(platformLabelColor)
        .onTapGesture {
            #if os(iOS)
            if appManager.shouldPlayHaptics {
                Haptic.shared.play(.light)
            }
            #endif
        }
    }
    
    var generateButton: some View {
        Button {
            if llm.running {
                llm.stop()
            } else {
                generate()
            }
        } label: {
            Image(systemName: llm.running ? "stop.circle.fill" : "arrow.up.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
#if os(iOS) || os(visionOS)
                .frame(width: 24, height: 24)
#else
                .frame(width: 16, height: 16)
#endif
        }
        .disabled((isPromptEmpty && !llm.running) || (llm.running && llm.cancelled))
        .animation(.default, value: llm.running)
        .animation(.default, value: isPromptEmpty)
#if os(iOS) || os(visionOS)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
#else
        .padding(.trailing, 8)
        .padding(.bottom, 8)
#endif
#if os(macOS) || os(visionOS)
        .buttonStyle(.plain)
#endif
    }
    
    var chatTitle: String {
        if let currentThread = currentThread,
        let title =  currentThread.title{
           return title
//            if let firstMessage = currentThread.sortedMessages.first {
//                return firstMessage.content
//            }
        }
        
         return "New Chat"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let currentThread = currentThread {
                    ConversationView(thread: currentThread, generatingThreadID: generatingThreadID)
                } else {
                    Spacer()
                    Image("brain.gear")
                        .font(.system(size: 44))
                        .foregroundStyle(.quaternary)
                    Spacer()
                }
                
#if !os(iOS)
                HStack(alignment: .bottom) {
#if os(macOS)
                    modelPickerButton
#endif
                    chatInput
                }
                .padding()
#endif
            }
#if os(iOS)
            .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
                if !isPreview {
                    ZStack(alignment: .bottom) {
                        VariableBlurView(maxBlurRadius: 4, direction: .blurredBottomClearTop, startOffset: 0.1)
                            .frame(maxWidth: .infinity)
                            .frame(height: 116)
                            .offset(y: 26)
                            .ignoresSafeArea(.all)
                        chatInput
                            .padding()
                            .padding(.bottom, 10)
                            .ignoresSafeArea(edges: [])
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                    .ignoresSafeArea(.all)
                }
            }
#endif
            .if(!isPreview && appManager.userInterfaceIdiom != .phone) {v in
                v
                    .modifier(CustomNavTitle(title: chatTitle))
            }
#if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
#if os(iOS)
            .sheet(isPresented: $showModelPicker) {
                NavigationStack {
                    OnboardingInstallModelView(showOnboarding: $showModelPicker)
                        .environment(llm)
                        .toolbar {
#if os(iOS) || os(visionOS)
                            ToolbarItem(placement: .topBarLeading) {
                                Button(action: { showModelPicker = false }) {
                                    Image(systemName: "xmark")
                                }
                            }
#elseif os(macOS)
                            ToolbarItem(placement: .destructiveAction) {
                                Button(action: { showOnboardingInstallModelView = false }) {
                                    Text("close")
                                }
                            }
#endif
                        }
                }
            }
#else
            .sheet(isPresented: $showModelPicker) {
                NavigationStack {
                    ModelsSettingsView()
                        .environment(llm)
#if os(visionOS)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button(action: { showModelPicker.toggle() }) {
                                    Image(systemName: "xmark")
                                }
                            }
                        }
#endif
                }
#if os(iOS)
                .presentationDragIndicator(.visible)
                .if(appManager.userInterfaceIdiom == .phone) { view in
                    view.presentationDetents([.fraction(0.4)])
                }
#elseif os(macOS)
                .toolbar {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(action: { showModelPicker.toggle() }) {
                            Text("close")
                        }
                    }
                }
#endif
            }
#endif
            .toolbar {
                if !isPreview {
#if os(iOS) || os(visionOS)
                    if appManager.userInterfaceIdiom == .phone {
                        ToolbarItem(placement: .principal) {
                            modelPickerMenu
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {
//                                appManager.playHaptic()
                                showChats.toggle()
                            }) {
                                if appManager.userInterfaceIdiom == .phone {
                                    if #available(iOS 18.0, *) {
                                        Image(systemName: showChats ? "xmark" : "list.bullet")
                                            .contentTransition(.symbolEffect(.replace))
                                    } else {
                                        Image(systemName: showChats ? "xmark" : "list.bullet")
                                            .contentTransition(.symbolEffect)
                                    }
                                } else {
                                    Image(systemName: "list.bullet")
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
#if os(iOS)
                                if appManager.shouldPlayHaptics {
                                    Haptic.shared.play(.light)
                                }
#endif
                                showSettings.toggle()
                            }) {
                                Image(systemName: "gear")
                            }
                        }
                    } else {
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack {
                                modelPickerMenu
                                Button(action: {
#if os(iOS)
                                    if appManager.shouldPlayHaptics {
                                        Haptic.shared.play(.light)
                                    }
#endif
                                    appManager.playHaptic()
                                    showSettings.toggle()
                                }) {
                                    Image(systemName: "gear")
                                }
                            }
                        }
                    }
#elseif os(macOS)
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            appManager.playHaptic()
                            showSettings.toggle()
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
#endif
                }
            }
        }
        .fontDesign(.serif)
    }
    
    private func generate() {
        if !isPromptEmpty {
            if currentThread == nil {
                let newThread = Thread()
                currentThread = newThread
                modelContext.insert(newThread)
                try? modelContext.save()
            }
            
            if let currentThread = currentThread {
                generatingThreadID = currentThread.id
                
                if currentThread.title == nil {
                    currentThread.title = prompt.components(separatedBy: "\n").first
                }
                
                Task {
                    let message = prompt
                    prompt = ""
                    appManager.playHaptic()
                    sendMessage(Message(role: .user, content: message, thread: currentThread))
                    isPromptFocused = true
                    if let modelName = appManager.currentModelName {
                        var sys = appManager.systemPrompt
                        
//                        if ModelConfiguration.getModelByName(modelName)?.modelType == .reasoning {
//                            sys += " You are also an advanced AI model, capable of reasoning and understanding complex concepts. However, your current environment has limited compute resources. Use your reasoning ability sparingly, and when you do, make sure to keep the language within your internal dialog concise and don't overthink, as to not exceed your token limit."
//                        }
                        
                        print(sys)
                        
                        let output = await llm.generate(modelName: modelName, thread: currentThread, systemPrompt: sys)
                        sendMessage(Message(role: .assistant, content: output, thread: currentThread, generatingTime: llm.thinkingTime))
                        generatingThreadID = nil
                    }
                }
            }
        }
    }
    
    private func sendMessage(_ message: Message) {
        
#if os(iOS)
        if appManager.shouldPlayHaptics {
            Haptic.shared.play(.heavy)
        }
#endif
        modelContext.insert(message)
        try? modelContext.save()
    }
    
#if os(macOS)
    private func handleShiftReturn() {
        if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
            prompt.append("\n")
            isPromptFocused = true
        } else {
            generate()
        }
    }
#endif
}

#Preview {
    @FocusState var isPromptFocused: Bool
    ChatView(currentThread: .constant(nil), isPromptFocused: $isPromptFocused, showChats: .constant(false), showSettings: .constant(false))
}
