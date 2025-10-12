import SwiftUI

struct NotesPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (NoteItem) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let notes: [NoteItem] = [
        NoteItem(title: "Remember His mercy", surah: SurahPlaceholder.examples[0], ayah: 3),
        NoteItem(title: "Patience brings relief", surah: SurahPlaceholder.examples[1], ayah: 4),
        NoteItem(title: "Trust in the plan", surah: SurahPlaceholder.examples[2], ayah: 9),
        NoteItem(title: "Stand for justice", surah: SurahPlaceholder.examples[3], ayah: 8),
        NoteItem(title: "Gratitude multiplies", surah: SurahPlaceholder.examples[4], ayah: 2)
    ]

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(notes) { note in
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
}

struct NoteItem: Identifiable {
    let id = UUID()
    let title: String
    let surah: SurahPlaceholder
    let ayah: Int

    var subtitle: String {
        "Surah \(surah.name), Ayah \(ayah)"
    }

    var destination: ReaderDestination {
        ReaderDestination(surah: surah, ayah: ayah)
    }
}

#Preview {
    NotesPage(theme: .dawn) { _ in }
}
