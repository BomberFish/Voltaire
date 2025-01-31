//
//  AppearanceSettingsView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/5/24.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var appManager: AppManager

    var body: some View {
        Form {
//            #if os(iOS)
//            Section {
//                Picker(selection: $appManager.appTintColor) {
//                    ForEach(AppTintColor.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { option in
//                        HStack {
////                            Image(systemName: "swatchpalette")
////                                .resizable()
////                                .colorMultiply(option.getColor())
////                            Spacer()
//                            Text(String(describing: option).capitalized)
//                        }
//                        .tag(option)
//                    }
//                } label: {
//                    Label("Color", systemImage: "paintbrush.pointed")
//                }
//            }
//            #endif

//            Section(header: Text("Font")) {
//                Picker(selection: $appManager.appFontDesign) {
//                    ForEach(AppFontDesign.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { option in
//                        Text(String(describing: option).capitalized)
//                            .tag(option)
//                    }
//                } label: {
//                    Label("Design", systemImage: "textformat")
//                }
//
//                Picker(selection: $appManager.appFontWidth) {
//                    ForEach(AppFontWidth.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { option in
//                        Text(String(describing: option).capitalized)
//                            .tag(option)
//                            .fontDesign(appManager.appFontDesign.getFontDesign())
//                            .fontWidth(option.getFontWidth())
//                    }
//                } label: {
//                    Label("Width", systemImage: "arrow.left.and.line.vertical.and.arrow.right")
//                }
//                .disabled(appManager.appFontDesign != .standard)
//
//                #if !os(macOS)
//                Picker(selection: $appManager.appFontSize) {
//                    ForEach(AppFontSize.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { option in
//                        Text(String(describing: option).capitalized)
//                            .tag(option)
//                    }
//                } label: {
//                    Label("Size", systemImage: "arrow.up.left.and.arrow.down.right")
//                }
//                #endif
//            }
        }
        .formStyle(.grouped)
        .modifier(CustomNavTitle(title: "Appearance"))
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    AppearanceSettingsView()
}
