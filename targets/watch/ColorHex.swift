import SwiftUI

extension Color {
    /// Builds a colour from `#RRGGBB` or `#RGB`. Anything else gives a neutral
    /// grey, so a subject without a valid colour still gets drawn.
    init(hex: String?) {
        var digits = (hex ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if digits.hasPrefix("#") {
            digits.removeFirst()
        }
        if digits.count == 3 {
            digits = digits.map { "\($0)\($0)" }.joined()
        }
        let value = digits.count == 6 ? UInt32(digits, radix: 16) : nil
        let rgb = value ?? 0x8E8E93

        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: 1
        )
    }
}
