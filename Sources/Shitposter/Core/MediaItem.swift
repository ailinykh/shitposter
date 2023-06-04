import Foundation
#if os(Linux)
import FoundationNetworking
#endif

struct MediaItem {
    let caption: String
    let date: Date
    let width: Int
    let height: Int
    let duration: Int?
    let size: Int64
    let type: String
    let fileName: String?
    let mimeType: String?
    let url: URL
    let thumb: Thumb
    
    func with(caption: String? = nil, size: Int64? = nil, fileName: String? = nil, mimeType: String? = nil, url: URL? = nil) -> MediaItem {
        MediaItem(
            caption: caption ?? self.caption,
            date: date,
            width: width,
            height: height,
            duration: duration,
            size: size ?? self.size,
            type: type,
            fileName: fileName ?? self.fileName,
            mimeType: mimeType ?? self.mimeType,
            url: url ?? self.url,
            thumb: thumb)
    }
}

struct Thumb {
    let width: Int
    let height: Int
    let url: URL
}

extension MediaItem {
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

protocol MediaItemDownloader {
    func download(items: [MediaItem]) async throws -> [(MediaItem, MediaFile, MediaFile)]
}

protocol MediaItemUploader {
    func upload(items: [(MediaItem, MediaFile, MediaFile)], url: URL) async throws -> (Data, URLResponse)
}
