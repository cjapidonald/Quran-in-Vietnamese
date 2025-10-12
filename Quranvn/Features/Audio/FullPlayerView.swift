import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var isPlaying = false

    var body: some View {
        ZStack {
            ThemeManager.backgroundGradient(style: readerStore.selectedGradient, for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxl) {
                    artwork

                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("Mishary — Al-Fātiḥah")
                            .font(.title.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(primaryText)

                        Text("Placeholder recitation UI")
                            .font(.callout)
                            .foregroundStyle(secondaryText)
                    }

                    playbackProgress

                    playbackControls

                    Spacer(minLength: DesignTokens.Spacing.xl)
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.top, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Now Playing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
    }

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge * 2, style: .continuous)
                .fill(AngularGradient(
                    gradient: Gradient(colors: [accentColor, accentColor.opacity(0.25), accentColor]),
                    center: .center
                ))
                .frame(height: 320)

            Circle()
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.4), lineWidth: 6)
                .frame(width: 180, height: 180)
                .blendMode(.screen)
        }
        .shadow(color: DesignTokens.Shadow.glass.color(for: colorScheme), radius: 24, x: 0, y: 18)
    }

    private var playbackProgress: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Slider(value: .constant(0.25))
                .disabled(true)
                .tint(accentColor)

            HStack {
                Text("00:32")
                Spacer()
                Text("03:21")
            }
            .font(.caption)
            .foregroundStyle(secondaryText)
        }
    }

    private var playbackControls: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            Button(action: {}) {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundStyle(primaryText)
                    .frame(width: 56, height: 56)
                    .background(controlBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPlaying.toggle()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(Color.white)
                    .frame(width: 76, height: 76)
                    .background(accentColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button(action: {}) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(primaryText)
                    .frame(width: 56, height: 56)
                    .background(controlBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.semibold))
            }
        }
    }

    private var controlBackground: some View {
        Circle()
            .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2))
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4), lineWidth: 1)
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
    NavigationStack {
        FullPlayerView()
            .environmentObject(ReaderStore())
    }
}
