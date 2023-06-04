import Foundation
#if os(Linux)
import FoundationNetworking
#endif

final class TelegramItemUploader {
    let client: HTTPClient
    init(client: HTTPClient) {
        self.client = client
    }
}

extension TelegramItemUploader: MediaItemUploader {
    func upload(items: [(MediaItem, MediaFile, MediaFile)], url: URL) async throws -> (Data, URLResponse) {
        var requests = [TelegramMediaRequest]()
        var params = [String: Multipart]()
        
        for (i, (item, file, thumb)) in items.enumerated() {
            requests.append(TelegramMediaRequest(
                caption: item.caption,
                duration: 0,
                media: "attach://video\(i)",
                width: file.width,
                height: file.height,
                type: file.type,
                thumbnail: "attach://thumb\(i)"))
            params["video\(i)"] = .file((file.filename, file.mime, file.url))
            params["thumb\(i)"] = .file((thumb.filename, thumb.mime, thumb.url))
        }
        let request = try! JSONEncoder().encode(requests)
        
//        params["chat_id"] = .data(chatId.data(using: .utf8)!)
        params["media"] = .data(request)
        
//        let url = URL(string: "https://api.telegram.org/bot\(token)/sendMediaGroup")!
        return try await client.multipart(url: url, params: params)
    }
}
