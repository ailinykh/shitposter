import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element == MediaItem {
    func headed(client: HTTPClient) async throws -> Self {
        try await withThrowingTaskGroup(of: MediaItem.self) { group in
            for item in self {
                group.addTask {
                    let response = try await client.head(url: item.url)
                    return item.with(
                        size: response.expectedContentLength,
                        fileName: response.suggestedFilename,
                        url: response.url)
                }
            }
            
            var items = [MediaItem]()
            
            for try await item in group {
                items.append(item)
            }
            
            return items
        }
    }
}
