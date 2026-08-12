import SwiftUI

public extension View {
    func storeProvider(_ store: Store) -> some View {
        modifier(SP(store: store))
    }
}

fileprivate struct SP: ViewModifier {
    @ObservedObject var store: Store

    func body(content: Content) -> some View {
        content
            .environmentObject(store)
            .environmentObject(store.dispatcher)
            .environmentObject(store.auth)
            .environmentObject(store.collaborators)
            .environmentObject(store.collections)
            .environmentObject(store.config)
            .environmentObject(store.filters)
            .environmentObject(store.icons)
            .environmentObject(store.raindrops)
            .environmentObject(store.filters)
            .environmentObject(store.recent)
            .environmentObject(store.subscription)
            .environmentObject(store.user)
    }
}
