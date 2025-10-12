#if DEBUG
import SwiftUI

struct DebugMenu: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Reader") {
                    Button("Populate 30 placeholder ayahs", action: populatePlaceholderAyahs)
                    Toggle("Always show mini player for screenshots", isOn: alwaysShowMiniPlayerBinding)
                }

                Section("Library") {
                    Button("Clear favorites/notes", role: .destructive, action: clearFavoritesAndNotes)
                }

                Section("Appearance") {
                    Button("Cycle all gradients", action: cycleGradients)
                }

                Section("Navigation") {
                    Button("Jump to Al-Kahf", action: jumpToAlKahf)
                }
            }
            .navigationTitle("Debug Menu")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", role: .cancel) { dismiss() }
                }
            }
        }
    }

    private var alwaysShowMiniPlayerBinding: Binding<Bool> {
        Binding(
            get: { appState.alwaysShowMiniPlayer },
            set: { newValue in
                appState.alwaysShowMiniPlayer = newValue
                if newValue {
                    appState.showMiniPlayer = true
                }
            }
        )
    }

    private func populatePlaceholderAyahs() {
        appState.debugAyahCountOverride = 30
        appState.debugLibraryFavoritesOverride = FavoriteItem.samples
        appState.debugLibraryNotesOverride = NoteItem.samples
    }

    private func clearFavoritesAndNotes() {
        appState.debugLibraryFavoritesOverride = []
        appState.debugLibraryNotesOverride = []
    }

    private func cycleGradients() {
        let allGradients = ThemeManager.ThemeGradient.allCases
        guard !allGradients.isEmpty else { return }

        let current = appState.selectedThemeGradient
        let nextIndex: Int
        if let currentIndex = allGradients.firstIndex(of: current) {
            nextIndex = (currentIndex + 1) % allGradients.count
        } else {
            nextIndex = 0
        }

        let nextGradient = allGradients[nextIndex]
        appState.selectedThemeGradient = nextGradient
        readerStore.selectGradient(nextGradient)
    }

    private func jumpToAlKahf() {
        guard let surah = SurahPlaceholder.examples.first(where: { $0.name.contains("Al-Kahf") || $0.index == 18 }) else {
            return
        }

        appState.pendingReaderDestination = ReaderDestination(surah: surah, ayah: 1)
        appState.selectedTab = .read
        appState.showSurahDashboard = true
        dismiss()
    }
}
#endif
