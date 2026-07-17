import SwiftUI
import API

///Drives the whole add flow — detecting picked items (staging files locally), then
///uploading them — with a per-item outcome for every single thing the user picked.
///Nothing is dropped silently: an item either ends up in `completed`,
///in `failedUploads`, or in `detectFailures`, and failures can be retried.
@MainActor
public final class AddPipeline: ObservableObject {
    public enum Phase: Equatable {
        case preparing
        case uploading
        case finished
    }

    @Published public private(set) var phase = Phase.preparing
    @Published public private(set) var prepared = 0
    ///how many items the current preparing pass is loading (a retry re-detects
    ///only the previously failed subset, not the whole batch)
    @Published public private(set) var prepareTotal = 0
    @Published public private(set) var urls = Set<URL>()
    @Published public private(set) var detectFailures = [DetectFailure]()
    @Published public var completed = Set<URL>()
    @Published public var failedUploads = [URL: RestError]()

    private var detected = false

    //inputs; providers are retained so failed detects can be retried
    //(e.g. iCloud originals that timed out).
    //nonisolated(unsafe): NSItemProvider isn't Sendable, but the array is
    //immutable after init and providers are thread-safe to load from
    private nonisolated(unsafe) let items: [NSItemProvider]
    private let initialURLs: Set<URL>
    private let initialFailures: [DetectFailure]

    //nonisolated (touching only the nonisolated inputs) so views can construct
    //the pipeline inside StateObject(wrappedValue:), which is not main-actor-isolated
    public nonisolated init(items: [NSItemProvider]) {
        self.items = items
        self.initialURLs = []
        self.initialFailures = []
    }

    public nonisolated init(urls: Set<URL>, detectFailures: [DetectFailure] = []) {
        self.items = []
        self.initialURLs = urls
        self.initialFailures = detectFailures
    }
}

extension AddPipeline {
    ///everything the user picked, as far as we know at the current phase
    public var total: Int {
        if items.isEmpty {
            return initialURLs.count + initialFailures.count
        }
        return detected ? urls.count + detectFailures.count : items.count
    }

    public var failedCount: Int {
        detectFailures.count + failedUploads.count
    }

    public var isRunning: Bool {
        phase != .finished
    }

    public var isSuccess: Bool {
        phase == .finished
            && !urls.isEmpty
            && completed.count == urls.count
            && detectFailures.isEmpty
    }

    public var canRetry: Bool {
        !failedUploads.isEmpty || (!items.isEmpty && !detectFailures.isEmpty)
    }

    public var failureReason: String? {
        failedUploads.values.first?.localizedDescription
            ?? detectFailures.first?.reason
    }
}

extension AddPipeline {
    public func run(_ dispatch: Dispatcher, collection: Int) async {
        if items.isEmpty {
            urls = initialURLs
            detectFailures = initialFailures
        }
        else if !detected {
            phase = .preparing
            prepared = 0
            prepareTotal = items.count

            let result = await items.detectItems { [weak self] done in
                self?.prepared = done
            }

            //sheet dismissed mid-detect: nothing will upload the staged copies
            guard !Task.isCancelled else {
                discard(result.urls)
                phase = .finished
                return
            }

            urls = result.urls
            detectFailures = result.failures
            detected = true
        }

        await upload(dispatch, collection: collection)
    }

    public func retry(_ dispatch: Dispatcher, collection: Int) async {
        //ignore a second tap racing the first one
        guard phase == .finished
        else { return }

        //give previously failed items another chance
        if !items.isEmpty, !detectFailures.isEmpty {
            phase = .preparing
            prepared = 0
            prepareTotal = detectFailures.count

            let redone = await detectFailures.map(\.id).detectItems(from: items) { [weak self] done in
                self?.prepared = done
            }

            guard !Task.isCancelled else {
                discard(redone.urls)
                phase = .finished
                return
            }

            urls.formUnion(redone.urls)
            detectFailures = redone.failures
        }

        await upload(dispatch, collection: collection)
    }

    private func discard(_ urls: Set<URL>) {
        for url in urls where url.isFileURL {
            FileStaging.discard(url)
        }
    }

    private func upload(_ dispatch: Dispatcher, collection: Int) async {
        defer { phase = .finished }

        guard !urls.isEmpty
        else { return }

        phase = .uploading

        //keep the process alive if the user briefly leaves the app mid-upload
        let activity = ExtendedActivity(reason: "File upload")
        defer { activity.end() }

        try? await dispatch(
            RaindropsAction.add(
                urls,
                collection: collection,
                completed: Binding(
                    get: { [weak self] in self?.completed ?? [] },
                    set: { [weak self] in self?.completed = $0 }
                ),
                failed: Binding(
                    get: { [weak self] in self?.failedUploads ?? [:] },
                    set: { [weak self] in self?.failedUploads = $0 }
                )
            )
        )
    }
}

///Asks the system not to suspend the process until `end()` is called.
///Without it, backgrounding the app kills in-flight uploads immediately
fileprivate final class ExtendedActivity: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    #if !canImport(UIKit)
    private let token: NSObjectProtocol
    #endif

    init(reason: String) {
        #if canImport(UIKit)
        ProcessInfo.processInfo.performExpiringActivity(withReason: reason) { [semaphore] expired in
            if expired {
                //the block is invoked a second time when background time runs
                //out — release the invocation parked below, its thread would
                //otherwise stay pinned until the upload chain unwinds
                semaphore.signal()
            } else {
                //hold the assertion until the work signals completion
                semaphore.wait()
            }
        }
        #else
        token = ProcessInfo.processInfo.beginActivity(options: .userInitiated, reason: reason)
        #endif
    }

    func end() {
        #if canImport(UIKit)
        semaphore.signal()
        #else
        ProcessInfo.processInfo.endActivity(token)
        #endif
    }
}
