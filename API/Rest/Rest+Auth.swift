import Foundation
import AuthenticationServices

//MARK: - Login
extension Rest {
    public func authLogin(_ body: AuthLoginRequest) async throws {
        let res: AuthResponse = try await fetch.post(
            "auth/email/login",
            body: body
        )
        
        if let tfa = res.tfa {
            throw RestError.tfaRequired(token: tfa)
        }
        
        guard res.result == true
        else { throw RestError.unauthorized }
    }
}

//MARK: - Sign up
extension Rest {
    public func authSignup(_ body: AuthSignupRequest) async throws {
        let res: ResultResponse = try await fetch.post(
            "auth/email/signup",
            body: body
        )
        
        guard res.result == true
        else { throw RestError.unknown() }
    }
}

//MARK: - Logout
extension Rest {
    public func authLogout() async throws {
        do {
            let _: ResultResponse = try await fetch.get(
                "auth/logout",
                query: [.init(name: "no_redirect", value: nil)]
            )
        }
        catch RestError.unauthorized {
            return
        }
        catch {
            throw error
        }
    }
}

//MARK: - Apple
extension Rest {
    public func authApple(credentials: ASAuthorizationAppleIDCredential) async throws {
        guard
            let identityToken = credentials.identityToken,
            let identityTokenString = String(data: identityToken, encoding: .utf8),
            let code = credentials.authorizationCode,
            let codeString = String(data: code, encoding: .utf8)
        else {
            throw RestError.appleAuthCredentialsInvalid
        }

        //fullName is only returned on the first authorization, never on refresh
        let displayName = credentials.fullName.map {
            "\($0.familyName ?? "") \($0.givenName ?? "") \($0.middleName ?? "")"
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } ?? ""

        let res: AuthResponse = try await fetch.get(
            "auth/apple/native",
            query: [
                .init(name: "code", value: codeString),
                .init(name: "identity_token", value: identityTokenString),
                .init(name: "display_name", value: displayName)
            ]
        )
        
        if let tfa = res.tfa {
            throw RestError.tfaRequired(token: tfa)
        }
        
        guard res.result == true
        else { throw RestError.unauthorized }
    }
}

//MARK: - Google
extension Rest {
    public func authGoogle(accessToken: String) async throws {
        let res: AuthResponse = try await fetch.get(
            "auth/google/native",
            query: [
                .init(name: "access_token", value: accessToken)
            ]
        )
        
        if let tfa = res.tfa {
            throw RestError.tfaRequired(token: tfa)
        }
        
        guard res.result == true
        else { throw RestError.unauthorized }
    }
}

//MARK: - Native
extension Rest {
    public enum AuthNativeProvider: String {
        case google
    }
    
    /// returns URL that can be opened in web browser, after success makes redirect to **deeplink** with JWT token. Then this deeplink can be used in `authJWTEnd` method
    /// deeplink example: raindrop://jwt
    public static func authJWTStart(_ provider: AuthNativeProvider, deeplink: URL) -> URL {
        //deeplink redirect url
        var redirect = URLComponents()
        redirect.path = "auth/jwt"
        redirect.queryItems = [
            URLQueryItem(
                name: "done_uri",
                value: deeplink.absoluteString
            )
        ]
        
        //main url
        var main = URLComponents()
        main.path = "auth/\(provider)"
        main.queryItems = [
            URLQueryItem(
                name: "redirect",
                value: redirect.url(relativeTo: Self.base.api)!.absoluteString
            )
        ]
        
        return main.url(relativeTo: Self.base.api)!
    }
}

//MARK: - JWT Token
extension Rest {
    public func authJWTEnd(_ callbackUrl: URL) async throws {
        guard
            let components = URLComponents(url: callbackUrl, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems,
            let token = queryItems.first(where: { item in item.name == "token" }),
            let tokenString = token.value
        else {
            throw RestError.jwtAuthCallbackURLInvalid
        }
        
        let res: ResultResponse = try await fetch.post(
            "auth/jwt",
            body: JWTTokenBody(token: tokenString)
        )
        
        guard res.result == true
        else { throw RestError.unauthorized }
    }
    
    fileprivate struct JWTTokenBody: Codable {
        var token: String
    }
}

//MARK: - 2FA
extension Rest {
    public func authTfa(token: String, code: String) async throws {
        let res: ResultResponse = try await fetch.post(
            "auth/tfa/\(token)",
            body: TFABody(code: code)
        )
        
        guard res.result == true
        else { throw RestError.unauthorized }
    }
    
    fileprivate struct TFABody: Codable {
        var code: String
    }
}
