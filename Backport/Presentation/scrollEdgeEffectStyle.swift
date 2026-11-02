import SwiftUI

public extension Backported where Wrapped: View {
    @ViewBuilder func scrollEdgeEffectStyle(_ style: Backport.ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View {
        #if os(visionOS)
        content
        #else
        if #available(iOS 26, macOS 26, *) {
            content.scrollEdgeEffectStyle(style?.native, for: edges)
        } else {
            content
        }
        #endif
    }
}

public extension Backport {
    enum ScrollEdgeEffectStyle {
        case automatic, hard, soft

        #if !os(visionOS)
        @available(iOS 26, macOS 26, *)
        fileprivate var native: SwiftUI.ScrollEdgeEffectStyle {
            switch self {
            case .automatic: .automatic
            case .hard: .hard
            case .soft: .soft
            }
        }
        #endif
    }
}