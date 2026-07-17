import SwiftUI
import API
import UI
import Features

struct SaveFiles: View {
    var found: DetectedItems
    @State var collection: Int?

    var body: some View {
        Group {
            if let collection {
                AddStack(found.urls, detectFailures: found.failures, to: collection)
                    .presentationDetents([.fraction(0.333)])
                    .presentationBackground(.regularMaterial)
            } else {
                NavigationStack {
                    CollectionsList($collection, system: [-1])
                        .collectionSheets()
                        .navigationTitle("Where to save")
                        #if canImport(UIKit)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            CancelToolbarItem()
                        }
                }
            }
        }
            .transition(.opacity)
            .safeAnimation(.default, value: collection)
    }
}
