import SwiftUI
import API
import UniformTypeIdentifiers

public extension View {
    func dropProvider() -> some View {
        modifier(DropProviderModifier())
    }
}

fileprivate struct DropProviderModifier: ViewModifier {
    @EnvironmentObject private var dispatch: Dispatcher

    @State private var pending: PendingDrop?

    struct PendingDrop: Identifiable {
        let id = UUID()
        var items: [NSItemProvider]
        var collection: Int
    }

    func onDrop(_ items: [NSItemProvider], _ collection: Int) {
        let raindropsDrag = items.contains {
            $0.hasItemConformingToTypeIdentifier(UTType.raindrop.identifier)
        }

        //only raindrops
        if raindropsDrag {
            Task {
                var ids = Set<Raindrop.ID>()
                for item in items {
                    if let raindrop = try? await item.loadTransferable(type: Raindrop.self) {
                        ids.insert(raindrop.id)
                    }
                }
                try? await dispatch(RaindropsAction.updateMany(.some(ids), .moveTo(collection)))
            }
        }
        //other nsitems
        else if !items.isEmpty {
            //present immediately: the import starts inside the sheet and consumes
            //providers right away, otherwise OS kills nsitems in short time
            pending = .init(items: items, collection: collection)
        }
    }

    func body(content: Content) -> some View {
        content
            .environment(\.drop, onDrop)
            .sheet(item: $pending) { drop in
                AddStack(drop.items, to: drop.collection)
                    .presentationDetents([.height(240)])
                    .presentationBackground(.regularMaterial)
            }
    }
}
