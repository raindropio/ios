import SwiftUI
import API
import UI
import Backport

//MARK: - Init
public struct TagsList: View {
    @EnvironmentObject private var f: FiltersStore
    @EnvironmentObject private var r: RecentStore

    @Binding var value: [String]

    public init(_ value: Binding<[String]>) {
        self._value = value
    }

    public var body: some View {
        Memorized(
            known: known,
            recents: r.state.tags,
            value: $value
        )
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
}

//MARK: - View
extension TagsList {
    fileprivate struct Memorized: View {
        @EnvironmentObject private var dispatch: Dispatcher
        @State private var new = ""
        @State private var searching = true
        @FocusState private var focused: Bool
        @Namespace private var namespace

        var known: [String: Filter]
        var recents: [String]
        @Binding var value: [String]

        private var trimmed: String {
            new.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private var filter: String {
            trimmed.localizedLowercase
        }

        private var selected: [String] {
            value.filter { filter.isEmpty || $0.localizedStandardContains(filter) }
        }

        private var pool: [String] {
            Array(known.keys) + value.filter { known[$0] == nil }
        }

        private var recent: [String] {
            guard filter.isEmpty else { return [] }
            return recents.filter { !value.contains($0) }
        }

        //each unselected tag renders in exactly one section, keeping matched geometry ids unique
        private var all: [String] {
            let recent = Set(recent)
            return matches(filter).filter { !recent.contains($0) }
        }

        //exact > prefix > contains, alphabetical within each group
        private func matches(_ query: String) -> [String] {
            let picked = Set(value)
            func rank(_ tag: String) -> Int? {
                guard !query.isEmpty else { return 2 }
                guard let range = tag.localizedStandardRange(of: query) else { return nil }
                guard range.lowerBound == tag.startIndex else { return 2 }
                return range.upperBound == tag.endIndex ? 0 : 1
            }
            return pool
                .compactMap { tag -> (tag: String, rank: Int)? in
                    guard !picked.contains(tag), let rank = rank(tag) else { return nil }
                    return (tag, rank)
                }
                .sorted {
                    if $0.rank != $1.rank { return $0.rank < $1.rank }
                    return $0.tag.localizedStandardCompare($1.tag) == .orderedAscending
                }
                .map(\.tag)
        }

        //case- and diacritic-insensitive whole-string match
        private func exact(_ query: String) -> String? {
            pool.first { $0.localizedStandardRange(of: query) == $0.startIndex..<$0.endIndex }
        }

        private var creatable: Bool {
            !filter.isEmpty && exact(filter) == nil
        }

        private func toggle(_ tag: String) {
            if value.contains(tag) {
                value.removeAll { $0 == tag }
            } else {
                value.append(tag)
                if !new.isEmpty {
                    new = ""
                }
            }
        }

        //selects the best existing match, creates only when nothing matches
        private func commit(_ text: String) {
            let tag = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tag.isEmpty else { return }
            let match = exact(tag)
                ?? matches(tag).first
                ?? tag
            if !value.contains(match) {
                value.append(match)
            }
        }

        //creates exactly what was typed
        private func create() {
            let tag = trimmed
            if !tag.isEmpty, !value.contains(tag) {
                value.append(tag)
            }
            new = ""
        }

        private func submit() {
            let text = trimmed
            let keep = !text.isEmpty
            searching = keep
            focused = keep
            commit(text)
            new = ""
        }

        private func comma() {
            guard new.contains(",") else { return }
            let parts = new.split(separator: ",", omittingEmptySubsequences: false)
            for part in parts.dropLast() {
                commit(String(part))
            }
            new = String(parts.last ?? "")
        }

        var body: some View {
            let all = all
            List {
                //selected
                if !selected.isEmpty {
                    WStack(spacingX: 8, spacingY: 8) {
                        ForEach(selected, id: \.self) { tag in
                            Button {
                                toggle(tag)
                            } label: {
                                HStack(spacing: 5) {
                                    Text(tag)
                                    Image(systemName: "xmark")
                                        .imageScale(.small)
                                        .foregroundStyle(.secondary)
                                }
                            }
                                .matchedGeometryEffect(id: tag, in: namespace, properties: .position)
                        }
                    }
                        .safeAnimation(.snappy, value: selected)
                        .buttonStyle(Backport.glassProminent)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 8, leading: 8, bottom: 16, trailing: 8))
                        .listSectionSpacing(.custom(0))
                }

                //create
                if creatable {
                    Section {
                        Button(action: create) {
                            Label("Create \"\(trimmed)\"", systemImage: "plus")
                        }
                            .matchedGeometryEffect(id: trimmed, in: namespace, properties: .position)
                    }
                }

                //recent
                if !recent.isEmpty {
                    Section {
                        ForEach(recent, id: \.self) { tag in
                            row(tag, filter: known[tag])
                        }
                    } header: {
                        HStack {
                            Text("Recent")
                            Spacer()
                            ActionButton("Clear") {
                                try? await dispatch(RecentAction.clearTags)
                            }
                        }
                    }
                }

                //tags
                if !all.isEmpty {
                    Section("Available") {
                        ForEach(all, id: \.self) { tag in
                            row(tag, bold: !filter.isEmpty && all.first == tag, filter: known[tag])
                        }
                    }
                }
            }
                .safeAnimation(.snappy, value: value)
                .safeAnimation(.snappy, value: filter)
                .safeAnimation(.snappy, value: recents)
                .overlay {
                    if pool.isEmpty && recent.isEmpty && filter.isEmpty {
                        EmptyState("No tags", message: Text("Find or create tags using the search field")) {
                            Image(systemName: "number")
                        } actions: {}
                    }
                }
                .searchable(text: $new, isPresented: $searching, prompt: "Add tag")
                .searchPresentationToolbarBehavior(.avoidHidingContent)
                .submitLabel(.return)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .backport.searchFocused($focused)
                .onSubmit(of: .search, submit)
                .onChange(of: new) { comma() }
                .tagSheets()
                .reload(priority: .background) {
                    try? await dispatch(
                        FiltersAction.reload(),
                        RecentAction.reload()
                    )
                }
        }

        private func row(_ tag: String, bold: Bool = false, filter: Filter? = nil) -> some View {
            Button {
                toggle(tag)
            } label: {
                Text(tag)
                    .tint(.primary)
                    .bold(bold)
            }
                .matchedGeometryEffect(id: tag, in: namespace, properties: .position)
                .badge(filter?.count ?? 0)
                .swipeActions {
                    if let filter {
                        TagsMenu(filter)
                    }
                }
        }
    }
}
