// bomberfish
// SidebarView.swift – Voltaire
// created on 2025-01-27

import SwiftUI

fileprivate enum Direction {
    case left
    case right
}

#if canImport(UIKit)
struct SidebarView<SidebarContent: View, Content: View>: View {
    @Binding var show: Bool
    let sidebarView: SidebarContent
    let detailView: Content
    @State private var offset: CGFloat = 0
    @State private var dragging = false
    @State private var startOffset: CGFloat = 0
    
    init(show: Binding<Bool>, @ViewBuilder sidebar: ()->SidebarContent, @ViewBuilder content: ()->Content) {
        self._show = show
        sidebarView = sidebar()
        detailView = content()
    }
    
    func dw(_ w: CGFloat) -> CGFloat {
        max(min(w / 1.25, offset * (w / 1.25)), 0)
    }
    
    func sw(_ w: CGFloat) -> CGFloat {
        min((-1 * (w / 1.25) * (1 - offset)), 0)
    }
    
    var body: some View {
        GeometryReader {geo in
            ZStack(alignment: .leading) {
                sidebarView
                    .frame(width: geo.size.width / 1.25)
                    .offset(x: sw(geo.size.width))
                detailView
                    .frame(width: geo.size.width)
                    .offset(x: dw(geo.size.width))
            }
            .onChange(of: show) {
                print("show: \(show)")
                // if offset == 0 || offset == 1 {
#if os(iOS)
//                if appManager.shouldPlayHaptics {
                    Haptic.shared.play(.rigid)
//                }
#endif
                withAnimation(.smooth(duration: 0.25)) {
                    offset = show ? 1 : 0
                }
                // }
            }
//            .onChange(of: offset) {
//                show = (offset > 0.25)
//            }
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let translationX = value.translation.width
                        // Only begin dragging if we've passed the threshold
                        if !dragging && abs(translationX) > 15 {
                            dragging = true
                            startOffset = offset
                        }
                        // Update offset only if dragging has begun
                        if dragging {
                            let newOffset = startOffset + (translationX / (geo.size.width / 2.5))
                            offset = max(0, min(1, newOffset))
                            print(offset, startOffset, value.translation.width)
                        }
                    }
                    .onEnded { value in
                        dragging = false
                        withAnimation(.smooth(duration: 0.1)) {
                            offset = offset > 0.25 ? 1 : 0
                        }
                        show = offset > 0.25
                    }
            )
            // .gesture (
            //     DragGesture()
            //         .onChanged { value in
            //             dragging = true
            //             if (value.translation.width < 0 && offset == 0) || (value.translation.width > 0 && offset == 1) {
            //                 return
            //             }
            //             offset = value.translation.width / (geo.size.width / 2.5)
            //             print(offset, value.translation.width)
            //         }
            //         .onEnded { value in
            //             dragging = false
            //             withAnimation {
            //                 if offset > 0.5 {
            //                     offset = 1
            //                 } else {
            //                     offset = 0
            //                 }
            //             }
            //         }
            // )
        }
    }
}
#endif

//#Preview {
//    SidebarView()
//}
