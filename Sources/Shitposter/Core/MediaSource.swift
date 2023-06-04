import Foundation

protocol MediaSource {
    func get(completion: @escaping (Result<[MediaItem], Error>) -> Void)
}
