import SwiftUI
import API
import UI
import Features

struct SplitView: View {
    @EnvironmentObject private var store: Store
    @State private var path = SplitViewPath()
    @SceneStorage("column-visibility") private var columnVisibility = NavigationSplitViewVisibility.automatic

    @ViewBuilder
    private func screen(_ screen: SplitViewPath.Screen) -> some View {
        switch screen {
        case .find(let find): FolderStateful(find: find)
        case .preview(let find, let id): Preview(find: find, id: id)
        case .cached(let id): PermanentCopy(id: id)
        case .browse(let url): Browse(url: url)
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: .constant(path.preferredCompactColumn)) {
            SidebarScreen(selection: $path.sidebar)
                .navigationSplitViewColumnWidth(min: 250, ideal: 450)
        } detail: {
            NavigationStack(path: $path.detail) {
                Group {
                    if let sidebar = path.sidebar {
                        Folder(find: .init(get: { sidebar }, set: { path.sidebar = $0 }))
                    }
                }
                //stores re-injected: cached destinations can re-evaluate detached from the hierarchy, losing ancestor environment objects
                .navigationDestination(for: SplitViewPath.Screen.self) { screen($0).storeProvider(store) }
            }
        }
            .inspector(isPresented: $path.ask){
                Ask(path: $path)
                    .inspectorColumnWidth(min: 250, ideal: 450)
            }
            //auto hide sidebar / ask
            .onChange(of: path.ask) { _, next in
                if next {
                    columnVisibility = .detailOnly
                }
            }
            .onChange(of: columnVisibility) { _, next in
                if next != .detailOnly && path.ask {
                    path.ask = false
                }
            }
            //split view specific
            .navigationSplitViewUnlockSize()
            .containerSizeClass()
            //sheets
            .collectionSheets()
            .tagSheets()
            //pushes
            .modifier(PushNotifications())
            //routing
            .modifier(ReceiveDeepLink(path: $path))
            .restoreSceneValue("app-path", value: $path)
    }
}
