import SwiftUI
import SwiftData
import PhotosUI

struct ProgressPhotosView: View {
    @Query(sort: \ProgressPhoto.date, order: .reverse)
    private var photos: [ProgressPhoto]
    @Environment(\.modelContext) private var modelContext

    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedPhoto: ProgressPhoto?
    @State private var showCompare = false
    @State private var comparePhotos: [ProgressPhoto] = []
    @State private var isSelecting = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Actions
                HStack(spacing: 12) {
                    Button {
                        showPhotoLibrary = true
                    } label: {
                        Label("Add Photo", systemImage: "photo.badge.plus")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    if photos.count >= 2 {
                        Button {
                            isSelecting.toggle()
                            if !isSelecting { comparePhotos = [] }
                        } label: {
                            Label(isSelecting ? "Cancel" : "Compare", systemImage: isSelecting ? "xmark" : "square.split.2x1")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(.white)
                                .background(isSelecting ? Color.gray : Color.orange, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                if photos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "camera")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("No progress photos yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // Thumbnail grid
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(photos) { photo in
                            photoThumbnail(photo)
                        }
                    }
                    .padding(.horizontal)
                }

                if isSelecting && comparePhotos.count == 2 {
                    Button {
                        showCompare = true
                    } label: {
                        Label("Compare Selected", systemImage: "arrow.left.and.right")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.orange, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Progress Photos")
        .sheet(isPresented: $showPhotoLibrary) {
            PhotoPickerWrapper { image in
                savePhoto(image)
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            NavigationStack {
                PhotoDetailView(photo: photo)
            }
        }
        .sheet(isPresented: $showCompare) {
            if comparePhotos.count == 2 {
                NavigationStack {
                    PhotoCompareView(photo1: comparePhotos[0], photo2: comparePhotos[1])
                }
            }
        }
    }

    private func photoThumbnail(_ photo: ProgressPhoto) -> some View {
        let isSelected = comparePhotos.contains(where: { $0.id == photo.id })

        return Button {
            if isSelecting {
                if isSelected {
                    comparePhotos.removeAll { $0.id == photo.id }
                } else if comparePhotos.count < 2 {
                    comparePhotos.append(photo)
                }
            } else {
                selectedPhoto = photo
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let image = PhotoStorageManager.load(filename: photo.filename) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .frame(height: 120)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.tertiary)
                        }
                }

                Text(photo.date.shortDate)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.orange, lineWidth: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deletePhoto(photo)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func savePhoto(_ image: UIImage) {
        guard let filename = PhotoStorageManager.save(image: image) else { return }
        let photo = ProgressPhoto(filename: filename)
        modelContext.insert(photo)
        try? modelContext.save()
    }

    private func deletePhoto(_ photo: ProgressPhoto) {
        PhotoStorageManager.delete(filename: photo.filename)
        modelContext.delete(photo)
        try? modelContext.save()
    }
}

// MARK: - Photo Detail

private struct PhotoDetailView: View {
    let photo: ProgressPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            if let image = PhotoStorageManager.load(filename: photo.filename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }

            VStack(spacing: 4) {
                Text(photo.date.shortDateTime)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let weight = photo.weightKg {
                    Text(weight.formattedWeight)
                        .font(.headline)
                }
                if !photo.notes.isEmpty {
                    Text(photo.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .navigationTitle("Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - Photo Picker Wrapper

struct PhotoPickerWrapper: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage) -> Void
        init(onPick: @escaping (UIImage) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let image = image as? UIImage {
                    DispatchQueue.main.async { self.onPick(image) }
                }
            }
        }
    }
}
