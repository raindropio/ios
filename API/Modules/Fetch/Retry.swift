import Foundation

/// Retry an operation a few times when the failure is provably safe to resend.
/// The default predicate accepts only errors where the server never processed
/// the request, which is the one policy that is safe even for non-idempotent
/// create/upload calls — anything more aggressive risks server-side duplicates.
public func withRetry<T>(
    maxAttempts: Int = 3,
    isSafeToResend: (Error) -> Bool = FetchError.requestNeverReachedServer,
    _ operation: () async throws -> T
) async throws -> T {
    var attempt = 1

    while true {
        do {
            return try await operation()
        } catch {
            guard attempt < maxAttempts, isSafeToResend(error)
            else { throw error }

            //backoff before the next attempt
            try await Task.sleep(nanoseconds: UInt64(attempt) * 2_000_000_000)
            attempt += 1
        }
    }
}
