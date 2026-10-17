import SwiftUI

/// Small coloured pill: "Cancelled", "Now", "Test"...
struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.4)))
    }
}

/// The tinted card drawn behind a list row.
struct RowBackground: View {
    let tint: Color
    var emphasised = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(tint.opacity(emphasised ? 0.4 : 0.2))
    }
}

/// Shown instead of a list when there is nothing to list.
struct Placeholder: View {
    let symbol: String
    let text: String
    let footnote: String?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.footnote)
                .multilineTextAlignment(.center)

            if let footnote = footnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

/// Last row of a list: when the data was sent by the phone.
struct SyncFooter: View {
    let label: String?

    var body: some View {
        if let label = label {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
        }
    }
}
