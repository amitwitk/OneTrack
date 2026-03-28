import Foundation
import UIKit

struct PhotoStorageManager {
    private static var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("progress_photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Saves a UIImage as JPEG and returns the filename.
    static func save(image: UIImage, compression: CGFloat = 0.8) -> String? {
        guard let data = image.jpegData(compressionQuality: compression) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let url = photosDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }

    /// Loads a UIImage from a filename.
    static func load(filename: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Deletes a photo by filename.
    static func delete(filename: String) {
        let url = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    /// Full URL for a filename.
    static func url(for filename: String) -> URL {
        photosDirectory.appendingPathComponent(filename)
    }
}
