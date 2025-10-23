//
//  ImageCache.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 22.10.2025.
//

import UIKit

actor ImageCache {
    static let shared = ImageCache()
    private let mem = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let dir: URL
    private var inflight: [URL: Task<UIImage, Error>] = [:]
    
    init () {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        dir = base.appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        mem.countLimit = 228
    }
    
    private func diskURL(for url: URL) -> URL {
        dir.appendingPathComponent(String(url.absoluteString.hashValue))
    }
    
    func image(for url: URL) async throws -> UIImage {
        if let image = mem.object(forKey: url as NSURL) { return image }
        let diskURL = diskURL(for: url)
        if let data = try? Data(contentsOf: diskURL), let image = UIImage(data: data) {
            mem.setObject(image, forKey: url as NSURL)
            return image
        }
        if let running = inflight[url] { return try await running.value }
        let task = Task.detached { () throws -> UIImage in
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, resp) = try await URLSession.shared.data(for: request)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let img = await UIImage(data: data, scale: UIScreen.main.scale) else { throw APIError.decoding }
            try? data.write(to: diskURL, options: .atomic)
            return img
        }
        inflight[url] = task
        defer { inflight[url] = nil }
        let image = try await task.value
        mem.setObject(image, forKey: url as NSURL)
        return image
    }
    
    func preheat(_ urls: [URL]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = try await self.image(for: url)
                }
            }
            try await group.waitForAll()
        }
    }
}


/// TESTS ONLY!
#if DEBUG
extension ImageCache {
    /// Засеять кэш заранее закодированной картинкой для указанного URL (только для тестов)
    nonisolated static func testImage(_ color: UIColor = .red, size: CGSize = .init(width: 2, height: 2)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    func seed(image: UIImage, for url: URL) async {
        mem.setObject(image, forKey: url as NSURL)
    }
}
#endif
