//
//  ChatsSettingsView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/6/24.
//

import SwiftUI

struct ChatsSettingsView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(\.modelContext) var modelContext
    @State var systemPrompt = ""
    @State var deleteAllChats = false
    @Binding var currentThread: Thread?
    
    var body: some View {
        Form {
            Section(header: Text("System prompt")) {
                TextEditor(text: $appManager.systemPrompt)
                    .textEditorStyle(.plain)
                    .lineLimit(7, reservesSpace: true)
            }
            
            if appManager.userInterfaceIdiom == .phone {
                Section {
                    Toggle("Haptics", isOn: $appManager.shouldPlayHaptics)
                        .tint(.green)
                }
            }
            
            Section {
                Button {
                    deleteAllChats.toggle()
                } label: {
                    Label("Delete all chats", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .alert("Are you sure?", isPresented: $deleteAllChats) {
                    Button("Cancel", role: .cancel) {
                        deleteAllChats = false
                    }
                    Button("Delete", role: .destructive) {
                        deleteChats()
                    }
                }
                .buttonStyle(.borderless)
            }
        }
        .formStyle(.grouped)
        .modifier(CustomNavTitle(title: "Chats"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    func deleteChats() {
        do {
            currentThread = nil
            try modelContext.delete(model: Thread.self)
            try modelContext.delete(model: Message.self)
        } catch {
            print("Failed to delete.")
        }
    }
}

#Preview {
    ChatsSettingsView(currentThread: .constant(nil))
}
