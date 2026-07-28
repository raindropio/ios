import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import API
#if canImport(UIKit)
import UIKit
#endif

//MARK: - Batch detect with per-item outcome

public struct DetectedItems: Equatable, Sendable {
    public var urls = Set<URL>()
    public var failures = [DetectFailure]()

    public init(urls: Set<URL> = [], failures: [DetectFailure] = []) {
        self.urls = urls
        self.failures = failures
    }

    public var isEmpty: Bool { urls.isEmpty && failures.isEmpty }
}

public struct DetectFailure: Identifiable, Equatable, Sendable {
    ///index of the provider in the originally picked batch
    public let id: Int
    public let name: String
    public let reason: String
}

fileprivate typealias DetectOutcome = (index: Int, url: URL?, error: Error?)

///the item loaded fine but carried nothing bookmarkable
fileprivate struct NoLinkFound: LocalizedError {
    var errorDescription: String? { String(localized: "No link found") }
}

extension Array where Element == NSItemProvider {
    ///Detect URLs of files or web pages (including from text).
    ///Unlike a plain `compactMap`, every item that can't be loaded is reported back —
    ///a photo the user picked must never disappear silently
    public func detectItems(progress: (@MainActor @Sendable (Int) -> Void)? = nil) async -> DetectedItems {
        await indices.detectItems(from: self, progress: progress)
    }
}

extension Collection where Element == Int {
    ///detect a subset of the batch, by original indices — used for retrying failures
    public func detectItems(
        from providers: [NSItemProvider],
        progress: (@MainActor @Sendable (Int) -> Void)? = nil
    ) async -> DetectedItems {
        FileStaging.cleanStale()

        var result = DetectedItems()
        var skipped = [Int]()
        var done = 0

        //providers should start loading right away (the OS invalidates them quickly),
        //but only a few at a time: each detected file is copied to disk
        await forEachConcurrent(limit: 3) { index -> DetectOutcome in
            do {
                return (index, try await providers[index].url(), nil)
            } catch {
                return (index, nil, error)
            }
        } onEach: { outcome in
            if let url = outcome.url {
                result.urls.insert(url)
            }
            //items with no usable content (a pasteboard often carries junk
            //side-items, like a bare filename next to a copied photo) are
            //noise, not lost user content — only surface them if nothing
            //else was found
            else if let error = outcome.error, error is NoLinkFound {
                skipped.append(outcome.index)
            } else {
                result.failures.append(.init(
                    id: outcome.index,
                    name: providers[outcome.index].suggestedName ?? String(localized: "Item \(outcome.index + 1)"),
                    reason: outcome.error?.localizedDescription ?? String(localized: "Unknown error")
                ))
            }

            done += 1
            if let progress {
                await progress(done)
            }
        }

        if result.isEmpty {
            result.failures = skipped.map {
                .init(
                    id: $0,
                    name: providers[$0].suggestedName ?? String(localized: "Item \($0 + 1)"),
                    reason: NoLinkFound().localizedDescription
                )
            }
        }

        result.failures.sort { $0.id < $1.id }

        return result
    }
}

//MARK: - Single item

extension NSItemProvider {
    //detect single URL of file or web page (including from text)
    public func url() async throws -> URL? {
        //items no representation can load are noise, not failures
        guard hasLoadableType
        else { throw NoLinkFound() }

        //media and documents go straight to a file representation: it streams
        //to disk, never materializing the whole asset in memory. The data-probing
        //path below would load every photo's full bytes into RAM just to inspect them
        if isFileMedia {
            return try await loadTransferable(type: DirectURL.self).rawValue
        }

        //support edge cases
        if let url = try? await loadTransferable(type: URLFromData.self).rawValue {
            return url
        }

        //will work for almost any case
        return try await loadTransferable(type: DirectURL.self).rawValue
    }

    ///mirrors exactly what DirectURL/URLFromData accept (String proxy = plain text only) — keep in sync
    private var hasLoadableType: Bool {
        registeredTypeIdentifiers.contains {
            guard let type = UTType($0) else { return false }

            return type.conforms(to: .url)
                || type.conforms(to: .plainText)
                || type.conforms(to: .image)
                || type.conforms(to: .movie)
                || type.conforms(to: .video)
                || type.conforms(to: .audio)
                || type.conforms(to: .pdf)
        }
    }

    ///concrete file-backed media/document type; exact abstract bases (public.image …)
    ///arrive as archived in-memory objects and need the data-probing path instead
    private var isFileMedia: Bool {
        registeredTypeIdentifiers.contains {
            guard
                let type = UTType($0),
                !type.isDynamic,
                ![.image, .movie, .video, .audio].contains(type)
            else { return false }

            return type.conforms(to: .image)
                || type.conforms(to: .movie)
                || type.conforms(to: .video)
                || type.conforms(to: .audio)
                || type.conforms(to: .pdf)
        }
    }
}

fileprivate struct DirectURL: Transferable {
    private var string: String { rawValue.absoluteString }

    let rawValue: URL

    @Sendable init(_ url: URL) throws {
        if url.isFileURL {
            //unlock file
            let unlocked = url.startAccessingSecurityScopedResource()
            defer {
                if unlocked {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            //always make a file copy, required in any case.
            //staged into a unique dir so same-named files don't overwrite each other or dedupe in Set<URL>
            self.rawValue = try FileStaging.stage(copying: url)
        }
        //a real web link always has a scheme and a host; pasteboards carry junk
        //url side-items (e.g. a bare export filename next to a photo copied from
        //the Photos app) that would otherwise turn into bogus bookmarks
        else if url.scheme != nil, url.host != nil || url.scheme == "mailto" {
            self.rawValue = url
        } else {
            throw NoLinkFound()
        }
    }

    @Sendable init(_ received: ReceivedTransferredFile) throws {
        try self.init(received.file)
    }

    @Sendable init(_ text: String) throws {
        if let detected: URL = URL.detect(from: text) {
            try self.init(detected)
        } else {
            throw NoLinkFound()
        }
    }

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.rawValue, importing: self.init)

        FileRepresentation(importedContentType: .fileURL, importing: self.init)
        FileRepresentation(importedContentType: .video, importing: self.init)
        FileRepresentation(importedContentType: .movie, importing: self.init)
        FileRepresentation(importedContentType: .audio, importing: self.init)
        FileRepresentation(importedContentType: .pdf, importing: self.init)
        FileRepresentation(importedContentType: .image, importing: self.init)

        ProxyRepresentation(exporting: \.string, importing: self.init)
    }
}

fileprivate struct URLFromData: Transferable {
    let rawValue: URL

    @Sendable init(_ data: Data) throws {
        //screenshot specific
        #if canImport(UIKit)
        if let image = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: data),
            let data = image.pngData() {
            self.rawValue = try FileStaging.stage(data, name: "\(UUID().uuidString).png")
            return
        }
        #endif

        //youtube specific
        if let text = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) as? String,
           let detected: URL = URL.detect(from: text) {
            self.rawValue = detected
            return
        }

        throw NoLinkFound()
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image, importing: self.init)
        DataRepresentation(importedContentType: .text, importing: self.init)
    }
}
