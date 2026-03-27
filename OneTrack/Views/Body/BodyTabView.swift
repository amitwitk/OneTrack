import SwiftUI

struct BodyTabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange.opacity(0.5))
                Text("Body Measurements")
                    .font(.title3.bold())
                Text("Coming in Phase 3")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Track weight, waist, biceps, chest, and more")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer()
            }
            .navigationTitle("Body")
        }
    }
}
