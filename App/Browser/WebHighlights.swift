import SwiftUI
import UIKit
import UI
import API

struct WebHighlights {
    @EnvironmentObject private var dispatch: Dispatcher
    @EnvironmentObject private var user: UserStore
    @Environment(\.sendWebMessage) private var _send
    private static let channel = "rdh"
    private static let highlightsJs = Bundle.main.url(forResource: "highlights", withExtension: "js")!
    
    @ObservedObject var page: WebPage
    @Binding var raindrop: Raindrop
    @Binding var loading: Bool
    
    private func onMessageFromPage(_ event: Event) async {
        switch event {
        //highlighting script is loaded
        case .ready:
            await reload()
            
        //add new
        case .add(let highlight):
            guard !loading else { return }
            raindrop.highlights.append(highlight)

            try? await dispatch(
                raindrop.isNew ? RaindropsAction.create(raindrop) : RaindropsAction.update(raindrop)
            )
            
        //updated
        case .update(let updated):
            guard !loading else { return }
            guard let index = raindrop.highlights.firstIndex (where: { $0.id == updated._id })
            else { return }
            
            if let text = updated.text {
                raindrop.highlights[index].text = text
            }
            if let note = updated.note {
                raindrop.highlights[index].note = note
            }
            if let color = updated.color {
                raindrop.highlights[index].color = color
            }
            if let position = updated.position {
                raindrop.highlights[index].position = position
            }
            
            try? await dispatch(RaindropsAction.update(raindrop))
            
        //removed
        case .remove(let removed):
            guard !loading else { return }
            guard let index = raindrop.highlights.firstIndex (where: { $0.id == removed._id })
            else { return }
            
            raindrop.highlights[index].text = ""
            
            try? await dispatch(RaindropsAction.update(raindrop))
            
        case .unknown:
            break
        }
    }
    
    private func reload() async {
        guard page.progress == 1 else { return }
        
        try? await send(.config(.init(enabled: true, nav: true, pro: user.state.me?.pro == true, hide_new_toolbar: true)))
        try? await send(.apply(raindrop.highlights))
    }
    
    private func send(_ action: Action) async throws {
        try await _send(page, channel: Self.channel, message: action)
    }
}

extension WebHighlights: ViewModifier {
    func body(content: Content) -> some View {
        content
            .injectJavaScript(page, file: Self.highlightsJs)
            .onWebMessage(page, channel: Self.channel, receive: onMessageFromPage)
            .webEditMenu(page) {[
                UIMenu(
                    title: String(localized: "Highlight"),
                    image: UIImage(systemName: "highlighter"),
                    options: .displayInline,
                    children: Highlight.Color.bestCases.map { color in
                        UIAction(
                            title: "",
                            image: UIImage(systemName: "circle.fill")?.withTintColor(UIColor(color.ui), renderingMode: .alwaysOriginal)
                        ) { _ in
                            Task { try? await send(.addSelection(color)) }
                        }
                    }
                ),
                
                UIAction(title: String(localized: "Note"), image: UIImage(systemName: "ellipsis.bubble")) { _ in
                    Task { try? await send(.noteSelection) }
                }
            ]}
            .task(id: page.progress) { await reload() }
            .task(id: raindrop.highlights) { await reload() }
    }
}
