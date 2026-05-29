import Foundation
import CoreTransferable
#if canImport(UIKit)
import UIKit
#endif

extension Array where Element == NSItemProvider {
    //detect URLs of files or web pages (including from text)
    public func urls() async -> Set<URL> {
        var found: Set<URL> = []
        for item in self {
            let url = try? await item.url()
            if let url {
                found.insert(url)
            }
        }
        return found
    }
}

extension NSItemProvider {
    //detect single URL of file or web page (including from text)
    public func url() async throws -> URL? {
        //support edge cases
        if let url = try? await self.loadTransferable(type: URLFromData.self).rawValue {
            return url
        }
        
        //will work for almost any case
        return try await self.loadTransferable(type: DirectURL.self).rawValue
    }
}

fileprivate struct DirectURL: Transferable {
    private var string: String { rawValue.absoluteString }

    let rawValue: URL
    
    @Sendable init(_ url: URL) throws {
        if url.isFileURL {
            //unlock file
            _ = url.startAccessingSecurityScopedResource()
            //always make a file copy, required in any case.
            //unique dir per file so same-named files don't overwrite each other or dedupe in Set<URL>
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let name = url.lastPathComponent.isEmpty ? UUID().uuidString : url.lastPathComponent
            let copy = dir.appendingPathComponent(name)
            try FileManager.default.copyItem(at: url, to: copy)
            self.rawValue = copy
        } else {
            self.rawValue = url
        }
    }
    
    @Sendable init(_ received: ReceivedTransferredFile) throws {
        try self.init(received.file)
    }
    
    @Sendable init(_ text: String) throws {
        if let detected: URL = URL.detect(from: text) {
            try self.init(detected)
        } else {
            throw MyError.ignore
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
    
    enum MyError: Error {
        case ignore
    }
}

fileprivate struct URLFromData: Transferable {
    let rawValue: URL
    
    @Sendable init(_ data: Data) throws {
        //screenshot specific
        #if canImport(UIKit)
        if let image = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: data),
            let data = image.pngData() {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("\(UUID().uuidString).png")
            try data.write(to: url)
            self.rawValue = url
            return
        }
        #endif
        
        //youtube specific
        if let text = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) as? String,
           let detected: URL = URL.detect(from: text) {
            self.rawValue = detected
            return
        }
        
        throw MyError.ignore
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image, importing: self.init)
        DataRepresentation(importedContentType: .text, importing: self.init)
    }
    
    enum MyError: Error {
        case ignore
    }
}
