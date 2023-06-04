import Foundation
#if os(Linux)
import FoundationNetworking
#endif

final class HTTPClientFactory {
    static func makeSession(cookies: [URL: [Cookie]], additionalHeaders: [String: String]? = nil) -> URLSession {
        let cookieStorage = HTTPCookieStorage.shared
        cookies.forEach {
            cookieStorage.setCookies($0.value.http, for: $0.key, mainDocumentURL: nil)
        }
        return makeSession(cookieStorage: cookieStorage, additionalHeaders: additionalHeaders)
    }
    
    static func makeSession(cookieStorage: HTTPCookieStorage = .shared, additionalHeaders: [String: String]? = nil) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = cookieStorage
        
        if let additionalHeaders {
            configuration.httpAdditionalHeaders = additionalHeaders
        }
        
        return URLSession(configuration: configuration)
    }
    
    static func makeHTTPClient(session: URLSession = makeSession()) -> HTTPClient {
        HTTPClientLogger(decoratee: HTTPClientImpl(session: session))
    }
}
