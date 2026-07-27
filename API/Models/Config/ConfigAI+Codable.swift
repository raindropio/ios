import Foundation

extension ConfigAI: Codable {
    enum CodingKeys: CodingKey {
        case ai_assistant
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        assistant = (try? container.decode(Bool.self, forKey: .ai_assistant)) ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try? container.encode(assistant, forKey: .ai_assistant)
    }
}
