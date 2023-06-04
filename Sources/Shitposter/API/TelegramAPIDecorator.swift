import Foundation

final class TelegramAPIDecorator {
    let primary: TelegramAPI
    let secondary: TelegramAPI
    let condition: (Error) -> Bool
    
    init(primary: TelegramAPI, secondary: TelegramAPI, condition: @escaping (Error) -> Bool) {
        self.primary = primary
        self.secondary = secondary
        self.condition = condition
    }
}

extension TelegramAPIDecorator: TelegramAPI {
    func post(items: [MediaItem], chatId: String) async throws -> TelegramResponse {
        do {
            return try await primary.post(items: items, chatId: chatId)
        } catch {
            if condition(error) {
                return try await secondary.post(items: items, chatId: chatId)
            } else {
                throw error
            }
        }
    }
}
