import Foundation

struct TelegramMedia: Codable {
    let caption: String?
    let media: URL
    let type: String
    let width: Int?
    let height: Int?
    let duration: Int?
}

struct TelegramResponse: Decodable {
    let ok: Bool
    let error_code: Int?
    let description: String?
    let parameters: TelegramResponseParams?
    let result: [TelegramMessage]?
}

struct TelegramResponseParams: Decodable {
    let retry_after: Int?
}

struct TelegramMessage: Decodable {
    let message_id: Int
    let from: TelegramUser
    let chat: TelegramChat
    let date: Int
    let photo: [TelegramPhoto]?
    let video: TelegramVideo?
    let caption: String?
}

struct TelegramUser: Decodable {
    let id: Int
    let is_bot: Bool
    let first_name: String?
    let username: String?
    // TODO: more fields
}

struct TelegramChat: Decodable {
    let id: Int
    let type: String
    // TODO: more fields
}

struct TelegramPhoto: Decodable {
    let file_id: String
    let file_unique_id: String
    let file_size: Int
    let width: Int
    let height: Int
}

struct TelegramVideo: Decodable {
    let file_name: String
    let mime_type: String
    let file_id: String
    let file_unique_id: String
    let file_size: Int
    let width: Int
    let height: Int
    let thumbnail: TelegramPhoto
}

struct TelegramMediaRequest: Codable {
    let caption: String?
    let duration: Int
    let media: String
    let width: Int
    let height: Int
    let type: String
    let thumbnail: String
}

protocol TelegramAPI {
    func post(items: [MediaItem], chatId: String) async throws -> TelegramResponse
}
