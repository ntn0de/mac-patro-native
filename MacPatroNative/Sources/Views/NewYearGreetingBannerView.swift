import SwiftUI

public struct NewYearGreetingBannerView: View {
    let nepaliYearText: String
    let englishYearText: String
    let onDismiss: () -> Void

    public init(nepaliYearText: String, englishYearText: String, onDismiss: @escaping () -> Void) {
        self.nepaliYearText = nepaliYearText
        self.englishYearText = englishYearText
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Happy New Year \(englishYearText)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("नव वर्ष \(nepaliYearText) को शुभकामना")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .topTrailing) {
            ZStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.95, green: 0.7, blue: 0.15))
                    .offset(x: -2, y: 2)

                Circle()
                    .fill(Color(red: 0.2, green: 0.55, blue: 0.95))
                    .frame(width: 5, height: 5)
                    .offset(x: -18, y: 10)

                Circle()
                    .fill(Color(red: 0.9, green: 0.22, blue: 0.3))
                    .frame(width: 6, height: 6)
                    .offset(x: -8, y: 18)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.28, green: 0.72, blue: 0.42))
                    .frame(width: 10, height: 3)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -22, y: 20)
            }
            .padding(8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.18))
        )
    }
}

#Preview {
    NewYearGreetingBannerView(nepaliYearText: "२०८३", englishYearText: "2083") {}
        .padding()
        .frame(width: 320)
}
