import SwiftUI

struct ActivityTabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red.opacity(0.5))
                Text("Activity")
                    .font(.title3.bold())
                Text("Coming in Phase 3")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Steps, active calories, and workouts from Apple Health")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer()
            }
            .navigationTitle("Activity")
        }
    }
}
