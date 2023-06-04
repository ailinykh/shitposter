import Foundation

@main
public struct Shitposter {
    public static func main() async {
        do {
            try await doJob(
                config: config()
            )
        } catch {
            print(error)
        }
    }

    private static func config(arguments: [String] = CommandLine.arguments) -> Config {
        print(arguments)
        if let configPath = arguments.last, let url = URL(string: configPath) {
            do {
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode(Config.self, from: data)
                return config
            } catch {
                print("config reading failed: \(error)")
            }
        }
        return .empty
    }
    
    private static func doJob(config: Config) async throws {
        let session = HTTPClientFactory.makeSession(cookies: config.cookies, additionalHeaders: config.headers)
        let client = HTTPClientFactory.makeHTTPClient(session: session)
        
        let downloader = MediaItemDownloaderImpl(client: client)
        let uploader = TelegramItemUploader(client: client)
        let resizer = MediaItemResizer(decoratee: downloader, factory: VideoFactoryImpl())
        
        let telegramApiImpl = TelegramAPIImpl(client: client, token: config.token)
            .logged
        let telegramApiDownloader = TelegramAPIDownloader(
            client: client,
            dowloader: resizer,
            uploader: uploader,
            token: config.token)
        let telegramApi = telegramApiImpl
            .fallback(to: telegramApiDownloader) { ($0 as NSError).code == 400 }
            .fallback(to: telegramApiImpl) { error in
                print(error)
                guard let timeout = (error as NSError).userInfo["retry_after"] as? Int else { return false }
                print("❌ \(timeout) seconds timeout")
                Thread.sleep(forTimeInterval: Double(timeout))
                return true
            }
        
        let instagramApi = InstagramAPILogger(decoratee: InstagramAPIImpl(client: client))
        
        for user in config.users {
            let reels = try await instagramApi.getReels(user: user)
            let items = reels
                .mediaItems
                .chunked(into: 10)
            
            for (part, items) in items.enumerated() {
                print(user.username, "part:", part, "items:", items.count)
                var captions = [String]()
                var items = items.map {
                    $0.caption.split(separator: "\n").forEach({ captions.append(String($0)) })
                    return $0.with(caption: nil)
                }
                captions.append("https://instagr.am/\(user.username)")
                if let last = items.popLast() {
                    items.append(last.with(caption: captions.joined(separator: "\n")))
                }
                
                
                items.forEach {
                    print($0.date, $0.duration ?? "it's a photo", $0.caption)
                }
                
                let result = try await telegramApi.post(items: items, chatId: config.chatId)
                print(user.username, "ok:", result.result?.map({ $0.photo != nil ? "photo" : $0.video != nil ? "video" : "no media" }) ?? "nil")
            }
        }
    }
}
