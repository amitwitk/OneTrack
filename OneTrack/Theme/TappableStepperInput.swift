import SwiftUI

/// Reusable stepper with tappable number for direct keyboard entry.
/// Used in workout active view (reps, weight) and body tab (weight, measurements).
struct TappableStepperInput: View {
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    var decimals: Bool = false
    var format: String?
    var minWidth: CGFloat = 32
    var buttonSize: CGFloat = 28
    var buttonHeight: CGFloat = 32
    var spacing: CGFloat = 2
    var cornerRadius: CGFloat = 6

    @FocusState private var isEditing: Bool
    @State private var textValue = ""

    private var displayText: String {
        if let format {
            return String(format: format, value)
        }
        return decimals ? String(format: "%.1f", value) : "\(Int(value))"
    }

    var body: some View {
        HStack(spacing: spacing) {
            Button {
                isEditing = false
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus")
                    .font(.caption2.bold())
                    .frame(width: buttonSize, height: buttonHeight)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: cornerRadius))
            }
            .buttonStyle(.plain)

            ZStack {
                // Always-present TextField (hidden when not editing)
                TextField("", text: $textValue)
                    .keyboardType(.decimalPad)
                    .font(.subheadline.monospacedDigit().bold())
                    .multilineTextAlignment(.center)
                    .frame(minWidth: minWidth)
                    .focused($isEditing)
                    .opacity(isEditing ? 1 : 0)
                    .onChange(of: isEditing) {
                        if isEditing {
                            // Select all text so typing replaces the value
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                            }
                        } else {
                            commitEdit()
                        }
                    }

                // Display text (hidden when editing)
                if !isEditing {
                    Text(displayText)
                        .font(.subheadline.monospacedDigit().bold())
                        .frame(minWidth: minWidth)
                        .multilineTextAlignment(.center)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            textValue = displayText.replacingOccurrences(of: " kg", with: "").replacingOccurrences(of: " cm", with: "")
                            isEditing = true
                        }
                }
            }

            Button {
                isEditing = false
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus")
                    .font(.caption2.bold())
                    .frame(width: buttonSize, height: buttonHeight)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: cornerRadius))
            }
            .buttonStyle(.plain)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if isEditing {
                    Spacer()
                    Button("Done") {
                        isEditing = false
                    }
                }
            }
        }
    }

    private func commitEdit() {
        let cleaned = textValue
            .replacingOccurrences(of: " kg", with: "")
            .replacingOccurrences(of: " cm", with: "")
            .trimmingCharacters(in: .whitespaces)
        if let parsed = Double(cleaned) {
            value = min(range.upperBound, max(range.lowerBound, parsed))
        }
    }
}
