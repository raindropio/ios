import Foundation

public enum RestError: LocalizedError, Equatable {
    case unknown(String? = nil)
    case unauthorized(String? = nil)
    case forbidden(String? = nil)
    case notFound(String? = nil)
    case invalid(String? = nil)
    case tfaRequired(token: String)
    
    case appleAuthCredentialsInvalid
    case jwtAuthCallbackURLInvalid
    
    case subscriptionRestoreReceiptInvalid
    case purchaseHavePending
    case purchaseUnknownStatus
    
    public var errorDescription: String? {
        switch self {
        case .unknown(let message): return message ?? String(localized: "Unknown error")
        case .unauthorized(let message): return message ?? String(localized: "Please log in first")
        case .forbidden(let message): return message ?? String(localized: "You don't have access")
        case .notFound(let message): return message ?? String(localized: "Nothing found")
        case .invalid(let message): return message ?? String(localized: "Invalid request")
        case .tfaRequired(_): return String(localized: "2FA required")

        case .appleAuthCredentialsInvalid: return String(localized: "can't get apple sign in credentials")
        case .jwtAuthCallbackURLInvalid: return String(localized: "callback url doesn't have token")

        case .subscriptionRestoreReceiptInvalid: return String(localized: "receipt invalid")
        case .purchaseHavePending: return String(localized: "Purchase is pending. Please tap Restore later")
        case .purchaseUnknownStatus: return String(localized: "Unknown status. Please tap Restore later")
        }
    }
}
