import Foundation
import Logging

final class InstagramAPILogger: InstagramAPI {
    let decoratee: InstagramAPI
    let logger = Logger(label: "instagram")
    
    init(decoratee: InstagramAPI) {
        self.decoratee = decoratee
    }
    
    func getReels(user: InstagramUser) async throws -> [InstagramReelItem] {
        logger.info("async loading \(user.username)'s reels")
        let reels = try await decoratee.getReels(user: user)
        logger.info("got \(reels.count) \(user.username)'s reels")
        return reels
    }
}
