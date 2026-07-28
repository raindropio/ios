import SwiftUI
import API

public func CollectionsList(_ selection: Binding<Int?>, system: [Int] = []) -> some View {
    _Optional(selection: selection, system: system)
}

public func CollectionsList(_ selection: Binding<Int>, system: [Int] = []) -> some View {
    _Strict(selection: selection, system: system)
}

//MARK: - Main implementation
fileprivate struct _Optional {
    @EnvironmentObject private var dispatch: Dispatcher
    @State private var search = ""

    @Binding var selection: Int?
    var system: [Int]
}

extension _Optional: View {
    var body: some View {
        List(selection: $selection) {
            if search.isEmpty {
                if system.contains(-1) {
                    SystemCollections<Int>(-1)
                }
                
                UserCollections<UserCollection.ID>()
                
                if system.contains(-99) {
                    SystemCollections<Int>(-99)
                }
            } else {
                FindCollections<Int>(search)
            }
        }
            .searchable(text: $search)
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            #if canImport(UIKit)
            .listStyle(.insetGrouped)
            .headerProminence(.increased)
            #endif
            .labelStyle(.sidebar)
            .collectionsAnimation()
            .contextMenu(forSelectionType: FindBy.self) { selection in
                CollectionsMenu(selection)
            }
            .reload(priority: .background) {
                try? await dispatch(CollectionsAction.load)
            }
    }
}

//MARK: - Support non-optional binding
fileprivate struct _Strict: View {
    @State private var local: Int?
    
    @Binding var selection: Int
    var system: [Int]
    
    var body: some View {
        _Optional(selection: $local, system: system)
            .task(id: selection) {
                local = selection
            }
            .onChange(of: local) {
                selection = $0 ?? -1
            }
    }
}
