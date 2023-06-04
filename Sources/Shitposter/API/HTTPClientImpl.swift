import Foundation
#if os(Linux)
import FoundationNetworking
#endif


final class HTTPClientImpl: NSObject {
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private func makeBody(params: [String: Multipart], boundary: String) throws -> Data {
        var data = Data()
        try params.forEach {
            switch $0.value {
            case .data(let content):
                data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"\($0.key)\";\r\n\r\n".data(using: .utf8)!)
                data.append(content)
            case .file((let filename, let mime, let url)):
                data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"\($0.key)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
                data.append(try Data(contentsOf: url))
            }
        }
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }
}

extension HTTPClientImpl: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print(#function, task, error ?? "nil")
    }
}

extension HTTPClientImpl: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print(#function)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = ByteCountFormatter.string(fromByteCount: Int64(totalBytesWritten), countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: Int64(totalBytesExpectedToWrite), countStyle: .file)
        print(#function, downloadTask, progress, total)
    }
}

extension HTTPClientImpl: HTTPClient {
    func head(url: URL) async throws -> URLResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let (_, response) = try await session.data(for: request)
        return response
    }
    
    func get(url: URL) async throws -> (Data, URLResponse) {
        let request = URLRequest(url: url)
        return try await session.data(for: request)
    }
    
    func multipart(url: URL, params: [String: Multipart]) async throws -> (Data, URLResponse) {
        let boundary = "--------" + UUID().uuidString
        var request = URLRequest(url: url)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try makeBody(params: params, boundary: boundary)
        return try await session.data(for: request)
    }
    
    func download(url: URL, progress: @escaping (Double) -> Void) async throws -> (URL, URLResponse) {
        let request = URLRequest(url: url)
        return try await session.download(for: request)
    }
}

private extension NSError {
    static let unknown = NSError(domain: "unknown error", code: -1)
}

#if canImport(FoundationNetworking)
extension URLSession {
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        try await withUnsafeThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                switch (data, response, error) {
                case (nil, nil, let error?):
                    continuation.resume(throwing: error)
                case (let data?, let response?, nil):
                    continuation.resume(returning: (data, response))
                default: fatalError("The data and response should be non-nil if there's no error!")
                }
            }
            
            task.resume()
        }
    }
    
    func download(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (URL, URLResponse) {
        try await withUnsafeThrowingContinuation { continuation in
            let task = downloadTask(with: request) { url, response, error in
                switch (url, response, error) {
                case (nil, nil, let error?):
                    continuation.resume(throwing: error)
                case (let url?, let response?, nil):
                    continuation.resume(returning: (url, response))
                default: fatalError("The url and response should be non-nil if there's no error!")
                }
            }
            
            task.resume()
        }
    }
}
#endif
