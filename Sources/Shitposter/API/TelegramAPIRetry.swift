import Foundation

final class TelegramAPIRetry: TelegramAPI {
    let decoratee: TelegramAPI
    
    init(decoratee: TelegramAPI) {
        self.decoratee = decoratee
    }
    
    func post(items: [MediaItem], chatId: String) async throws -> TelegramResponse {
        do {
            return try await decoratee.post(items: items, chatId: chatId)
        } catch {
            if let timeout = (error as NSError).userInfo["retry_after"] as? Int {
                print("❌ \(timeout) seconds timeout")
                try await Task.sleep(nanoseconds: UInt64(timeout) * 1_000_000_000)
                return try await post(items: items, chatId: chatId)
            } else {
                throw error
            }
        }
    }
}
