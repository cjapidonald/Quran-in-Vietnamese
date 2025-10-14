import SwiftUI

struct LibraryPage: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
    @EnvironmentObject private var readingProgressStore: ReadingProgressStore
    @EnvironmentObject private var quranStore: QuranDataStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedSegment: LibrarySegment = .surahs

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager
                    .backgroundGradient(style: appState.selectedThemeGradient, for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                        readingProgress
                        segmentedControl
                        segmentContent
                    }
                    .padding(DesignTokens.Spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationDestination(isPresented: $appState.showSurahDashboard) {
                ReaderDashboardView(
                    initialSurah: destinationSurah,
                    initialAyah: appState.pendingReaderDestination?.ayah
                )
                .environmentObject(readerStore)
                .environmentObject(readingProgressStore)
                .onAppear {
                    appState.pendingReaderDestination = nil
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .tint(accentColor)
    }

    private var readingProgress: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tiến độ đọc")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)

                Spacer()

                Text(overallProgressText)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(primaryText)
            }

            ProgressView(value: overallProgressValue)
                .progressViewStyle(.linear)
                .tint(accentColor)
                .frame(height: 6)
                .background(
                    Capsule()
                        .fill(primaryText.opacity(0.08))
                )
                .clipShape(Capsule())
                .animation(.easeInOut(duration: 0.35), value: overallProgressValue)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
    }

    private var segmentedControl: some View {
        Picker("Phần thư viện", selection: $selectedSegment) {
            Text("Chương (Tiếng Việt)").tag(LibrarySegment.surahs)
            Text("Yêu thích").tag(LibrarySegment.favorites)
            Text("Ghi chú").tag(LibrarySegment.notes)
        }
        .pickerStyle(.segmented)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    @ViewBuilder
    private var segmentContent: some View {
        switch selectedSegment {
        case .favorites:
            FavoritesPage(theme: appState.selectedThemeGradient) { item in
                openReader(for: item.destination)
            }
        case .surahs:
            SurahsPage(theme: appState.selectedThemeGradient) { destination in
                openReader(for: destination)
            }
        case .notes:
            NotesPage(theme: appState.selectedThemeGradient) { note in
                openReader(for: note.destination)
            }
        }
    }

    private func openReader(for destination: ReaderDestination) {
        appState.pendingReaderDestination = destination
        appState.showSurahDashboard = true
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

    private var destinationSurah: Surah? {
        guard let destination = appState.pendingReaderDestination else { return nil }
        return quranStore.surah(number: destination.surahNumber)
    }

    private var overallProgressValue: Double {
        readingProgressStore.overallProgress(for: quranStore.surahs)
    }

    private var overallProgressText: String {
        overallProgressValue.formatted(.percent.precision(.fractionLength(0)))
    }
}

enum LibrarySegment: Hashable {
    case favorites
    case surahs
    case notes
}

#Preview {
    LibraryPage()
        .environmentObject(AppState())
        .environmentObject(ReaderStore())
        .environmentObject(ReadingProgressStore())
        .environmentObject(QuranDataStore())
}
