import SwiftUI
import Features
import API
import UI
import Backport

struct Folder: View {
    @EnvironmentObject private var r: RaindropsStore
    @State private var pick: RaindropsPick = .some([])

    @Binding var find: FindBy
    var compact = false

    //single source of truth is `pick`; project the List's Set<ID> from it.
    //editing the set demotes `.all` back to `.some`
    private var selection: Binding<Set<Raindrop.ID>> {
        .init(
            get: {
                switch pick {
                case .all: return Set(r.state.ids(find))
                case .some(let ids): return ids
                }
            },
            set: { pick = .some($0) }
        )
    }

    var body: some View {
        RaindropsContainer(find, selection: selection) {
            if !find.isSearching {
                Nesteds(find: find)
            }

            if !compact {
                RaindropItems(find)
                LoadMoreRaindropsButton(find)
            }
        }
            .pasteCommands(to: find.collectionId)
            .modifier(SearchBar(find: $find))
            .backport.searchPresentationToolbarBehavior(.avoidHidingContent)
            .modifier(Title(find: find))
            .modifier(Toolbar(find: $find, pick: $pick))
            .raindropSheets()
            #if canImport(UIKit)
            .scopeEditMode()
            #endif
            .onChange(of: find) {
                pick = .some([])
            }
            .dropProvider()
    }
}

struct FolderStateful: View {
    @State var find: FindBy

    var body: some View {
        Folder(find: $find)
    }
}
