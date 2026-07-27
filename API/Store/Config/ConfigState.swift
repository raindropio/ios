import Foundation

public struct ConfigState: ReduxState {
    public init() {}
    
    @Persisted("cfg-ai") public var ai = ConfigAI()
    @Persisted("cfg-collections") public var collections = ConfigCollections()
    @Persisted("cfg-raindrops") public var raindrops = ConfigRaindrops()
}

extension ConfigState: Codable {
    public init(from decoder: Decoder) throws {
        ai = try .init(from: decoder)
        collections = try .init(from: decoder)
        raindrops = try .init(from: decoder)
    }

    //ai is read-only for the app, so it's not sent back to the server
    public func encode(to encoder: Encoder) throws {
        try collections.encode(to: encoder)
        try raindrops.encode(to: encoder)
    }
}
