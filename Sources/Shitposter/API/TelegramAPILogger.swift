import Foundation
import Logging

final class TelegramAPILogger: TelegramAPI {
    let decoratee: TelegramAPI
    let logger = Logger(label: "telegram")
    
    init(decoratee: TelegramAPI) {
        self.decoratee = decoratee
    }
    
    func post(items: [MediaItem], chatId: String) async throws -> TelegramResponse {
        logger.info("posting \(items.count) items to \(chatId)")
        let result = try await decoratee.post(items: items, chatId: chatId)
        logger.info("successfully posted \(result.result?.count ?? 0) messages to chat_id: \(chatId)")
        return result
    }
}
