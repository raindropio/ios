import WebKit

extension WebPage: WKNavigationDelegate {
    //decide navigation
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let handler = navigationDecisionHandler else {
            decisionHandler(.allow)
            return
        }
        decisionHandler(handler(navigationAction, false))
    }

    //start
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.error = nil
    }
    
    //response recieved
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if navigationResponse.isForMainFrame {
            //remove background for non text response
            let isText = navigationResponse.response.mimeType?.contains("text") ?? true
            #if canImport(UIKit)
            view?.isOpaque = isText
            view?.backgroundColor = isText ? nil : .clear
            #else
            view?.setValue(isText, forKey: "drawsBackground")
            #endif
            
            //show error for non ok response
            if let response = navigationResponse.response as? HTTPURLResponse {
                if response.statusCode >= 400 {
                    onError(webView, error: NSError(
                        domain: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                        code: response.statusCode
                    ))
                }
            }
        }
        
        decisionHandler(.allow)
    }
    
    //finish
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        #if canImport(UIKit)
        webView.scrollView.refreshControl?.endRefreshing()
        
        //fix inset issue on some websites
        if webView.scrollView.contentInsetAdjustmentBehavior != .never {
            webView.scrollView.contentInset.top = 1
            webView.scrollView.contentInset.top = 0
        }
        #endif
    }
    
    //error
    private func onError(_ webView: WKWebView, error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        self.error = error
        #if canImport(UIKit)
        webView.scrollView.refreshControl?.endRefreshing()
        #endif
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onError(webView, error: error)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        onError(webView, error: error)
    }
}
