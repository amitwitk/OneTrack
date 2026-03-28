import Testing
import Foundation
import UIKit
@testable import OneTrack

@Suite("Photo Storage")
struct PhotoStorageTests {

    @Test func saveAndLoad_roundTrips() {
        let image = UIImage(systemName: "photo")!
        guard let filename = PhotoStorageManager.save(image: image) else {
            Issue.record("Failed to save image")
            return
        }
        let loaded = PhotoStorageManager.load(filename: filename)
        #expect(loaded != nil)
        // Cleanup
        PhotoStorageManager.delete(filename: filename)
    }

    @Test func delete_removesFile() {
        let image = UIImage(systemName: "photo")!
        guard let filename = PhotoStorageManager.save(image: image) else {
            Issue.record("Failed to save image")
            return
        }
        PhotoStorageManager.delete(filename: filename)
        let loaded = PhotoStorageManager.load(filename: filename)
        #expect(loaded == nil)
    }

    @Test func load_nonexistentFile() {
        let loaded = PhotoStorageManager.load(filename: "nonexistent.jpg")
        #expect(loaded == nil)
    }

    @Test func url_constructsCorrectly() {
        let url = PhotoStorageManager.url(for: "test.jpg")
        #expect(url.lastPathComponent == "test.jpg")
        #expect(url.pathComponents.contains("progress_photos"))
    }
}
