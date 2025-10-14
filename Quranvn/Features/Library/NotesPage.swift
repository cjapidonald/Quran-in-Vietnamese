import SwiftUI

struct NotesPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (NoteItem) -> Void

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var quranStore: QuranDataStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(currentNotes) { note in
                Button {
                    onSelect(note)
                } label: {
                    noteRow(for: note)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func noteRow(for note: NoteItem) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(note.title)
                    .font(.headline)
                    .foregroundStyle(primaryText)
                Text(note.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }

            Spacer(minLength: DesignTokens.Spacing.md)

            Image(systemName: "note.text")
                .font(.title3)
                .foregroundStyle(accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: theme, colorScheme: colorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: theme, colorScheme: colorScheme)
    }

    private var currentNotes: [NoteItem] {
#if DEBUG
        if let override = appState.debugLibraryNotesOverride {
            return override
        }
#endif
        return NoteItem.samples(using: quranStore.surahs)
    }
}

struct NoteItem: Identifiable {
    let id = UUID()
    let title: String
    let surah: Surah
    let ayah: Int

    static func samples(using surahs: [Surah]) -> [NoteItem] {
        let entries = surahs.prefix(5)
        guard entries.count == 5 else { return [] }
        let titles = [
            "Ghi nhớ lòng thương xót của Ngài",
            "Kiên nhẫn mang lại an yên",
            "Tin vào sự sắp đặt",
            "Kiên định vì công lý",
            "Biết ơn sẽ tăng phúc lành"
        ]

        return zip(entries, titles).enumerated().map { index, pair in
            NoteItem(title: pair.1, surah: pair.0, ayah: index + 2)
        }
    }

    var subtitle: String {
        "Chương \(surah.transliteration), câu \(ayah)"
    }

    var destination: ReaderDestination {
        ReaderDestination(surahNumber: surah.number, ayah: ayah)
    }
}

#Preview {
    NotesPage(theme: .dawn) { _ in }
        .environmentObject(AppState())
        .environmentObject(QuranDataStore())
}
