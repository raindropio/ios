import SwiftUI
import UniformTypeIdentifiers
import API

public struct AddDetect<V: View> {
    ///nil while detection is in progress
    @State private var found: DetectedItems?

    var items: [NSItemProvider]
    var content: (DetectedItems?) -> V

    public init(
        _ items: [NSItemProvider],
        @ViewBuilder content: @escaping (DetectedItems?) -> V
    ) {
        self.items = items
        self.content = content
    }
}

extension AddDetect {
    func convert() async {
        found = nil

        var found = await items.detectItems()

        let web = found.urls.filter { !$0.isFileURL }
        //web urls are priority; files that lose to them won't be uploaded —
        //drop their staged copies right away instead of waiting for stale cleanup
        if !web.isEmpty {
            for url in found.urls where url.isFileURL {
                FileStaging.discard(url)
            }
            found.urls = web
        }

        self.found = found
    }
}

extension AddDetect: View {
    public var body: some View {
        content(found)
            .task(id: items, priority: .userInitiated) {
                await convert()
            }
    }
}
