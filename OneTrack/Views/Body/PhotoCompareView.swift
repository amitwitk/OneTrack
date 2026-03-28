import SwiftUI

struct PhotoCompareView: View {
    let photo1: ProgressPhoto
    let photo2: ProgressPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                photoPanel(photo1)
                photoPanel(photo2)
            }

            // Info bar
            HStack(spacing: 0) {
                infoLabel(photo1)
                Divider().frame(height: 40)
                infoLabel(photo2)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func photoPanel(_ photo: ProgressPhoto) -> some View {
        Group {
            if let image = PhotoStorageManager.load(filename: photo.filename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }
        }
    }

    private func infoLabel(_ photo: ProgressPhoto) -> some View {
        VStack(spacing: 2) {
            Text(photo.date.shortDate)
                .font(.caption.bold())
            if let weight = photo.weightKg {
                Text(weight.formattedWeight)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
