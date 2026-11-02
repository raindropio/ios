import SwiftUI

public extension Backported where Wrapped: View {
    @ViewBuilder func toolbarMinimizationBehavior(_ behavior: Backport.ToolbarMinimizationBehavior, for bar: ToolbarPlacement) -> some View {
        #if os(iOS)
        if #available(iOS 27, *) {
            content.toolbarMinimizationBehavior(behavior.native, for: bar)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

public extension Backport {
    enum ToolbarMinimizationBehavior {
        case automatic, onScrollDown, onScrollUp, never

        #if os(iOS)
        @available(iOS 27, *)
        fileprivate var native: SwiftUI.ToolbarMinimizationBehavior {
            switch self {
            case .automatic: .automatic
            case .onScrollDown: .onScrollDown
            case .onScrollUp: .onScrollUp
            case .never: .never
            }
        }
        #endif
    }
}