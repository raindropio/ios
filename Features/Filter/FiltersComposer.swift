import SwiftUI
import API
import UI

public struct FiltersComposer: View {
    @EnvironmentObject private var f: FiltersStore
    @EnvironmentObject private var dispatch: Dispatcher

    @Binding var find: FindBy
    
    public init(_ find: Binding<FindBy>) {
        self._find = find
    }

    public var body: some View {
        let scoped = find.excludingFilters()
        
        Memorized(
            find: $find,
            tags: f.state.tags(scoped),
            simple: f.state.simple(scoped),
            created: f.state.created(scoped)
        )
        .task(id: find, priority: .background, debounce: 0.3) {
            try? await dispatch(FiltersAction.reload(scoped))
        }
    }
}

extension FiltersComposer {
    fileprivate struct Memorized: View {
        @Binding var find: FindBy
        var tags: [Filter]
        var simple: [Filter]
        var created: [Filter]
        
        @Environment(\.dismiss) private var dismiss
        @State private var show = false
        
        //match by identity (id = kind+exclude); full == also compares the volatile count
        private func isSelected(_ item: Filter) -> Bool {
            find.filters.contains { $0.id == item.id }
        }

        private func toggle(_ item: Filter) {
            if isSelected(item) {
                find.filters.removeAll { $0.id == item.id }
            } else {
                find.filters.append(item)
            }
        }

        private var selectedCreated: Binding<Filter?> {
            .init(
                get: {
                    //return the displayed element so the Picker (matches tags by Hashable) highlights it
                    guard let selected = find.filters.first(where: {
                        if case .created = $0.kind {
                            return true
                        }
                        return false
                    }) else { return nil }

                    return created.first { $0.id == selected.id } ?? selected
                },
                set: {
                    find.filters = find.filters.filter {
                        if case .created = $0.kind {
                            return false
                        }
                        return true
                    }
                    if let filter = $0 {
                        find.filters.append(filter)
                    }
                }
            )
        }
        
        private func activeBadge(_ item: Filter) -> Text {
            let active = isSelected(item)

            return .init(active ? "✓" : String(item.count))
                .foregroundColor(active ? .accentColor : .secondary)
                .fontWeight(active ? .semibold : nil)
        }
                
        var body: some View {
            NavigationStack {
                List {
                    Picker("Created", systemImage: "calendar", selection: selectedCreated) {
                        Text("Any time")
                            .tag(nil as Filter?)
                        
                        ForEach(created) { item in
                            Text(item.title)
                                .tag(item)
                        }
                    }
                        .disabled(created.isEmpty)
                    
                    if !created.isEmpty {
                        Section {
                            ForEach(simple) { item in
                                Button {
                                    toggle(item)
                                } label: {
                                    Label {
                                        Text(item.title).foregroundColor(.primary)
                                    } icon: {
                                        Image(systemName: item.systemImage)
                                    }
                                }
                                .badge(activeBadge(item))
                                .listItemTint(item.color)
                            }
                        }
                    }
                    
                    if !tags.isEmpty {
                        Section("Tags") {
                            ForEach(tags) { item in
                                Button {
                                    toggle(item)
                                } label: {
                                    Label {
                                        Text(item.title).foregroundColor(.primary)
                                    } icon: {
                                        Image(systemName: item.systemImage)
                                    }
                                }
                                .badge(activeBadge(item))
                            }
                        }
                    }
                }
                .symbolVariant(.fill)
                .navigationTitle("Filter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if !find.filters.isEmpty {
                            Button("Reset") {
                                find.filters = []
                            }
                        }
                    }
                    
                    DoneToolbarItem()
                }
                .presentationDetents(UIDevice.current.userInterfaceIdiom == .phone ? [.medium, .large] : [.large])
                .animation(.default, value: find.filters.count)
            }
        }
    }
}
