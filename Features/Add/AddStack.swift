import SwiftUI
import API
import UI

//View conformance lives in an extension, so the type doesn't inherit
//@MainActor from the protocol — annotate explicitly: the helper views and
//upload/retry all touch the main-actor pipeline
@MainActor
public struct AddStack {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dispatch: Dispatcher
    @EnvironmentObject private var c: CollectionsStore
    @AppStorage("last-used-collection") private var lastUsedCollection: Int?

    @StateObject private var pipeline: AddPipeline
    @State var collection: Int

    public init(_ items: [NSItemProvider], to collection: Int? = nil) {
        self._pipeline = .init(wrappedValue: AddPipeline(items: items))
        self._collection = .init(initialValue: collection ?? -1)
    }

    public init(_ urls: Set<URL>, detectFailures: [DetectFailure] = [], to collection: Int? = nil) {
        self._pipeline = .init(wrappedValue: AddPipeline(urls: urls, detectFailures: detectFailures))
        self._collection = .init(initialValue: collection ?? -1)
    }
}

extension AddStack {
    private func upload() async {
        lastUsedCollection = collection
        await pipeline.run(dispatch, collection: collection)
    }

    private func retry() async {
        await pipeline.retry(dispatch, collection: collection)
    }
}

extension AddStack: View {
    @ViewBuilder
    private var status: some View {
        if pipeline.isSuccess {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 56, weight: .semibold))
        } else if !pipeline.isRunning {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 40, weight: .semibold))
        } else if pipeline.total <= 1 {
            ProgressView()
        } else if pipeline.phase == .preparing {
            ProgressView(
                value: Double(pipeline.prepared),
                total: Double(max(pipeline.prepareTotal, 1))
            ) {
                Text("Preparing \(pipeline.prepared) of \(pipeline.prepareTotal)…")
            }
                .frame(width: 256)
        } else {
            ProgressView(
                value: Double(pipeline.completed.count),
                total: Double(max(pipeline.total, 1))
            ) {
                Text(
                    Double(pipeline.completed.count) / Double(max(pipeline.total, 1)),
                    format: .percent.precision(.fractionLength(0))
                )
                + Text(" complete")
            }
                .frame(width: 256)
        }
    }

    @ViewBuilder
    private var failures: some View {
        if !pipeline.isRunning, pipeline.failedCount > 0 {
            VStack(spacing: 8) {
                Text("\(pipeline.failedCount) of \(pipeline.total) failed")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if let reason = pipeline.failureReason {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }

                if pipeline.canRetry {
                    ActionButton(action: retry) {
                        Label("Retry failed", systemImage: "arrow.clockwise")
                    }
                        .tint(.red)
                }
            }
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                status
                    .transition(.scale(scale: 1.5).combined(with: .opacity))

                failures
            }
                .scenePadding()
                .navigationTitle("Add to \(c.state.title(collection))")
                #if canImport(UIKit)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    CancelToolbarItem()
                }
        }
            .safeAnimation(.spring(), value: pipeline.isSuccess)
            .interactiveDismissDisabled(pipeline.isRunning)
            //start the pipeline; cancelling (sheet dismiss) stops it
            .task(priority: .userInitiated) {
                await upload()
            }
            //auto close when everything succeeded
            .task(id: pipeline.isSuccess) {
                if pipeline.isSuccess {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    dismiss()
                }
            }
    }
}
