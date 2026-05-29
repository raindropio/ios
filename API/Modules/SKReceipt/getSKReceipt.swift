import Foundation
import StoreKit

func getSKReceipt() async throws -> String {
    //refresh
    var refresher: ReceiptRefresher? = .init()
    try await refresher?.refresh()
    refresher = nil
    
    //read from file
    if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
        FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
        let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
        return receiptData.base64EncodedString(options: [])
    }
    
    throw SKError(.unknown)
}

fileprivate class ReceiptRefresher: NSObject, SKRequestDelegate {
    private var request: SKReceiptRefreshRequest
    private var continuation: CheckedContinuation<Void, Error>?
    
    override init() {
        request = SKReceiptRefreshRequest(receiptProperties: nil)
        super.init()
        request.delegate = self
    }
    
    func refresh() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            request.start()
        }
    }
    
    func requestDidFinish(_ request: SKRequest) {
        //resume exactly once — StoreKit can deliver both didFinish and didFail
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume()
        request.cancel()
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard let continuation else { return }
        self.continuation = nil
        if request is SKReceiptRefreshRequest {
            //refresh can end with error even if refresh is complete
            continuation.resume()
        } else {
            continuation.resume(throwing: error)
        }
    }
}
