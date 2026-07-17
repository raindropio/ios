import Foundation
import CoreTransferable

extension NSItemProvider {
    /// async version of `loadTransferable`; cancelling the task cancels the load
    public func loadTransferable<T: Transferable>(type transferableType: T.Type) async throws -> T {
        let progress = ProgressBox()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                progress.set(self.loadTransferable(type: transferableType) {
                    switch $0 {
                    case .success(let result):
                        continuation.resume(returning: result)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
            }
        } onCancel: {
            progress.cancel()
        }
    }
}

///onCancel may fire before the load has started (no Progress yet) or from another
///thread — remember the cancellation and apply it whenever the Progress arrives
fileprivate final class ProgressBox: @unchecked Sendable {
    private let lock = NSLock()
    private var progress: Progress?
    private var cancelled = false

    func set(_ new: Progress) {
        lock.lock()
        progress = new
        let cancelled = cancelled
        lock.unlock()

        if cancelled {
            new.cancel()
        }
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let progress = progress
        lock.unlock()

        progress?.cancel()
    }
}
