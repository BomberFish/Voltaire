//
//  ChatsListView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/5/24.
//

import StoreKit
import SwiftData
import SwiftUI

struct ChatsListView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(\.dismiss) var dismiss
    @Binding var showChats: Bool
    @Binding var currentThread: Thread?
    @FocusState.Binding var isPromptFocused: Bool
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Thread.timestamp, order: .reverse) var threads: [Thread]
    @State var search = ""
    @State var selection: Thread?
    
    @State var llm = LLMEvaluator()
    
    @Environment(\.requestReview) private var requestReview
    
    @ViewBuilder var newItem: some View {
        Button(action: {
            selection = nil
            // create new thread
            setCurrentThread(nil)
            
            // ask for review if appropriate
            //                            requestReviewIfAppropriate()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.primary, .tertiary)
                    .font(.title3)
                Text("New Chat")
                    .font(.headline)
                Spacer()
            }
        }
        .tint(Color(UIColor.label))
//        .padding(.vertical, 12)
        .padding(.horizontal, 12)
//        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 52)
        .background(selection == nil ? Color(UIColor.secondarySystemFill) : Color(UIColor.systemBackground))
        .cornerRadius(14)
    }
    
    @ViewBuilder var chats: some View {
        Group {
            if appManager.userInterfaceIdiom == .phone {
                newItem
            }
            
            ForEach(filteredThreads, id: \.id) { thread in
                VStack(alignment: .leading) {
                    //                    ZStack {
                    //                        if let firstMessage = thread.sortedMessages.first {
                    //                            Text(firstMessage.content)
                    //                                .lineLimit(1)
                    //                        } else {
                    //                            Text("Untitled")
                    //                        }
                    //                    }
                    
                    Text(thread.title ?? "Untitled Chat")
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text("\(thread.timestamp.formatted())")
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                }
#if os(macOS)
                .swipeActions {
                    Button("Delete") {
                        deleteThread(thread)
                    }
                    .tint(.red)
                }
                .contextMenu {
                    Button {
                        deleteThread(thread)
                    } label: {
                        Text("Delete")
                    }
                }
#else
                .if(appManager.userInterfaceIdiom == .phone) { view in
                    ZStack(alignment: .leading) {
                        if selection != thread {
                            Rectangle()
                                .fill(Color(UIColor.systemBackground))
                                .frame(height: 52)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack {
                            view
                                Spacer()
                        }
                    }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                    //                        .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .frame(height: 52)
                    .background(selection == thread ? Color(UIColor.secondarySystemFill) : Color(UIColor.systemBackground))
                    .cornerRadius(14)
                    .contextMenu {
                        Button("Rename", systemImage: "pencil") {
                            UIApplication.shared.alertWithTextField(title: "Rename Chat", body: "", placeholder: (thread.title ?? ""), onOK: {new in
                                if !new.isEmpty {
                                    thread.title = new
                                }
                            })
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            deleteThread(thread)
                        }
                    } preview: {
                        ChatView(currentThread: .constant(thread), isPromptFocused: $isPromptFocused, showChats: .constant(false), showSettings: .constant(false), isPreview: true)
                            .environment(llm)
                            .environmentObject(appManager)
                    }
                    .onTapGesture {
                        showChats = false
                        withAnimation(.easeInOut(duration: 0.1)) {
                            selection = thread
                        }
                    }
                }
#endif
                .tag(thread)
            }
            .onDelete(perform: deleteThreads)
        }
    }
    
    @ViewBuilder var list: some View {
#if os(iOS)
        Group {
            if appManager.userInterfaceIdiom == .phone {
                ScrollView {
                    chats
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                }
            } else {
                List(selection: $selection) {
                    chats
                }
            }
        }
#else
        List(selection: $selection) {
#if os(macOS)
            Section {} // adds some space below the search bar on mac
#endif
            Section {
                chats
            }
        }
#endif
    }
    
    
    
    var body: some View {
        Group {
            ZStack {
                list
                    .onChange(of: selection) {
                        setCurrentThread(selection)
                    }
#if os(iOS)
                    .if(appManager.userInterfaceIdiom == .phone) { view in
                        view
                            .listRowBackground(Color.clear)
                            .listStyle(.grouped)
                            .environment(\.defaultMinListHeaderHeight, 0)
                            .offset(y: -8)
                    }
#elseif os(macOS) || os(visionOS)
                    .listStyle(.sidebar)
#endif
                if filteredThreads.count == 0 {
                    ContentUnavailableView {
                        Label(threads.count == 0 ? "No Chats" : "No results", systemImage: "message")
                    }
                }
            }
#if os(iOS)
            .if(appManager.userInterfaceIdiom != .phone) {view in
                view
                    .modifier(CustomNavTitle(title: "Chats"))
                    .searchable(text: $search)
            }
#elseif os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search)
#elseif os(macOS)
            .searchable(text: $search, placement: .sidebar)
#endif
#if os(macOS)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        selection = nil
                        // create new thread
                        setCurrentThread(nil)
                        
                        // ask for review if appropriate
                        //                            requestReviewIfAppropriate()
                    }) {
                        Label("new", systemImage: "plus")
                    }
                    .keyboardShortcut("N", modifiers: [.command])
                }
            }
#elseif os(visionOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        selection = nil
                        // create new thread
                        setCurrentThread(nil)
                        
                        // ask for review if appropriate
                        //                                requestReviewIfAppropriate()
                    }) {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("N", modifiers: [.command])
                    .buttonStyle(.bordered)
                }
            }
#else
#endif
        }
#if !os(visionOS)
        .tint(appManager.appTintColor.getColor())
        
#endif
        .if(appManager.userInterfaceIdiom != .phone) { view in
            NavigationStack {
                view
            }
        }
        .if(appManager.userInterfaceIdiom == .phone) { view in
            view
                .safeAreaInset(edge: .top, spacing: 12) {
                    ZStack {
                        VariableBlurView(maxBlurRadius: 3, direction: .blurredTopClearBottom, startOffset: -0.1)
                            .frame(height: 78, alignment: .top)
                            .ignoresSafeArea(.all)
                        SearchBar(text: $search)
                            .padding(.horizontal, 4)
                    }
                    .frame(height: 26)
                }
                .onChange(of: currentThread) {
                    selection = currentThread
                }
                .overlay(alignment: .trailing) {
                    Divider()
                        .frame(maxWidth: 1, maxHeight: .infinity)
                        .background(Color(UIColor.separator))
                        .ignoresSafeArea(edges: [])
                }
        }
    }
    
    var filteredThreads: [Thread] {
        threads.filter { thread in
            search.isEmpty || thread.messages.contains { message in
                message.content.localizedCaseInsensitiveContains(search)
            }
        }
    }
    
    func requestReviewIfAppropriate() {
        //        if appManager.numberOfVisits - appManager.numberOfVisitsOfLastRequest >= 5 {
        //            requestReview() // can only be prompted if the user hasn't given a review in the last year, so it will prompt again when apple deems appropriate
        //            appManager.numberOfVisitsOfLastRequest = appManager.numberOfVisits
        //        }
    }
    
    private func deleteThreads(at offsets: IndexSet) {
        for offset in offsets {
            let thread = threads[offset]
            
            if let currentThread = currentThread {
                if currentThread.id == thread.id {
                    setCurrentThread(nil)
                }
            }
            
            // Adding a delay fixes a crash on iOS following a deletion
            let delay = appManager.userInterfaceIdiom == .phone ? 1.0 : 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                modelContext.delete(thread)
            }
        }
    }
    
    private func deleteThread(_ thread: Thread) {
        if let currentThread = currentThread {
            if currentThread.id == thread.id {
                setCurrentThread(nil)
            }
        }
        modelContext.delete(thread)
    }
    
    private func setCurrentThread(_ thread: Thread? = nil) {
        currentThread = thread
        showChats = false
        isPromptFocused = true
#if os(iOS)
        dismiss()
        if appManager.shouldPlayHaptics {
            Haptic.shared.play(.light)
        }
#endif
    }
}

#if canImport(UIKit)
struct SearchBar: UIViewRepresentable {
    
    @Binding var text: String
    var placeholder: String = "Search"
    
    class Coordinator: NSObject, UISearchBarDelegate {
        
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }
    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.autocapitalizationType = .none
        searchBar.placeholder = placeholder
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor.clear.cgColor
        searchBar.backgroundColor = UIColor.clear
        searchBar.searchBarStyle = .minimal
        searchBar.isTranslucent = false
        
        searchBar.searchTextField.backgroundColor = UIColor.systemBackground
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}
#endif

#Preview {
    @FocusState var isPromptFocused: Bool
    ChatsListView(showChats: .constant(false), currentThread: .constant(nil), isPromptFocused: $isPromptFocused)
}
