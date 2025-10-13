import SwiftUI

struct SurahsPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (ReaderDestination) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isSearchPresented = false
    private var surahList: [SurahPlaceholder] {
        SurahPlaceholder.examples.sorted { $0.index < $1.index }
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            searchButton

            ForEach(surahList) { surah in
                surahButton(for: surah)
            }
        }
        .sheet(isPresented: $isSearchPresented) {
            SurahSearchSheet(theme: theme) { destination in
                isSearchPresented = false
                onSelect(destination)
            }
        }
    }

    private func surahButton(for surah: SurahPlaceholder) -> some View {
        Button {
            onSelect(ReaderDestination(surah: surah, ayah: 1))
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

    private var searchButton: some View {
        Button {
            isSearchPresented = true
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryText)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Tìm kiếm câu kinh")
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    Text("Chạm để tìm câu kinh và chương liên quan")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                }

                Spacer(minLength: DesignTokens.Spacing.md)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
        }
        .buttonStyle(.plain)
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

private struct SurahSearchSheet: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (ReaderDestination) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery: String = ""

    private var trimmedQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredResults: [AyahSearchResult] {
        guard !trimmedQuery.isEmpty else { return [] }

        return AyahSearchResult.examples.filter { result in
            result.matches(trimmedQuery)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager
                    .backgroundGradient(style: theme, for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                        header
                        resultsSection
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.top, DesignTokens.Spacing.xl)
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Tìm kiếm câu kinh")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Tìm câu kinh")
        .tint(accentColor)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Nhập nội dung để tìm câu kinh minh hoạ")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
    }

    @ViewBuilder
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Kết quả")
                .font(.headline)
                .foregroundStyle(primaryText)

            if trimmedQuery.isEmpty {
                Text("Hãy nhập từ khoá hoặc số câu để xem kết quả tìm kiếm.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
            } else if filteredResults.isEmpty {
                Text("Không tìm thấy câu kinh nào trùng \"\(trimmedQuery)\"")
                    .font(.footnote)
                    .foregroundStyle(secondaryText.opacity(0.85))
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
            } else {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(filteredResults) { result in
                        Button {
                            searchQuery = ""
                            onSelect(ReaderDestination(surah: result.surah, ayah: result.ayahNumber))
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text(result.displayTitle)
                                    .font(.headline)
                                    .foregroundStyle(primaryText)

                                Text(result.text)
                                    .font(.subheadline)
                                    .foregroundStyle(secondaryText)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            .glassCard(
                                cornerRadius: DesignTokens.CornerRadius.large,
                                padding: 0,
                                shadowStyle: DesignTokens.Shadow.subtle
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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

private struct AyahSearchResult: Identifiable {
    let id = UUID()
    let surah: SurahPlaceholder
    let ayahNumber: Int
    let text: String

    var displayTitle: String {
        "Chương \(surah.index) • Ayah \(ayahNumber)"
    }

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        let haystack = [
            surah.name,
            surah.vietnameseName,
            text,
            String(surah.index),
            String(ayahNumber)
        ]
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        return haystack.contains(normalizedQuery)
    }

    static let examples: [AyahSearchResult] = {
        var results: [AyahSearchResult] = []
        let templates = [
            "Đây là câu minh hoạ mô tả lòng thành kính trong chương %@.",
            "Một đoạn văn mô phỏng thể hiện sự suy ngẫm sâu sắc của chương %@.",
            "Câu minh hoạ khuyến khích lòng biết ơn thuộc chương %@.",
            "Ví dụ nói về sự kiên nhẫn của chương %@.",
            "Câu diễn tả niềm hy vọng và ánh sáng từ chương %@."
        ]

        for surah in SurahPlaceholder.examples {
            for number in 1...3 {
                let template = templates[(number + surah.index) % templates.count]
                let text = String(format: template, surah.vietnameseName)
                results.append(
                    AyahSearchResult(
                        surah: surah,
                        ayahNumber: number,
                        text: text
                    )
                )
            }
        }

        return results
    }()
}
