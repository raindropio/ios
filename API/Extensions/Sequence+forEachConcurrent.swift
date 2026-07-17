extension Sequence where Element: Sendable {
    /// Sliding-window concurrency: at most `limit` transforms in flight, the next
    /// one starts as soon as any finishes (chunked batches would stall each batch
    /// on its slowest item). Results are delivered to `onEach` in completion order.
    /// Cancellation stops new transforms from starting; in-flight ones finish
    /// (or observe cancellation themselves).
    public func forEachConcurrent<R: Sendable>(
        limit: Int,
        transform: @escaping @Sendable (Element) async -> R,
        onEach: (R) async -> Void
    ) async {
        await withTaskGroup(of: R.self) { group in
            var iterator = makeIterator()

            func enqueueNext() {
                guard !Task.isCancelled, let element = iterator.next() else { return }
                group.addTask {
                    await transform(element)
                }
            }

            for _ in 0..<limit {
                enqueueNext()
            }

            for await result in group {
                enqueueNext()
                await onEach(result)
            }
        }
    }
}
