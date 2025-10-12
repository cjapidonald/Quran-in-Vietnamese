import SwiftUI

struct ReaderPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ThemeManager.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Read")
                .font(.largeTitle.bold())
            Text("Quick actions for the reader experience")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Button(action: { appState.showSurahDashboard = true }) {
                StubButtonLabel(title: "Open Surah", subtitle: "Navigate to a placeholder Surah dashboard")
            }

            Button(action: { withAnimation { appState.isReaderFullScreen.toggle() } }) {
                StubButtonLabel(title: "Toggle Full Screen", subtitle: appState.isReaderFullScreen ? "Showing immersive layout" : "Showing standard layout")
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Switch Languages")
                    .font(.headline)
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(ReaderLanguage.allCases) { option in
                        Button(option.displayTitle) {
                            withAnimation(.easeInOut) {
                                appState.selectedReaderLanguage = option
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(option == appState.selectedReaderLanguage ? ThemeManager.accentColor(for: colorScheme) : ThemeManager.cardBackground(for: colorScheme).opacity(0.6))
                        .foregroundStyle(option == appState.selectedReaderLanguage ? Color.white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous))
                    }
                }
            }

            Button(action: { withAnimation(.spring) { appState.showMiniPlayer.toggle() } }) {
                StubButtonLabel(title: appState.showMiniPlayer ? "Hide Mini Player" : "Show Mini Player", subtitle: "Reveal a mock playback bar")
            }
        }
    }

    private var currentLayoutPreview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Preview")
                .font(.headline)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if appState.isReaderFullScreen {
                    Text("Full Screen Reader")
                        .font(.title3.bold())
                    Text("Immersive mode hides navigation chrome and focuses on verses.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Standard Reader Layout")
                        .font(.title3.bold())
                    Text("Shows header, controls, and translation side panels.")
                        .foregroundStyle(.secondary)
                }

                Text("Language: \(appState.selectedReaderLanguage.displayTitle)")
                    .font(.footnote.weight(.medium))
                    .padding(.top, DesignTokens.Spacing.sm)
            }
            .padding(DesignTokens.Spacing.lg)
            .background(ThemeManager.cardBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : DesignTokens.Shadow.subtle.opacity), radius: DesignTokens.Shadow.subtle.radius, x: DesignTokens.Shadow.subtle.x, y: DesignTokens.Shadow.subtle.y)
        }
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .fill(ThemeManager.accentColor(for: colorScheme))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "play.fill").foregroundStyle(Color.white))

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Mini Player")
                    .font(.headline)
                Text("Placeholder playback controls")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "forward.end.fill")
                    .font(.title3)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(ThemeManager.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.12), radius: DesignTokens.Shadow.medium.radius, x: DesignTokens.Shadow.medium.x, y: DesignTokens.Shadow.medium.y)
    }
}

#Preview {
    ReaderPage()
        .environmentObject(AppState())
}
