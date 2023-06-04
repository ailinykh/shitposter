import Foundation

final class TelegramAPIDownloader {
    let client: HTTPClient
    let dowloader: MediaItemDownloader
    let uploader: MediaItemUploader
    let token: String
    
    init(client: HTTPClient, dowloader: MediaItemDownloader, uploader: MediaItemUploader, token: String) {
        self.client = client
        self.dowloader = dowloader
        self.uploader = uploader
        self.token = token
    }
}

extension TelegramAPIDownloader: TelegramAPI {
    func post(items: [MediaItem], chatId: String) async throws -> TelegramResponse {
        let items = try await items.headed(client: client)
        items.forEach { print($0.fileName ?? "nil", $0.formattedSize) }
        let resized = try await dowloader.download(items: items)
            .sorted(by: { $0.0.date < $1.0.date })
        
        let url = URL(string: "https://api.telegram.org/bot\(token)/sendMediaGroup?chat_id=\(chatId)")!
        let (data, _) = try await uploader.upload(items: resized, url: url)
        return try JSONDecoder().decode(TelegramResponse.self, from: data)
    }
}
