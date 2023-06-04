import Foundation

final class InstagramAPIImpl: InstagramAPI {
    let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func getReels(user: InstagramUser) async throws -> [InstagramReelItem] {
        let url = URL(string: "https://www.instagram.com/api/v1/feed/reels_media/?reel_ids=\(user.id)")!
        let (data, _) = try await client.get(url: url)
        let reel = try JSONDecoder().decode(InstagramReelResponse.self, from: data)
        return reel.reels_media.first?.items ?? []
    }
}
