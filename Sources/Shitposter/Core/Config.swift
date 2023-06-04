import Foundation

struct Config: Codable {
    let token: String
    let cookies: [URL: [Cookie]]
    let headers: [String: String]
    let users: [InstagramUser]
    let chatId: String
}

extension Config {
    static var empty: Config {
        Config(
            token: "",
            cookies: [:],
            headers: headers,
            users: [],
            chatId: "")
    }
    
    private static var headers: [String: String] {
        [
            "user-agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
            "x-ig-app-id": "936619743392459"
        ]
    }
}
