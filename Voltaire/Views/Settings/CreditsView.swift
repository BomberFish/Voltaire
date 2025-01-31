//
//  CreditsView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/6/24.
//

import SwiftUI

struct CreditsView: View {
    var body: some View {
        Form {
            Section {
                Link("fullmoon", destination: URL(string: "https://github.com/mainframecomputer/fullmoon-ios")!)
                    .badge(Text(Image(systemName: "arrow.up.right")))
                Link("MLX Swift", destination: URL(string: "https://github.com/ml-explore/mlx-swift")!)
                    .badge(Text(Image(systemName: "arrow.up.right")))
            }
        }
        .formStyle(.grouped)
        .modifier(CustomNavTitle(title: "Credits"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    CreditsView()
}
