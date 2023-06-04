import Foundation
import Logging

final class VideoFactoryImpl {
    let logger = Logger(label: "ffmpeg")
    let queue = DispatchQueue(label: "com.ailinykh.shitposter.video-factory-queue")
}

extension VideoFactoryImpl: VideoFactory {
    func make(url: URL, completion: @escaping (Result<VideoFile, Error>) -> Void) {
        queue.async {
            do {
                let data = try self.run(command: "ffprobe -v error -of json -show_streams -show_format \(url.path)")
//                let output = String(data: data, encoding: .utf8)!
//                print(output)
                
                let decoder = JSONDecoder()
                let response = try decoder.decode(FFProbeResponse.self, from: data)
                
                guard let videoStream = response.streams.first(where: { $0.codec_type == "video" }) else {
                    completion(.failure(NSError(domain: "ffprobe: no video stream found", code: -1)))
                    return
                }
                
                let video = VideoFile(
                    duration: Double(response.format.duration) ?? 0,
                    width: videoStream.width ?? 0,
                    height: videoStream.height ?? 0,
                    url: url)
                completion(.success(video))
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - async
    
    func resize(url: URL, width: Int, height: Int, ext: String) async throws -> URL {
        let tmp = FileManager.default.tmpUrl(with: ext)
        let data = try run(command: "ffmpeg -v error -y -i \(url.path) -vf scale=\(width):\(height) \(tmp.path)")
        let output = String(data: data, encoding: .utf8)!
        
        guard output.isEmpty else {
            let output = output.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.error("expected empty ouput, got: \(output)")
            throw NSError(domain: "ffmpeg: failed to resize to \(width)x\(height) \(ext)", code: -1)
        }
        
        return tmp
    }
    
    // MARK: - private
    
    private func run(command: String) throws -> Data {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.standardInput = nil
        
        try task.run()
        
        return pipe.fileHandleForReading.readDataToEndOfFile()
    }
}
