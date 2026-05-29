import SwiftUI

extension RaindropsReducer {
    func add(state: S, urls: Set<URL>, collection: Int?, completed: Binding<Set<URL>>?, failed: Binding<[URL: RestError]>?) async throws -> ReduxAction? {
        //nothing to add
        guard !urls.isEmpty
        else { return nil }
        
        var newRaindrops = [Raindrop]()

        let chunks = urls
            //ignore completed
            .filter { !(completed?.wrappedValue ?? []).contains($0) }
            //split to parallel tasks
            .chunked(into: 10)
        
        for chunk in chunks {
            //don't touch the @State bindings from the parallel child tasks (off-main data
            //race) — collect each outcome and apply it on the main actor below
            let outcomes = await withTaskGroup(of: (url: URL, raindrop: Raindrop?, error: RestError?).self) { [self] group in
                for url in chunk {
                    group.addTask {
                        do {
                            var raindrop: Raindrop

                            //file
                            if url.isFileURL {
                                raindrop = try await self.rest.raindropUploadFile(
                                    file: url,
                                    collection: collection
                                )
                            }
                            //web url
                            else {
                                var item = Raindrop.new(link: url)
                                if let collection {
                                    item.collection = collection
                                }
                                raindrop = try await self.rest.raindropCreate(raindrop: item)
                            }

                            return (url, raindrop, nil)
                        } catch {
                            print(error, url)
                            return (url, nil, (error as? RestError) ?? .unknown(error.localizedDescription))
                        }
                    }
                }

                var results = [(url: URL, raindrop: Raindrop?, error: RestError?)]()
                for await result in group {
                    results.append(result)
                }

                return results
            }

            await MainActor.run {
                for outcome in outcomes {
                    if outcome.raindrop != nil {
                        completed?.wrappedValue.insert(outcome.url)
                        //clear any prior failure on success
                        failed?.wrappedValue.removeValue(forKey: outcome.url)
                    } else if let error = outcome.error {
                        failed?.wrappedValue[outcome.url] = error
                    }
                }
            }

            newRaindrops += outcomes.compactMap(\.raindrop)
        }
        
        //can't add anything
        guard !newRaindrops.isEmpty
        else { throw RestError.invalid("cant add") }
        
        return A.createdMany(newRaindrops)
    }
}
