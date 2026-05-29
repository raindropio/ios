import SwiftUI
import UI
import API
import Features

extension Folder {
    struct Toolbar: ViewModifier {
        @EnvironmentObject private var r: RaindropsStore
        
        @Binding var find: FindBy
        @Binding var pick: RaindropsPick

        //`.all` targets the whole collection incl. unloaded items — only an explicit Select-all sets it
        private func toggleAll() {
            switch pick {
            case .all: pick = .some([])
            case .some: pick = .all(find)
            }
        }

        func body(content: Content) -> some View {
            content
                .modifier(
                    Regular(find: $find, pick: pick, total: r.state.total(find))
                )
                .modifier(
                    Editing(find: find, pick: pick, toggleAll: toggleAll)
                )
                .raindropCommands(pick)
        }
    }
}

