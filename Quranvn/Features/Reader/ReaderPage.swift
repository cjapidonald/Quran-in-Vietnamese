import SwiftUI

struct ReaderPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ThemeManager.backgroundGradient(style: appState.selectedThemeGradient, for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                        header
                        actionButtons
                        currentLayoutPreview
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.top, DesignTokens.Spacing.xl)
                    .padding(.bottom, appState.showMiniPlayer ? 120 : DesignTokens.Spacing.xl)
                }

                if appState.showMiniPlayer {
                    MiniPlayerPlaceholder()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                        .padding(.bottom, DesignTokens.Spacing.lg)
                }
            }
            .navigationDestination(isPresented: $appState.showSurahDashboard) {
                SurahDashboardPlaceholder()
            }
        }
        .tint(accentColor)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Read")
                .font(.largeTitle.bold())
                .foregroundStyle(primaryText)
            Text("Quick actions for the reader experience")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            PrimaryButton(
                title: "Open Surah",
                subtitle: "Navigate to a placeholder Surah dashboard",
                icon: "book",
                theme: appState.selectedThemeGradient
            ) {
                appState.showSurahDashboard = true
            }

            PrimaryButton(
                title: appState.isReaderFullScreen ? "Exit Full Screen" : "Enter Full Screen",
                subtitle: appState.isReaderFullScreen ? "Showing immersive layout" : "Showing standard layout",
                icon: "arrow.up.left.and.arrow.down.right",
                theme: appState.selectedThemeGradient
            ) {
                withAnimation { appState.isReaderFullScreen.toggle() }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Switch Languages")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(ReaderLanguage.allCases) { option in
                        SegmentPill(
                            title: option.displayTitle,
                            isSelected: option == appState.selectedReaderLanguage,
                            theme: appState.selectedThemeGradient
                        ) {
                            withAnimation(.easeInOut) {
                                appState.selectedReaderLanguage = option
                            }
                        }
                    }
                }
            }

            PrimaryButton(
                title: appState.showMiniPlayer ? "Hide Mini Player" : "Show Mini Player",
                subtitle: "Reveal a mock playback bar",
                icon: "play.rectangle.on.rectangle",
                theme: appState.selectedThemeGradient
            ) {
                withAnimation(.spring) { appState.showMiniPlayer.toggle() }
            }
        }
    }

    private var currentLayoutPreview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(primaryText)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if appState.isReaderFullScreen {
                    Text("Full Screen Reader")
                        .font(.title3.bold())
                        .foregroundStyle(primaryText)
                    Text("Immersive mode hides navigation chrome and focuses on verses.")
                        .foregroundStyle(secondaryText)
                } else {
                    Text("Standard Reader Layout")
                        .font(.title3.bold())
                        .foregroundStyle(primaryText)
                    Text("Shows header, controls, and translation side panels.")
                        .foregroundStyle(secondaryText)
                }

                Text("Language: \(appState.selectedReaderLanguage.displayTitle)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(secondaryText)
                    .padding(.top, DesignTokens.Spacing.sm)
            }
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
        }
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }
}

private struct SurahDashboardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("Surah Dashboard")
                .font(.largeTitle.bold())
            Text("This is where detailed Surah content will appear.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
}

private struct MiniPlayerPlaceholder: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        ThemeManager.accentColor(for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .fill(accentColor)
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "play.fill").foregroundStyle(Color.white))

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Mini Player")
                    .font(.headline)
                    .foregroundStyle(ThemeManager.semanticColor(.primary, for: appState.selectedThemeGradient, colorScheme: colorScheme))
                Text("Placeholder playback controls")
                    .font(.caption)
                    .foregroundStyle(ThemeManager.semanticColor(.secondary, for: appState.selectedThemeGradient, colorScheme: colorScheme))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "forward.end.fill")
                    .font(.title3)
                    .foregroundStyle(accentColor)
            }
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.large)
    }
}

#Preview {
    ReaderPage()
        .environmentObject(AppState())
}
