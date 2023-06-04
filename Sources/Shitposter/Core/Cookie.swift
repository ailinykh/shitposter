import Foundation

struct Cookie: Codable {
    let domain: String
    let path: String
    let name: String
    let value: String
}
