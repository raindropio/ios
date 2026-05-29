import SwiftUI
import UI
import API
import Features
import Backport

extension Folder.Toolbar {
    struct Regular: ViewModifier {
        @EnvironmentObject private var dispatch: Dispatcher
        @Environment(\.containerHorizontalSizeClass) private var sizeClass
        @Environment(\.openDeepLink) private var openDeepLink
        @IsEditing private var isEditing
        @State private var showFilterComposer = false

        @Binding var find: FindBy
        var pick: RaindropsPick
        var total: Int
        
        private var primaryActionsPlacement: ToolbarItemPlacement {
            if #available(iOS 26.0, *) {
                if sizeClass == .regular {
                    .primaryAction
                } else {
                    .bottomBar
                }
            } else {
                .primaryAction
            }
        }
        
        func body(content: Content) -> some View {
            content
                .toolbar {
                    if !isEditing {
                        ToolbarItem(placement: primaryActionsPlacement) {
                            Button("Ask", systemImage: "sparkle") {
                                openDeepLink?(.ask)
                            }
                                .tint(.pink)
                        }
                    }
                        
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(placement: primaryActionsPlacement)
                        DefaultToolbarItem(kind: .search, placement: primaryActionsPlacement)
                        ToolbarSpacer(placement: primaryActionsPlacement)
                    }
                    
                    if !isEditing {
                        ToolbarItem(placement: primaryActionsPlacement) {
                            AddButton(collection: find.collectionId)
                                .tint(.accentColor)
                        }
                        
                        if total > 0 {
                            if #available(iOS 26.0, *) {
                                ToolbarItem {
                                    EditButton("Select")
                                }
                                
                                ToolbarSpacer()
                            }
                        }
                        
                        if sizeClass == .regular {
                            ToolbarItem {
                                FilterRaindropsButton($find, show: $showFilterComposer)
                            }
                            
                            if #available(iOS 26.0, *) {
                                ToolbarSpacer()
                            }
                        }
                        
                        ToolbarItemGroup(placement: .secondaryAction) {
                            if #unavailable(iOS 26.0) {
                                EditButton("Select")
                            }
                            
                            if sizeClass == .compact {
                                FilterRaindropsButton($find, show: $showFilterComposer)
                            }
                            
                            SortRaindropsButton(find)
                            ViewConfigRaindropsButton(find)
                            
                            Section {
                                CollectionsMenu(find.collectionId)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showFilterComposer) {
                    FiltersComposer($find)
                }
        }
    }
}
