import SwiftUI

public extension Backported where Wrapped: ToolbarContent {
    func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some ToolbarContent {
        MatchedTransitionSource(content: content, id: id, namespace: namespace)
    }
}

private struct MatchedTransitionSource<Content: ToolbarContent, ID: Hashable>: ToolbarContent {
    let content: Content
    let id: ID
    let namespace: Namespace.ID

    var body: some ToolbarContent {
        if #available(iOS 26, macOS 26, *) {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}