import SwiftUI

struct LibraryPage: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
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
                    initialSurah: appState.pendingReaderDestination?.surah,
                    initialAyah: appState.pendingReaderDestination?.ayah
                )
                .environmentObject(readerStore)
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

                Text("42%")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(primaryText)
            }

            ProgressView(value: 0.42)
                .progressViewStyle(.linear)
                .tint(accentColor)
                .frame(height: 6)
                .background(
                    Capsule()
                        .fill(primaryText.opacity(0.08))
                )
                .clipShape(Capsule())
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
}
