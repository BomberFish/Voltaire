//
//  ConversationView.swift
//  fullmoon
//
//  Created by Xavier on 16/12/2024.
//

//import MDLatex
//import MarkdownUI
import SwiftUI

extension TimeInterval {
    var formatted: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

struct MessageView: View {
    @Environment(LLMEvaluator.self) var llm
    @EnvironmentObject var appManager: AppManager
    @State private var collapsed = true
    @Binding var message: Message

    var isThinking: Bool {
        !message.content.contains("</think>")
    }
    
    var labelColor: Color = {
#if canImport(UIKit)
        .init(UIColor.label)
#elseif canImport(AppKit)
        .init(NSColor.labelColor)
#else
        .black
#endif
    }()
    
    var bgColor: Color = {
#if os(iOS)
        .init(UIColor.systemBackground)
#elseif os(macOS)
        .init(NSColor.textBackgroundColor)
#else
        .clear // visionOS, etc
#endif
    }()

    func processThinkingContent(_ content: String) -> (String?, String?) {
        guard let startRange = content.range(of: "<think>") else {
            // No <think> tag, return entire content as the second part
            return (nil, content.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        guard let endRange = content.range(of: "</think>") else {
            // No </think> tag, return content after <think> without the tag
            let thinking = String(content[startRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return (thinking, nil)
        }

        let thinking = String(content[startRange.upperBound ..< endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let afterThink = String(content[endRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

        return (thinking, afterThink.isEmpty ? nil : afterThink)
    }

    var time: String {
        if llm.running, let elapsedTime = llm.elapsedTime {
            if isThinking {
                return elapsedTime.formatted
            }
            if let thinkingTime = llm.thinkingTime {
                return thinkingTime.formatted
            }
        }

        if let generatingTime = message.generatingTime {
            return generatingTime.formatted
        }

        return "0s"
    }

    var thinkingLabel: some View {
        HStack {
            Button {
                collapsed.toggle()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .fontWeight(.medium)
                    .rotationEffect(.degrees(collapsed ? 0 : 90))
            }
            
            if isThinking {
                ProgressView()
                    .padding(.trailing, 8)
            }
            
            Text(isThinking ? "Thinking... (\(time))" : "Thought for \(time)")
                .italic()
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
    }

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            if message.role == .assistant {
                let (thinking, afterThink) = processThinkingContent(message.content)
                VStack(alignment: .leading, spacing: 16) {
                    if let thinking {
                        VStack(alignment: .leading, spacing: 12) {
                            thinkingLabel
                            if !collapsed {
                                if !thinking.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    HStack(spacing: 12) {
                                        Capsule()
                                            .frame(width: 2)
                                            .padding(.vertical, 1)
                                            .foregroundStyle(.fill)
                                        //                                            MDLatex.render(
                                        //                                                markdown: thinking,
                                        //                                                theme: ThemeConfiguration(
                                        //                                                    backgroundColor: bgColor,
                                        //                                                    fontColor: labelColor,
                                        //                                                    fontSize: 16,
                                        //                                                    fontFamily: "apple-system",
                                        //                                                    userInteractionEnabled: true
                                        //                                                ),
                                        //                                                animation: AnimationConfiguration(isEnabled: true, chunkRenderingDuration: 0.4),
                                        //                                                width: geo.size.width - 24
                                        //                                            )
//                                        Markdown(thinking)
//                                            .textSelection(.enabled)
//                                            .markdownTextStyle {
//                                                ForegroundColor(.secondary)
//                                            }
//                                            .markdownTextStyle(\.code) {
//                                                FontFamilyVariant(.monospaced)
//                                                FontSize(.em(0.85))
//                                            }
                                        MarkdownView(thinking)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.leading, 5)
                                }
                            }
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            collapsed.toggle()
                            if isThinking {
                                llm.collapsed = collapsed
                            }
                        }
                    }
                    
                    if let afterThink {
                        //                            MDLatex.render(
                        //                                markdown: afterThink,
                        //                                theme: ThemeConfiguration(
                        //                                    backgroundColor: bgColor,
                        //                                    fontColor: labelColor,
                        //                                    fontSize: 16,
                        //                                    fontFamily: "apple-system",
                        //                                    userInteractionEnabled: true
                        //                                ),
                        //                                animation: AnimationConfiguration(isEnabled: true, chunkRenderingDuration: 0.4),
                        //                                width: geo.size.width - 24
                        //                            )
//                        Markdown(afterThink)
//                            .markdownTextStyle(\.code) {
//                                FontFamilyVariant(.monospaced)
//                                FontSize(.em(0.85))
//                                BackgroundColor(Color(.secondarySystemBackground))
//                            }
//                            .textSelection(.enabled)
                        MarkdownView(afterThink)
                    }
                }
                .padding(.trailing, 24)
            } else {
                MarkdownView($message.content)
//                Markdown(message.content)
//                    .markdownTextStyle(\.code) {
//                        FontFamilyVariant(.monospaced)
//                        FontSize(.em(0.85))
//                        BackgroundColor(Color(.secondarySystemBackground))
//                    }
//                    .textSelection(.enabled)
                //                    MDLatex.render(
                //                        markdown: message.content,
                //                        theme: ThemeConfiguration(
                //                            backgroundColor: bgColor,
                //                            fontColor: labelColor,
                //                            fontSize: 16,
                //                            fontFamily: "apple-system",
                //                            userInteractionEnabled: true
                //                        ),
                //                        animation: AnimationConfiguration(isEnabled: true, chunkRenderingDuration: 0.4),
                //                        width: geo.size.width - 24
                //                    )
#if os(iOS) || os(visionOS)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
#else
                    .padding(.horizontal, 16 * 2 / 3)
                    .padding(.vertical, 8)
#endif
                    .background(appManager.appTintColor.getColor().opacity(0.3))
#if os(iOS) || os(visionOS)
                    .mask(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 24, bottomLeading: 24, bottomTrailing: 12, topTrailing: 24)))
#elseif os(macOS)
                    .mask(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, bottomLeading: 16, bottomTrailing: 8, topTrailing: 16)))
#endif
                    .padding(.leading, 52)
            }
            
            if message.role == .assistant { Spacer() }
        }
        
        .onAppear {
            if llm.running {
                collapsed = false
            }
        }
        .onChange(of: llm.elapsedTime) {
            if isThinking {
                llm.thinkingTime = llm.elapsedTime
            }
        }
        .onChange(of: isThinking) {
            if llm.running {
                llm.isThinking = isThinking
            }
        }
        .animation(.smooth(duration: 0.2), value: collapsed)
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
}

struct ConversationView: View {
    @Environment(LLMEvaluator.self) var llm
    @EnvironmentObject var appManager: AppManager
    let thread: Thread
    let generatingThreadID: UUID?

    @State private var scrollID: String?
    @State private var scrollInterrupted = false
    
    @State private var currentMessage: Message = .init(role: .assistant, content: "")

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(thread.sortedMessages) { message in
                        MessageView(message: .constant(message))
                            .padding()
                            .id(message.id.uuidString)
                    }

                    if llm.running && !llm.output.isEmpty && thread.id == generatingThreadID {
                        VStack {
                            MessageView(message: $currentMessage)
                        }
                        .padding()
                        .id("output")
                        .onAppear {
                            print("output appeared")
                            scrollInterrupted = false // reset interruption when a new output begins
                        }
                    }

                    Rectangle()
                        .fill(.clear)
                        .frame(height: 1)
                        .id("bottom")
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: llm.output) { _, _ in
                currentMessage.content = llm.output + "█"
                // auto scroll to bottom
                if !scrollInterrupted {
                    scrollView.scrollTo("bottom")
                }

                #if os(iOS)
                if !llm.isThinking && appManager.shouldPlayHaptics {
                    Haptic.shared.play(.light)
                }
                #endif
            }
            .onChange(of: scrollID) { _, _ in
                // interrupt auto scroll to bottom if user scrolls away
                if llm.running {
                    scrollInterrupted = true
                }
            }
        }
        .defaultScrollAnchor(.bottom)
        #if os(iOS)
            .scrollDismissesKeyboard(.interactively)
        #endif
    }
}

#Preview {
    ConversationView(thread: Thread(), generatingThreadID: nil)
        .environment(LLMEvaluator())
        .environmentObject(AppManager())
}
