import SwiftUI

struct ReaderPage: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var isShowingFullPlayer = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ThemeManager.backgroundGradient(style: readerStore.selectedGradient, for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                        header
                        actionButtons
                        currentLayoutPreview
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.top, DesignTokens.Spacing.xl)
                    .padding(.bottom, appState.isMiniPlayerVisible ? 120 : DesignTokens.Spacing.xl)
                }

                if appState.isMiniPlayerVisible {
                    MiniPlayerBar {
                        isShowingFullPlayer = true
                    }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                        .padding(.bottom, DesignTokens.Spacing.lg)
                }
            }
            .navigationDestination(isPresented: $appState.showSurahDashboard) {
                ReaderDashboardView(
                    initialSurah: appState.pendingReaderDestination?.surah,
                    initialAyah: appState.pendingReaderDestination?.ayah
                )
                .onAppear {
                    appState.pendingReaderDestination = nil
                }
            }
            .navigationDestination(isPresented: $isShowingFullPlayer) {
                FullPlayerView()
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
                theme: readerStore.selectedGradient
            ) {
                appState.showSurahDashboard = true
            }

            PrimaryButton(
                title: readerStore.isFullScreen ? "Exit Full Screen" : "Enter Full Screen",
                subtitle: readerStore.isFullScreen ? "Showing immersive layout" : "Showing standard layout",
                icon: "arrow.up.left.and.arrow.down.right",
                theme: readerStore.selectedGradient
            ) {
                withAnimation { readerStore.toggleFullScreen() }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Switch Languages")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(ReaderLanguage.allCases) { option in
                        SegmentPill(
                            title: option.displayTitle,
                            isSelected: readerStore.isLanguageEnabled(option),
                            theme: readerStore.selectedGradient
                        ) {
                            withAnimation(.easeInOut) {
                                readerStore.toggleLanguage(option)
                            }
                        }
                    }
                }
            }

            PrimaryButton(
                title: appState.isMiniPlayerVisible ? "Hide Mini Player" : "Show Mini Player",
                subtitle: "Reveal a mock playback bar",
                icon: "play.rectangle.on.rectangle",
                theme: readerStore.selectedGradient
            ) {
                withAnimation(.spring) {
                    if appState.alwaysShowMiniPlayer {
                        appState.showMiniPlayer = true
                    } else {
                        appState.showMiniPlayer.toggle()
                    }
                }
            }
        }
    }

    private var currentLayoutPreview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(primaryText)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if readerStore.isFullScreen {
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

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Flow Mode: \(readerStore.isFlowMode ? "Flow" : "Verse")")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(secondaryText)

                    Text("Languages: \(activeLanguageSummary)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(secondaryText)

                    Text("Font Size: \(Int(readerStore.fontSize)) pt")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(secondaryText)
                }
                .padding(.top, DesignTokens.Spacing.sm)
            }
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
        }
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

    private var activeLanguageSummary: String {
        let active = ReaderLanguage.allCases.filter { readerStore.isLanguageEnabled($0) }
        if active.isEmpty {
            return ReaderLanguage.arabic.displayTitle
        }
        return active.map(\.displayTitle).joined(separator: ", ")
    }
}

#Preview {
    ReaderPage()
        .environmentObject(AppState())
        .environmentObject(ReaderStore())
}
