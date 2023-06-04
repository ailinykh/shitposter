import Foundation
#if os(Linux)
import FoundationNetworking
#endif

extension Cookie {
    var httpCookie: HTTPCookie {
        HTTPCookie(properties: [
            .domain: domain,
            .path: path,
            .secure: true,
            .name: name,
            .value: value
        ])!
    }
}

extension Array where Element == Cookie {
    var http: [HTTPCookie] {
        map { $0.httpCookie }
    }
}
