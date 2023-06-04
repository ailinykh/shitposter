import Foundation

final class TelegramAPIImpl: TelegramAPI {
    let client: HTTPClient
    let token: String
    
    init(client: HTTPClient, token: String) {
        self.client = client
        self.token = token
    }
    
    func post(items: [MediaItem], chatId: String) async throws -> TelegramResponse {
        let url = URL(string: "https://api.telegram.org/bot\(token)/sendMediaGroup")!
        let data = try JSONEncoder().encode(items.map({
            TelegramMedia(
                caption: $0.caption,
                media: $0.url,
                type: $0.type,
                width: $0.type == "video" ? $0.width : nil,
                height: $0.type == "video" ? $0.height : nil,
                duration: $0.type == "video" ? $0.duration : nil
            )
        }))
        let params: [String: Multipart] = [
            "chat_id": .data(chatId.data(using: .utf8)!),
            "media": .data(data)
        ]
        let result = try await client.multipart(url: url, params: params)
        let response = try JSONDecoder().decode(TelegramResponse.self, from: result.0)
        if let code = response.error_code, let description = response.description {
            print(String(data: result.0, encoding: .utf8) ?? "nil")
            var userInfo: [String: Any] = ["description": description]
            if let timeout = response.parameters?.retry_after {
                userInfo["retry_after"] = timeout
            }
            throw NSError(domain: "telegram", code: code, userInfo: userInfo)
        }
        return response
    }
}
