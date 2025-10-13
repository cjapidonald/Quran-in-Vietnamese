import SwiftUI

struct SurahsPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (SurahPlaceholder) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText: String = ""

    private var surahList: [SurahPlaceholder] {
        SurahPlaceholder.examples.sorted { $0.index < $1.index }
    }

    private var filteredSurahs: [SurahPlaceholder] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return surahList }

        return surahList.filter { surah in
            surah.vietnameseName.localizedCaseInsensitiveContains(trimmedQuery) ||
                surah.name.localizedCaseInsensitiveContains(trimmedQuery) ||
                String(surah.index).contains(trimmedQuery)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            searchField

            if filteredSurahs.isEmpty {
                placeholder
            } else {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(filteredSurahs) { surah in
                        surahButton(for: surah)
                    }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.headline.weight(.semibold))
                .foregroundStyle(secondaryText.opacity(0.9))

            TextField("Tìm chương tiếng Việt", text: $searchText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .foregroundStyle(primaryText)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                .fill(primaryText.opacity(0.06))
        )
    }

    private func surahButton(for surah: SurahPlaceholder) -> some View {
        Button {
            onSelect(surah)
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(surah.vietnameseName)
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Text("Chương \(surah.index) • \(surah.name)")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
        }
        .buttonStyle(.plain)
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Không tìm thấy chương phù hợp")
                .font(.headline)
                .foregroundStyle(primaryText)
            Text("Thử tìm bằng tên tiếng Việt hoặc số chương.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.Spacing.lg)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: theme, colorScheme: colorScheme)
    }
}

#Preview {
    SurahsPage(theme: .dawn) { _ in }
}
