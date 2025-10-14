import SwiftUI

struct SearchPage: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var quranStore: QuranDataStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchQuery: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager
                    .backgroundGradient(style: appState.selectedThemeGradient, for: colorScheme)
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
            .navigationTitle("Tìm kiếm")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") {
                        close()
                    }
                }
            }
        }
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Tìm kiếm Quran")
        .onChange(of: searchQuery) { _, newValue in
            withAnimation(.easeInOut) {
                appState.isSearchFocused = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
            }
        }
        .tint(accentColor)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Tìm kiếm")
                .font(.largeTitle.bold())
                .foregroundStyle(primaryText)
            Text("Tìm kiếm chương và câu kinh trong dữ liệu đã tải")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    @ViewBuilder
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Kết quả")
                .font(.headline)
                .foregroundStyle(primaryText)

            if trimmedSearchQuery.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Nhập nội dung để xem thử trải nghiệm tìm kiếm trực quan.")
                        .foregroundStyle(secondaryText)
                    Text("Chức năng tìm kiếm thật chưa khả dụng — toàn bộ đều là mô phỏng.")
                        .font(.footnote)
                        .foregroundStyle(secondaryText.opacity(0.8))
                }
                .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
            } else if filteredSurahResults.isEmpty {
                Text("Không tìm thấy chương nào trùng \"\(trimmedSearchQuery)\"")
                    .font(.footnote)
                    .foregroundStyle(secondaryText.opacity(0.8))
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
            } else {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(filteredSurahResults) { surah in
                        Button {
                            open(surah)
                        } label: {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text(surah.vietnameseName)
                                    .font(.headline)
                                    .foregroundStyle(primaryText)
                                Text("Chương \(surah.number) • \(surah.transliteration)")
                                    .font(.subheadline)
                                    .foregroundStyle(secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            .glassCard(cornerRadius: DesignTokens.CornerRadius.large, padding: 0, shadowStyle: DesignTokens.Shadow.subtle)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var trimmedSearchQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredSurahResults: [Surah] {
        guard !trimmedSearchQuery.isEmpty else { return [] }

        return quranStore.surahs.filter { surah in
            surah.vietnameseName.localizedCaseInsensitiveContains(trimmedSearchQuery) ||
                surah.transliteration.localizedCaseInsensitiveContains(trimmedSearchQuery) ||
                String(surah.number).contains(trimmedSearchQuery)
        }
    }

    private func open(_ surah: Surah) {
        searchQuery = ""
        appState.isSearchFocused = false
        appState.pendingReaderDestination = ReaderDestination(surahNumber: surah.number, ayah: 1)
        appState.selectedTab = .library
        appState.showSurahDashboard = true
        close()
    }

    private func close() {
        withAnimation(.easeInOut) {
            appState.isSearchPresented = false
        }
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

#Preview {
    SearchPage()
        .environmentObject(AppState())
        .environmentObject(QuranDataStore())
}
