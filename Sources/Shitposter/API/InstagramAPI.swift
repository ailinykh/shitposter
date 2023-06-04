import Foundation

struct InstagramUser: Codable {
    let id: String
    let username: String
}

struct InstagramReelResponse: Decodable {
    let reels_media: [InstagramReelsMedia]
}

struct InstagramReelsMedia: Decodable {
    let items: [InstagramReelItem]
}

struct InstagramReelItem: Decodable {
    let code: String
    let taken_at: Double
    let image_versions2: InstagramReelItemImageVersions
    let video_duration: Double?
    let video_versions: [InstagramReelItemVideo]?
    let original_width: Int
    let original_height: Int
    let story_bloks_stickers: [InstagramReelItemStickers]?
}

struct InstagramReelItemVideo: Decodable {
    let width: Int
    let height: Int
    let url: URL
}

struct InstagramReelItemImage: Decodable {
    let width: Int
    let height: Int
    let url: URL
}

struct InstagramReelItemImageVersions: Decodable {
    let candidates: [InstagramReelItemImage]
}

struct InstagramReelItemStickers: Decodable {
    let bloks_sticker: InstagramReelItemSticker
}

struct InstagramReelItemSticker: Decodable {
    let sticker_data: InstagramReelItemStickerData
    let bloks_sticker_type: String
}

struct InstagramReelItemStickerData: Decodable {
    let ig_mention: InstagramReelItemStickerDataMention?
}

struct InstagramReelItemStickerDataMention: Decodable {
    let account_id: String
    let username: String
    let full_name: String
    let profile_pic_url: URL
}

protocol InstagramAPI {
    func getReels(user: InstagramUser) async throws -> [InstagramReelItem]
}
