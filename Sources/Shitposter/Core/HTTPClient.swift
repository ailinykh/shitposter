import Foundation
#if os(Linux)
import FoundationNetworking
#endif

enum Multipart {
    case data(Data)
    case file((String, String, URL))
}

protocol HTTPClient {
    func head(url: URL) async throws -> URLResponse
    func get(url: URL) async throws -> (Data, URLResponse)
    func multipart(url: URL, params: [String: Multipart]) async throws -> (Data, URLResponse)
    func download(url: URL, progress: @escaping (Double) -> Void) async throws -> (URL, URLResponse)
}
