import SwiftUI
import WebKit
import Backport

public struct WebView {
    @ObservedObject public var page: WebPage
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var request: WebRequest
    var userAgent: String?
    var pullToRefresh: Bool
    var autoAdjustInset: Bool
    
    public init(_ page: WebPage, request: WebRequest, userAgent: String? = nil, refreshable: Bool? = true, autoAdjustInset: Bool? = true) {
        self.page = page
        self.request = request
        self.userAgent = userAgent
        self.pullToRefresh = refreshable ?? true
        self.autoAdjustInset = autoAdjustInset ?? true
    }
}

extension WebView: View {
    public var body: some View {
        Holder(page: page, request: request, userAgent: userAgent, pullToRefresh: pullToRefresh, autoAdjustInset: autoAdjustInset)
            //progress bar
            .overlay(alignment: .topLeading) {
                ProgressBar(value: page.progress)
            }
            //dialogs
            .modifier(Dialogs(page: page))
            //allow back webview navigation
            .popGesture(page.canGoBack ? .never : .automatic)
    }
}

extension WebView {
    @MainActor struct Holder {
        @StateObject private var prev = Prev()
        @Environment(\.webViewNavigationDecision) private var navigationDecision

        @ObservedObject var page: WebPage
        var request: WebRequest
        var userAgent: String?
        var pullToRefresh: Bool
        var autoAdjustInset: Bool
                
        class Prev: ObservableObject {
            var request: WebRequest?
        }
        
        func makeView(context: Context) -> NativeWebView {
            //configuration
            let configuration = WKWebViewConfiguration()
            configuration.mediaTypesRequiringUserActionForPlayback = []
            configuration.allowsInlineMediaPlayback = true
            
            //user-agent should include build-in safari browser for better compatability
            configuration.applicationNameForUserAgent = userAgent ?? "Version/18.0 Mobile/15E148 Safari/605.1.15"
            
            //reuse cookies
            let cookies = HTTPCookieStorage.shared.cookies ?? []
            for cookie in cookies {
                configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
            
            //create webview
            let view = NativeWebView(frame: .zero, configuration: configuration)
            context.coordinator.view = view
            context.coordinator.load(request)
            prev.request = request
            
            //behaviour
            view.allowsBackForwardNavigationGestures = true
            #if canImport(UIKit)
            view.scrollView.contentInsetAdjustmentBehavior = autoAdjustInset ? .automatic : .never
            #endif
            
            //disable pull to refresh
            if !pullToRefresh {
                view.scrollView.refreshControl = nil
            }
            
            context.coordinator.navigationDecisionHandler = navigationDecision

            return view
        }
        
        func updateView(_ view: NativeWebView, context: Context) {
            context.coordinator.navigationDecisionHandler = navigationDecision

            if prev.request?.url.absoluteURL != request.url.absoluteURL {
                context.coordinator.load(request)
                prev.request = request
            }
        }
    }
}

#if canImport(UIKit)
extension WebView.Holder: UIViewRepresentable {
    func makeCoordinator() -> WebPage {
        page
    }
    
    func makeUIView(context: Context) -> NativeWebView {
        makeView(context: context)
    }
    
    func updateUIView(_ view: NativeWebView, context: Context) {
        updateView(view, context: context)
    }
}
#else
extension WebView.Holder: NSViewRepresentable {
    func makeCoordinator() -> WebPage {
        page
    }
    
    func makeNSView(context: Context) -> NativeWebView {
        makeView(context: context)
    }
    
    func updateNSView(_ view: NativeWebView, context: Context) {
        updateView(view, context: context)
    }
}
#endif
