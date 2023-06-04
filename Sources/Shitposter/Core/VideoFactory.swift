import Foundation

struct VideoFile {
    let duration: Double
    let width: Int
    let height: Int
    let url: URL
}

struct FFProbeResponse: Decodable {
    struct Stream: Decodable {
        let codec_name: String
        let codec_type: String
        let width: Int?
        let height: Int?
    }
    
    struct Format: Decodable {
        let filename: URL
        let nb_streams: Int
        let bit_rate: String
        let duration: String
        let size: String
    }
    
    let streams: [Stream]
    let format: Format
}

protocol VideoFactory {
    func make(url: URL, completion: @escaping (Result<VideoFile, Error>) -> Void)
    func resize(url: URL, width: Int, height: Int, ext: String) async throws -> URL
}
