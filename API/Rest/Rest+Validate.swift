import Foundation

extension Rest {
    func validate(data: Data, res: URLResponse) async throws {
        //validate only json
        guard let mimeType = res.mimeType, mimeType.contains("json")
        else { return }
        
        let failed: FailedResponse = try fetch.decode(data: data)
        
        switch failed.status {
        case 400: throw RestError.invalid(failed.errorMessage)
        case 401: throw RestError.unauthorized(failed.errorMessage)
        case 403: throw RestError.forbidden(failed.errorMessage)
        case 404: throw RestError.notFound(failed.errorMessage)
        default: break
        }
    }
    
    fileprivate struct FailedResponse: Decodable {
        var status: Int?
        var errorMessage: String?
        
        enum CodingKeys: String, CodingKey {
            case status
            case errorMessage
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            status = try? container.decode(type(of: status), forKey: .status)
            errorMessage = try? container.decode(type(of: errorMessage), forKey: .errorMessage)
        }
    }
}
