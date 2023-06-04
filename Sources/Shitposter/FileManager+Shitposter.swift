import Foundation

extension FileManager {
    func tmpUrl(with ext: String = "tmp") -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString + "." + ext)
    }
}
