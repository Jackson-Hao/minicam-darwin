import Foundation
import AppKit
import AVFoundation
import CoreMedia
import UniformTypeIdentifiers

final class MediaManager: ObservableObject {
    static let shared = MediaManager()
    
    @Published var lastCapturedImage: NSImage?
    @Published var lastCapturedURL: URL?
    
    private let picturesDirectory: URL
    private let moviesDirectory: URL
    
    private init() {
        let fileManager = FileManager.default
        let pictures = fileManager.urls(for: .picturesDirectory, in: .userDomainMask).first!
        let movies = fileManager.urls(for: .moviesDirectory, in: .userDomainMask).first!
        
        self.picturesDirectory = pictures.appendingPathComponent("MiniCam", isDirectory: true)
        self.moviesDirectory = movies.appendingPathComponent("MiniCam", isDirectory: true)
        
        try? fileManager.createDirectory(at: picturesDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: moviesDirectory, withIntermediateDirectories: true)
        
        loadLatestThumbnail()
    }
    
    func getNewPhotoURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return picturesDirectory.appendingPathComponent("MiniCam_\(timestamp).jpg")
    }
    
    func getNewMovieURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return moviesDirectory.appendingPathComponent("MiniCam_\(timestamp).mov")
    }
    
    func savePhoto(data: Data) -> URL? {
        let fileURL = getNewPhotoURL()
        do {
            try data.write(to: fileURL)
            DispatchQueue.main.async {
                self.lastCapturedURL = fileURL
                self.lastCapturedImage = NSImage(data: data)
            }
            return fileURL
        } catch {
            print("Failed to save photo: \(error)")
            return nil
        }
    }
    
    func updateLatestVideo(url: URL) {
        DispatchQueue.main.async {
            self.lastCapturedURL = url
            self.generateVideoThumbnail(url: url)
        }
    }
    
    private func generateVideoThumbnail(url: URL) {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var actualTime = CMTime.zero
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: &actualTime) {
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 80, height: 80))
                DispatchQueue.main.async {
                    self.lastCapturedImage = nsImage
                }
            }
        }
    }
    
    private func loadLatestThumbnail() {
        let fileManager = FileManager.default
        var allFiles: [URL] = []
        
        if let pics = try? fileManager.contentsOfDirectory(at: picturesDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) {
            allFiles.append(contentsOf: pics)
        }
        if let movs = try? fileManager.contentsOfDirectory(at: moviesDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) {
            allFiles.append(contentsOf: movs)
        }
        
        let sorted = allFiles.sorted { url1, url2 in
            let d1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            let d2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            return d1 > d2
        }
        
        if let latest = sorted.first {
            self.lastCapturedURL = latest
            if latest.pathExtension.lowercased() == "mov" || latest.pathExtension.lowercased() == "mp4" {
                generateVideoThumbnail(url: latest)
            } else if let image = NSImage(contentsOf: latest) {
                self.lastCapturedImage = image
            }
        }
    }
    
    func openInFinder(url: URL?) {
        if let target = url, FileManager.default.fileExists(atPath: target.path) {
            NSWorkspace.shared.activateFileViewerSelecting([target])
        } else {
            NSWorkspace.shared.open(picturesDirectory)
        }
    }
    
    func openSaveDirectory() {
        NSWorkspace.shared.open(picturesDirectory)
    }
}
