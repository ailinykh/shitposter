import Foundation

final class MediaItemDownloaderImpl: MediaItemDownloader {
    let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func download(items: [MediaItem]) async throws -> [(MediaItem, MediaFile, MediaFile)] {
        try await withThrowingTaskGroup(of: (MediaItem, MediaFile, MediaFile).self) { group in
            for item in items {
                group.addTask {
                    let (fileUrl, fileResponse) = try await self.client.download(url: item.url, progress: { _ in })
                    let file = MediaFile(
                        caption: item.caption,
                        type: item.type,
                        width: item.width,
                        height: item.height,
                        filename: fileResponse.suggestedFilename ?? item.url.lastPathComponent,
                        mime: fileResponse.mimeType ?? item.url.mimeType,
                        url: fileUrl)
                    let (thumbUrl, thumbResponse) = try await self.client.download(url: item.thumb.url, progress: { _ in })
                    let thumb = MediaFile(
                        caption: item.caption,
                        type: "photo",
                        width: item.thumb.width,
                        height: item.thumb.height,
                        filename: thumbResponse.suggestedFilename ?? item.thumb.url.lastPathComponent,
                        mime: thumbResponse.mimeType ?? item.thumb.url.mimeType,
                        url: thumbUrl)
                    return (item, file, thumb)
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
