import Foundation

extension Array where Element == InstagramReelItem {
    var mediaItems: [MediaItem] {
        map { $0.mediaItem }
    }
}

private extension InstagramReelItem {
    var caption: String {
        guard let stickers = story_bloks_stickers else { return "" }
        return stickers
            .compactMap({ $0.bloks_sticker.sticker_data.ig_mention })
            .map({ "https://instagr.am/\($0.username)" })
            .joined(separator: "\n")
    }
    
    var url: URL {
        video_versions != nil ? video_versions![0].url : image_versions2.candidates[0].url
    }
    
    var type: String {
        video_versions != nil ? "video" : "photo"
    }
    
    var duration: Int? {
        video_duration != nil ? Int(video_duration!) : nil
    }
    
    var thumb: Thumb {
        Thumb(
            width: image_versions2.candidates[0].width,
            height: image_versions2.candidates[0].height,
            url: image_versions2.candidates[0].url)
    }
    
    var mediaItem: MediaItem {
        MediaItem(
            caption: caption,
            date: Date(timeIntervalSince1970: taken_at),
            width: original_width,
            height: original_height,
            duration: duration,
            size: 0,
            type: type,
            fileName: nil,
            mimeType: nil,
            url: url,
            thumb: thumb
        )
    }
}
