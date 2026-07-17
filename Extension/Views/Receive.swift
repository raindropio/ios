import SwiftUI
import API
import Features

struct Receive: View {
    @EnvironmentObject private var service: ExtensionService
    
    var body: some View {
        switch service.extensionType {
        case .share:
            DefaultCollection {
                Share(collection: $0)
            }
            
        case .action:
            Action()
        }
    }
}

extension Receive {
    struct DefaultCollection<C: View>: View {
        @EnvironmentObject private var c: CollectionsStore
        @AppStorage("extension-default-collection", store: UserDefaults(suiteName: Constants.appGroupName)) private var defaultCollection: Int = -1
        
        var content: (Int) -> C
        
        var body: some View {
            content(c.state.user[defaultCollection] == nil ? -1 : defaultCollection)
        }
    }
    
    struct Share: View {
        @EnvironmentObject private var service: ExtensionService
        var collection: Int
        
        var decoded: Raindrop? {
            var item: Raindrop? = service.decoded()
            item?.collection = collection
            return item
        }

        var body: some View {
            Group {
                if service.loading {
                    ProgressView()
                }
                else if let decoded {
                    RaindropStack(decoded, content: RaindropForm.init)
                } else {
                    AddDetect(service.items) { found in
                        //detecting
                        if found == nil {
                            ProgressView()
                        }
                        //no urls at all — the collection picker below would lead
                        //to a dead-end "n of n failed" with nothing to retry
                        else if let found, found.urls.isEmpty {
                            NothingFound()
                        }
                        //web url
                        else if let first = found?.urls.first, !first.isFileURL {
                            RaindropStack(
                                .new(link: first, collection: collection),
                                content: RaindropForm.init
                            )
                        }
                        //files
                        else if let found {
                            SaveFiles(found: found)
                        }
                    }
                }
            }
                .presentationDetents(UIDevice.current.userInterfaceIdiom == .phone ? [.fraction(0.75), .large] : [.large])
                .presentationBackground(.regularMaterial)
        }
    }
}

extension Receive {
    struct Action: View {
        @EnvironmentObject private var service: ExtensionService

        var body: some View {
            AddDetect(service.items) { found in
                if service.loading || found == nil {
                    ProgressView()
                }
                //nothing found
                else if let found, found.isEmpty {
                    NothingFound()
                }
                //add
                else if let found {
                    AddStack(found.urls, detectFailures: found.failures)
                }
            }
                .presentationDetents(UIDevice.current.userInterfaceIdiom == .phone ? [.fraction(0.333)] : [.large])
                .presentationBackground(.regularMaterial)
                .presentationCompactAdaptation(.sheet)
                .transition(.opacity)
                .safeAnimation(.default, value: service.loading)
        }
    }
}
