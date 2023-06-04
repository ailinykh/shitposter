import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import Logging

final class HTTPClientLogger {
    let decoratee: HTTPClient
    let logger: Logger
    
    init(decoratee: HTTPClient) {
        var logger = Logger(label: "http-cli")
                logger.logLevel = .debug
        self.logger = logger
        self.decoratee = decoratee
    }
}

extension HTTPClientLogger: HTTPClient {
    func head(url: URL) async throws -> URLResponse {
        logger.info("HEAD \(url)")
        let result = try await decoratee.head(url: url)
        logger.debug("HEAD completed: \(result)")
        return result
    }
    
    func get(url: URL) async throws -> (Data, URLResponse) {
        logger.info("GET \(url)")
        let result = try await decoratee.get(url: url)
        logger.debug("GET completed: \(String(data: result.0, encoding: .utf8) ?? "nil")")
        return result
    }
    
    func multipart(url: URL, params: [String: Multipart]) async throws -> (Data, URLResponse) {
        logger.info("POST multipart \(url)")
        let result = try await decoratee.multipart(url: url, params: params)
        logger.debug("POST multipart completed: \(String(data: result.0, encoding: .utf8) ?? "nil")")
        return result
    }
    
    func download(url: URL, progress: @escaping (Double) -> Void) async throws -> (URL, URLResponse) {
        logger.info("DOWNLOAD \(url)")
        let result = try await decoratee.download(url: url, progress: progress)
        logger.info("DOWNLOAD completed: \(result.0)")
        return result
    }
}
