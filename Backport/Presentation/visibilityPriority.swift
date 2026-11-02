import SwiftUI

public extension Backported where Wrapped: ToolbarContent {
    func visibilityPriority(_ priority: Backport.ToolbarItemVisibilityPriority) -> some ToolbarContent {
        VisibilityPriority(content: content, priority: priority)
    }
}

private struct VisibilityPriority<Content: ToolbarContent>: ToolbarContent {
    let content: Content
    let priority: Backport.ToolbarItemVisibilityPriority

    var body: some ToolbarContent {
        #if os(visionOS)
        content
        #else
        if #available(iOS 27, macOS 26.1, *) {
            content.visibilityPriority(priority.native)
        } else {
            content
        }
        #endif
    }
}

public extension Backport {
    enum ToolbarItemVisibilityPriority {
        case automatic, low, high

        #if !os(visionOS)
        @available(iOS 27, macOS 26.1, *)
        fileprivate var native: SwiftUI.ToolbarItemVisibilityPriority {
            switch self {
            case .automatic: .automatic
            case .low: .low
            case .high: .high
            }
        }
        #endif
    }
}