import SwiftUI
import API
import UI

public struct RaindropForm {
    @Binding var raindrop: Raindrop

    public init(_ raindrop: Binding<Raindrop>) {
        self._raindrop = raindrop
    }
}

extension RaindropForm: View {
    public var body: some View {
        RaindropSuggestedLoad(raindrop: raindrop) { suggestions in
            Form {
                Fields(raindrop: $raindrop, suggestions: suggestions)
                Actions(raindrop: $raindrop)
            }
                .safeAnimation(.default, value: suggestions)
        }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .safeAnimation(.snappy, value: raindrop.collection)
            .safeAnimation(.snappy, value: raindrop.tags.count)
            .modifier(Toolbar(raindrop: $raindrop))
            .navigationTitle((raindrop.isNew ? String(localized: "New") : String(localized: "Edit")) + " \(raindrop.type.single.localizedLowercase)")
            #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
            ._safeAreaInsets(.init(top: -15, leading: 0, bottom: 0, trailing: 0))
            #endif
            .toolbar {
                if raindrop.isNew {
                    ToolbarItem(placement: .confirmationAction) {
                        SubmitButton {
                            Text("Save")
                                .padding(.horizontal, 5)
                        }
                            #if canImport(UIKit)
                            .buttonBorderShape(.capsule)
                            #endif
                    }
                }
            }
    }
}
