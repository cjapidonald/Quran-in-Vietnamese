import SwiftUI

struct SearchPage: View {
    @EnvironmentObject private var appState: AppState
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
            Text("Hình dung trải nghiệm tìm kiếm với dữ liệu mô phỏng")
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
                                Text("Chương \(surah.index) • \(surah.name)")
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

    private var filteredSurahResults: [SurahPlaceholder] {
        guard !trimmedSearchQuery.isEmpty else { return [] }

        return SurahPlaceholder.examples.filter { surah in
            surah.vietnameseName.localizedCaseInsensitiveContains(trimmedSearchQuery) ||
                surah.name.localizedCaseInsensitiveContains(trimmedSearchQuery) ||
                String(surah.index).contains(trimmedSearchQuery)
        }
    }

    private func open(_ surah: SurahPlaceholder) {
        searchQuery = ""
        appState.isSearchFocused = false
        appState.pendingReaderDestination = ReaderDestination(surah: surah, ayah: 1)
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
}
