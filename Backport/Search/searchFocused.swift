import SwiftUI

public extension Backported where Wrapped: View {
    @ViewBuilder func searchFocused(_ focus: FocusState<Bool>.Binding) -> some View {
        if #available(iOS 18, macOS 15, *) {
            content.searchFocused(focus)
        } else {
            content
        }
    }
}
