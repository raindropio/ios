import SwiftUI

public extension Backported where Wrapped: ToolbarContent {
    func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent {
        SharedBackgroundVisibility(content: content, visibility: visibility)
    }
}

private struct SharedBackgroundVisibility<Content: ToolbarContent>: ToolbarContent {
    let content: Content
    let visibility: Visibility

    var body: some ToolbarContent {
        if #available(iOS 26, macOS 26, *) {
            content.sharedBackgroundVisibility(visibility)
        } else {
            content
        }
    }
}