import SwiftUI
import API
import UI
import Features

extension SidebarScreen {
    struct Toolbar: ViewModifier {
        @Environment(\.containerHorizontalSizeClass) private var sizeClass
        @Environment(\.openDeepLink) private var openDeepLink
        @EnvironmentObject private var cfg: ConfigStore

        private var addPlacement: ToolbarItemPlacement {
            if #available(iOS 26.0, *) {
                .bottomBar
            } else {
                .automatic
            }
        }
        
        func body(content: Content) -> some View {
            content
            #if canImport(UIKit)
            .meNavigationTitle()
            .navigationBarTitleDisplayMode(isPhone ? .automatic : .inline)
            .toolbar {
                if sizeClass == .compact, cfg.state.ai.assistant {
                    ToolbarItem(placement: addPlacement) {
                        Button("Ask", systemImage: "sparkle") {
                            openDeepLink?(.ask)
                        }
                            .tint(.pink)
                    }
                }
                    
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(placement: .bottomBar)
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                    ToolbarSpacer(placement: .bottomBar)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    DeepLink(.settings()) {
                        Image(systemName: "gearshape")
                    }
                }
                
                if sizeClass == .compact {
                    ToolbarItem(placement: addPlacement) {
                        AddButton()
                            .tint(.accentColor)
                    }
                }
                
                ToolbarItemGroup(placement: .secondaryAction) {
                    Section { CollectionsMenu() }
                    Section { TagsMenu() }
                }
            }
            #endif
        }
    }
}
