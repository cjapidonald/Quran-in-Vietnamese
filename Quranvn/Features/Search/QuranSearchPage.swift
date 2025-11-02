import SwiftUI

struct SearchResult: Identifiable {
    let id = UUID()
    let surah: Surah
    let ayah: Ayah
    let matchText: String
}

struct QuranSearchPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (ReaderDestination) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var quranStore: QuranDataStore

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [SearchResult] = []

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Search bar
            searchBar

            // Results
            if isSearching && !searchText.isEmpty {
                if searchResults.isEmpty {
                    emptySearchState
                } else {
                    resultsList
                }
            } else if !isSearching {
                initialState
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(isSearching ? accentColor : secondaryText.opacity(0.6))

            // Search text field
            TextField("Tìm kiếm trong Qur'an...", text: $searchText)
                .font(.body)
                .foregroundStyle(primaryText)
                .tint(accentColor)
                .onChange(of: searchText) { _, newValue in
                    performSearch(query: newValue)
                }

            // Clear button
            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                        searchResults = []
                        isSearching = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(secondaryText.opacity(0.6))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.large)
    }

    private var resultsList: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Results header
            HStack {
                Text("\(searchResults.count) kết quả")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)

            // Search results
            ForEach(searchResults) { result in
                searchResultCard(result)
            }
        }
    }

    private func searchResultCard(_ result: SearchResult) -> some View {
        Button {
            // Navigate to this specific ayah
            onSelect(ReaderDestination(
                surahNumber: result.surah.number,
                ayah: result.ayah.number
            ))
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Surah info
                HStack {
                    Text(result.surah.vietnameseName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accentColor)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(secondaryText.opacity(0.5))

                    Text("Câu \(result.ayah.number)")
                        .font(.caption)
                        .foregroundStyle(secondaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(secondaryText.opacity(0.5))
                }

                // Matched text preview
                Text(highlightedText(result.matchText, query: searchText))
                    .font(.subheadline)
                    .foregroundStyle(primaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: DesignTokens.CornerRadius.large, padding: 0)
        }
        .buttonStyle(.plain)
    }

    private func highlightedText(_ text: String, query: String) -> AttributedString {
        var attributedString = AttributedString(text)

        if let range = text.range(of: query, options: .caseInsensitive) {
            let start = attributedString.index(attributedString.startIndex, offsetByCharacters: text.distance(from: text.startIndex, to: range.lowerBound))
            let end = attributedString.index(start, offsetByCharacters: query.count)
            attributedString[start..<end].foregroundColor = accentColor
            attributedString[start..<end].font = .subheadline.weight(.semibold)
        }

        return attributedString
    }

    private var initialState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "book.pages")
                .font(.system(size: 56))
                .foregroundStyle(accentColor.opacity(0.6))

            Text("Tìm kiếm trong Qur'an")
                .font(.title3.weight(.semibold))
                .foregroundStyle(primaryText)

            Text("Nhập từ khóa để tìm kiếm trong các câu kinh")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xl * 2)
    }

    private var emptySearchState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(secondaryText.opacity(0.4))

            Text("Không tìm thấy kết quả")
                .font(.headline)
                .foregroundStyle(primaryText)

            Text("Thử tìm kiếm với từ khóa khác")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xl * 2)
    }

    private func performSearch(query: String) {
        guard !query.isEmpty, query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        let lowercased = query.lowercased()
        var results: [SearchResult] = []

        // Search through all surahs and ayahs
        for surah in quranStore.surahs {
            for ayah in surah.ayahs {
                // Check if ayah matches
                if ayah.vietnamese.lowercased().contains(lowercased) ||
                   ayah.arabic.lowercased().contains(lowercased) {

                    // Get context around match for preview
                    let matchText = getMatchPreview(
                        text: ayah.vietnamese,
                        query: query
                    )

                    results.append(SearchResult(
                        surah: surah,
                        ayah: ayah,
                        matchText: matchText
                    ))
                }
            }
        }

        // Limit results to prevent performance issues
        searchResults = Array(results.prefix(100))
    }

    private func getMatchPreview(text: String, query: String) -> String {
        guard let range = text.range(of: query, options: .caseInsensitive) else {
            // If no match, return beginning of text
            return String(text.prefix(150))
        }

        let matchStart = text.distance(from: text.startIndex, to: range.lowerBound)
        let contextStart = max(0, matchStart - 50)
        let contextEnd = min(text.count, matchStart + query.count + 100)

        let startIndex = text.index(text.startIndex, offsetBy: contextStart)
        let endIndex = text.index(text.startIndex, offsetBy: contextEnd)

        var preview = String(text[startIndex..<endIndex])

        // Add ellipsis if truncated
        if contextStart > 0 {
            preview = "..." + preview
        }
        if contextEnd < text.count {
            preview = preview + "..."
        }

        return preview
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

#Preview {
    QuranSearchPage(theme: .dawn) { _ in }
        .environmentObject(QuranDataStore())
}
