import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var isPlaying = false

    let onExpand: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            artwork

            VStack(alignment: .leading, spacing: 2) {
                Text("Mishary — Al-Fātiḥah")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)
                Text(isPlaying ? "Đang phát" : "Tạm dừng")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            Spacer(minLength: DesignTokens.Spacing.sm)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPlaying.toggle()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(accentColor)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onExpand) {
                Image(systemName: "chevron.up")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .background(
            ThemeManager.glassCard(
                cornerRadius: DesignTokens.CornerRadius.extraLarge,
                colorScheme: colorScheme
            )
        )
        .shadow(
            color: DesignTokens.Shadow.glass.color(for: colorScheme),
            radius: DesignTokens.Shadow.glass.radius,
            x: DesignTokens.Shadow.glass.x,
            y: DesignTokens.Shadow.glass.y
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onExpand)
    }

    private var artwork: some View {
        Circle()
            .fill(AngularGradient(
                gradient: Gradient(colors: [accentColor, accentColor.opacity(0.35), accentColor]),
                center: .center
            ))
            .frame(width: 56, height: 56)
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.5), lineWidth: 1)
                    .blendMode(.overlay)
            )
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: readerStore.selectedGradient, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: readerStore.selectedGradient, colorScheme: colorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: readerStore.selectedGradient, colorScheme: colorScheme)
    }
}

#Preview {
    MiniPlayerBar(onExpand: {})
        .padding()
        .background(Color.black)
        .environmentObject(ReaderStore())
}
