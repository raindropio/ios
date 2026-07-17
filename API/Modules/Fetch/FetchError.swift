import Foundation

public enum FetchError: LocalizedError, Codable {
    case invalidStatus(URL, Int)
    case invalidRequest(URL?, String? = nil)
    case invalidResponse(URL, String? = nil)
    ///transport failure; `code` is URLError.Code.rawValue, preserved so retry
    ///policy can tell "never reached the server" from ambiguous mid-flight failures
    case network(URL, code: Int, String? = nil)
    case decoding(String? = nil)

    public var errorDescription: String? {
        switch self {
        case .invalidStatus(_, let statusCode): return HTTPURLResponse.localizedString(forStatusCode: statusCode)
        case .invalidRequest(_, let message): return message ?? String(localized: "Invalid request")
        case .invalidResponse(_, let message): return message ?? String(localized: "Invalid response")
        case .network(_, let code, let message): return message ?? URLError(URLError.Code(rawValue: code)).localizedDescription
        case .decoding(let message): return message ?? String(localized: "Impossible to decode response")
        }
    }
}

extension FetchError {
    ///true only when the request provably never reached the server, so resending
    ///cannot duplicate anything — the safe retry policy even for non-idempotent
    ///creates. Ambiguous outcomes (timeout, connection lost mid-flight, gateway
    ///5xx) return false: the item may already exist server-side
    public static func requestNeverReachedServer(_ error: Error) -> Bool {
        guard let error = error as? FetchError
        else { return false }

        switch error {
        case .network(_, let code, _):
            switch URLError.Code(rawValue: code) {
            case .notConnectedToInternet,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dnsLookupFailed,
                 .dataNotAllowed,
                 .internationalRoamingOff:
                return true
            default:
                return false
            }
        case .invalidStatus(_, let code):
            //explicitly rejected without being processed
            return code == 408 || code == 429 || code == 503
        default:
            return false
        }
    }
}
