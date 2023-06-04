import Foundation

protocol MediaConsumer {
    func post(items: [MediaItem], completion: @escaping (Result<Bool, Error>) -> Void)
}
