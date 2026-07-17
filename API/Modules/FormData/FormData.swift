import Foundation
import UniformTypeIdentifiers

struct FormData {
    private enum Value {
        case field(String)
        case file(URL)
    }

    //insertion-ordered, plain fields are emitted before files
    private var params = [(key: String, value: Value)]()

    mutating func append<S: CustomStringConvertible>(key: String, value: S) {
        params.append((key, .field(String(describing: value))))
    }

    mutating func append(key: String, value: URL) {
        params.append((key, .file(value)))
    }
}

extension FormData {
    /// Write the whole multipart body to a temporary file, streaming file contents
    /// chunk by chunk (constant memory). A file-backed body lets URLSession rewind
    /// and resend it when a connection is dropped or redirected — an InputStream body can't be replayed.
    /// The file lives in the FileStaging area, so leftovers from a killed process
    /// are swept by its stale cleanup. Caller is responsible for discarding the returned file.
    func buildFile(boundary: String) throws -> URL {
        let url = try FileStaging.destination(name: "multipart.body")

        guard FileManager.default.createFile(atPath: url.path, contents: nil)
        else { throw URLError(.cannotCreateFile) }

        do {
            try writeBody(to: url, boundary: boundary)
        } catch {
            //don't leave a partially written body behind
            FileStaging.discard(url)
            throw error
        }

        return url
    }

    private func writeBody(to url: URL, boundary: String) throws {
        let lineBreak = "\r\n"

        let out = try FileHandle(forWritingTo: url)
        defer { try? out.close() }

        func write(_ string: String) throws {
            try out.write(contentsOf: Data(string.utf8))
        }

        //plain fields first so the server sees them before the (large) file parts
        let ordered =
            params.filter { if case .field = $0.value { true } else { false } }
            + params.filter { if case .file = $0.value { true } else { false } }

        for (key, value) in ordered {
            switch value {
            case .field(let field):
                try write("--\(boundary)\(lineBreak)")
                try write("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
                try write("\(field)\(lineBreak)")

            case .file(let file):
                //quotes and newlines in a user-supplied name would break the header framing
                let fileName = file.lastPathComponent
                    .components(separatedBy: .newlines).joined(separator: " ")
                    .replacingOccurrences(of: "\"", with: "'")
                let mimeType = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType
                               ?? "application/octet-stream"

                try write("--\(boundary)\(lineBreak)")
                try write("""
                          Content-Disposition: form-data; name="\(key)"; filename="\(fileName)"\(lineBreak)\
                          Content-Type: \(mimeType)\(lineBreak)\(lineBreak)
                          """)

                let input = try FileHandle(forReadingFrom: file)
                defer { try? input.close() }

                while let chunk = try input.read(upToCount: 1 << 20), !chunk.isEmpty {
                    try out.write(contentsOf: chunk)
                }

                try write(lineBreak)
            }
        }

        try write("--\(boundary)--\(lineBreak)")
    }
}
