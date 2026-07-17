import Foundation

/// App-owned staging area for files received from pickers / drag&drop / share sheet.
/// Every received file gets its own unique subdirectory (so equal names never collide),
/// lives there until uploaded, and is discarded right after a successful upload.
public enum FileStaging {
    public static var root: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("staged-items", isDirectory: true)
    }

    /// Reserve a unique destination for a file with the given name
    static func destination(name: String) throws -> URL {
        let dir = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let safeName = name.isEmpty ? UUID().uuidString : name
        return dir.appendingPathComponent(safeName)
    }

    /// Copy an external file into the staging area
    public static func stage(copying url: URL, name: String? = nil) throws -> URL {
        let copy = try destination(name: name ?? url.lastPathComponent)
        try FileManager.default.copyItem(at: url, to: copy)
        return copy
    }

    /// Write data into the staging area
    public static func stage(_ data: Data, name: String) throws -> URL {
        let url = try destination(name: name)
        try data.write(to: url)
        return url
    }

    /// Remove a staged file together with its unique subdirectory. No-op for foreign urls
    public static func discard(_ url: URL) {
        guard url.standardizedFileURL.path.hasPrefix(root.standardizedFileURL.path + "/")
        else { return }
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    /// Drop leftovers from interrupted sessions
    public static func cleanStale(olderThan age: TimeInterval = 60 * 60 * 48) {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let deadline = Date(timeIntervalSinceNow: -age)
        for dir in dirs {
            let modified = (try? dir.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            if (modified ?? .distantPast) < deadline {
                try? fm.removeItem(at: dir)
            }
        }
    }
}
