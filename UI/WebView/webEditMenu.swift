import SwiftUI
import WebKit

#if canImport(UIKit)
public extension View {
    func webEditMenu(@ObservedObject _ page: WebPage, items: @escaping () -> [UIMenuElement]) -> some View {
        modifier(EditMenu(page: page, items: items))
    }
}

fileprivate struct EditMenu: ViewModifier {
    @ObservedObject var page: WebPage
    var items: () -> [UIMenuElement]

    func attach() {
        (page.view as? NativeWebView)?.editMenu = items
    }

    func body(content: Content) -> some View {
        content
            .onAppear(perform: attach)
            .task(id: page.view) { attach() }
    }
}
#endif
