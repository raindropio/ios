import UniformTypeIdentifiers
import SwiftUI

extension UTType {
    public static var userCollection = UTType(exportedAs: "\(Bundle.main.bundleIdentifier!).collection")
}

extension UserCollection: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .userCollection)
        ProxyRepresentation(exporting: \.publicPage)
    }
}
