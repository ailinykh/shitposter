import Foundation

final class MediaItemResizer: MediaItemDownloader {
    let decoratee: MediaItemDownloader
    let factory: VideoFactory
    
    init(decoratee: MediaItemDownloader, factory: VideoFactory) {
        self.decoratee = decoratee
        self.factory = factory
    }
    
    func download(items: [MediaItem]) async throws -> [(MediaItem, MediaFile, MediaFile)] {
        let items = try await decoratee.download(items: items)
        return try await resize(items: items)
    }
    
    private func resize(items: [(MediaItem, MediaFile, MediaFile)]) async throws -> [(MediaItem, MediaFile, MediaFile)] {
        try await withThrowingTaskGroup(of: (MediaItem, MediaFile, MediaFile).self) { group in
            let factory = VideoFactoryImpl()
            for item in items {
                group.addTask {
                    let size: (Int, Int) = item.0.thumb.width > item.0.thumb.height ? (320, -1) : (-1, 320)
                    let url = try await factory.resize(url: item.2.url, width: size.0, height: size.1, ext: "jpg")
                    let resized = MediaFile(
                        caption: nil,
                        type: "photo",
                        width: size.0,
                        height: size.1,
                        filename: item.2.filename,
                        mime: item.2.mime,
                        url: url)
                    return (item.0, item.1, resized)
                }
            }
            
            var items = [(MediaItem, MediaFile, MediaFile)]()
            
            for try await item in group {
                items.append(item)
            }
            
            return items
        }
    }
}
