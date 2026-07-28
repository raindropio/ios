import SwiftUI
import API
import UI
import Backport

public struct TagsList {
    @EnvironmentObject private var dispatch: Dispatcher
    @EnvironmentObject private var f: FiltersStore
    @State private var new = ""
    @State private var searching = true
    @FocusState private var focused: Bool
    @State private var scroll: String?

    @Binding var value: [String]

    public init(_ value: Binding<[String]>) {
        self._value = value
    }
}

extension TagsList {
    private var trimmed: String {
        new.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filter: String {
        trimmed.localizedLowercase
    }

    @MainActor
    private var known: [String: Filter] {
        .init(
            f.state.tags()
                .compactMap {
                    switch $0.kind {
                    case .tag(let tag): return (tag, $0)
                    default: return nil
                    }
                },
            uniquingKeysWith: { first, _ in first }
        )
    }

    @MainActor
    private var pool: [String] {
        let known = self.known
        return Array(known.keys) + value.filter { known[$0] == nil }
    }

    @MainActor
    private var all: [String] {
        pool
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .filter { filter.isEmpty || $0.localizedLowercase.contains(filter) }
    }

    @MainActor
    private var exact: String? {
        pool.first { $0.localizedLowercase == filter }
    }

    @MainActor
    private var creatable: Bool {
        !filter.isEmpty && exact == nil
    }

    private func select(_ selection: Set<String>) {
        let added = selection.subtracting(value)
        value = value.filter { selection.contains($0) } + added.sorted()
        if let tag = added.first, !new.isEmpty {
            new = ""
            scroll = tag
        }
    }

    private func create() {
        let tag = trimmed
        guard !tag.isEmpty else { return }
        if !value.contains(tag) {
            value.append(tag)
            scroll = tag
        }
        new = ""
    }

    @MainActor
    private func submit() {
        let keep = !new.isEmpty
        if let exact {
            if !value.contains(exact) {
                value.append(exact)
                scroll = exact
            }
            new = ""
        } else {
            create()
        }
        searching = keep
        focused = keep
    }

    private func autoscroll(_ proxy: ScrollViewProxy) {
        guard let scroll else { return }
        withAnimation {
            proxy.scrollTo(scroll, anchor: .center)
        }
        self.scroll = nil
    }
}

extension TagsList: View {
    public var body: some View {
        let known = known
        ScrollViewReader { proxy in
            List(selection: .init(get: { Set(value) }, set: select)) {
                //create
                if creatable {
                    Section {
                        Button(action: create) {
                            Label("Create \"\(trimmed)\"", systemImage: "plus")
                        }
                            .selectionDisabled()
                    }
                }

                //tags
                Section {
                    ForEach(all, id: \.self) { tag in
                        if let filter = known[tag] {
                            Text(tag)
                                .badge(filter.count)
                                .swipeActions { TagsMenu(filter) }
                        } else {
                            Text(tag)
                        }
                    }
                }
            }
                .environment(\.editMode, .constant(.active))
                .searchable(text: $new, isPresented: $searching, prompt: "Add tag")
                .searchPresentationToolbarBehavior(.avoidHidingContent)
                .submitLabel(.return)
                .backport.searchFocused($focused)
                .onSubmit(of: .search, submit)
                .onChange(of: scroll) {
                    autoscroll(proxy)
                }
                .safeAnimation(.default, value: all)
                .safeAnimation(.default, value: creatable)
                .tagSheets()
                .reload(priority: .background) {
                    try? await dispatch(FiltersAction.reload())
                }
        }
    }
}