import SwiftUI

fileprivate typealias AddOutcome = (url: URL, raindrop: Raindrop?, error: RestError?)

extension RaindropsReducer {
    //keep the upload window narrow: a mobile uplink shared by too many
    //concurrent requests starves each of them into a timeout
    private static let maxConcurrentUploads = 4

    func add(state: S, urls: Set<URL>, collection: Int?, completed: Binding<Set<URL>>?, failed: Binding<[URL: RestError]>?) async throws -> ReduxAction? {
        //nothing to add
        guard !urls.isEmpty
        else { return nil }

        //the bindings are backed by @MainActor state — read them there,
        //this reducer itself runs on the global executor
        let pending = await MainActor.run {
            urls.filter { !(completed?.wrappedValue ?? []).contains($0) }
        }

        var newRaindrops = [Raindrop]()

        await pending.forEachConcurrent(limit: Self.maxConcurrentUploads) { [self] url -> AddOutcome? in
            do {
                return (url, try await addOne(url: url, collection: collection), nil)
            } catch is CancellationError {
                return nil
            } catch {
                #if DEBUG
                print(error, url)
                #endif
                return (url, nil, (error as? RestError) ?? .unknown(error.localizedDescription))
            }
        } onEach: { outcome in
            guard let outcome else { return }

            //report each item as it lands, so progress is live and
            //nothing is lost if the batch gets interrupted midway
            await MainActor.run {
                if outcome.raindrop != nil {
                    completed?.wrappedValue.insert(outcome.url)
                    //clear any prior failure on success
                    failed?.wrappedValue.removeValue(forKey: outcome.url)
                } else if let error = outcome.error {
                    failed?.wrappedValue[outcome.url] = error
                }
            }

            if let raindrop = outcome.raindrop {
                newRaindrops.append(raindrop)
            }
        }

        //can't add anything
        guard !newRaindrops.isEmpty
        else { throw RestError.invalid("cant add") }

        return A.createdMany(newRaindrops)
    }

    //auto-retry is deliberately conservative (see withRetry's default predicate):
    //ambiguous failures surface to the manual Retry button instead of resending
    //a non-idempotent create
    private func addOne(url: URL, collection: Int?) async throws -> Raindrop {
        try await withRetry {
            //file
            if url.isFileURL {
                let raindrop = try await rest.raindropUploadFile(
                    file: url,
                    collection: collection
                )
                //uploaded, the staged copy is no longer needed
                FileStaging.discard(url)
                return raindrop
            }

            //web url
            var item = Raindrop.new(link: url)
            if let collection {
                item.collection = collection
            }
            return try await rest.raindropCreate(raindrop: item)
        }
    }
}
