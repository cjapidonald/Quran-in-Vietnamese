import SwiftUI

struct SurahsPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (ReaderDestination) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var readingProgressStore: ReadingProgressStore
    @EnvironmentObject private var quranStore: QuranDataStore

    @State private var searchText = ""
    @State private var isSearching = false

    private var surahList: [Surah] {
        let sorted = quranStore.surahs.sorted { $0.index < $1.index }

        // Filter based on search
        if searchText.isEmpty {
            return sorted
        }

        let lowercased = searchText.lowercased()
        return sorted.filter { surah in
            // Search by surah name (Vietnamese or Arabic)
            let matchesSurahName = surah.vietnameseName.lowercased().contains(lowercased) ||
                surah.arabicName.lowercased().contains(lowercased) ||
                surah.transliteration.lowercased().contains(lowercased) ||
                "\(surah.number)".contains(lowercased)

            // If surah name matches, return true immediately
            if matchesSurahName {
                return true
            }

            // Otherwise, search through all ayahs in this surah
            let matchesAyah = surah.ayahs.contains { ayah in
                ayah.vietnamese.lowercased().contains(lowercased) ||
                ayah.arabic.lowercased().contains(lowercased)
            }

            return matchesAyah
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Search bar
            searchBar

            // Surah list or loading state
            if quranStore.surahs.isEmpty {
                // Loading state
                VStack(spacing: DesignTokens.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(accentColor)
                    Text("Đang tải...")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.xl * 2)
            } else if surahList.isEmpty && !searchText.isEmpty {
                // Empty search results
                emptySearchState
            } else {
                // Surah list
                ForEach(surahList) { surah in
                    surahButton(for: surah)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchBar: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(isSearching ? accentColor : secondaryText.opacity(0.6))

            // Search text field
            TextField("Tìm kiếm chương hoặc nội dung...", text: $searchText)
                .font(.body)
                .foregroundStyle(primaryText)
                .tint(accentColor)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearching = true
                    }
                }
                .onChange(of: searchText) { _, _ in
                    if searchText.isEmpty {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearching = false
                        }
                    }
                }

            // Clear button
            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
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

    private func surahButton(for surah: Surah) -> some View {
        Button {
            let targetAyah = readingProgressStore.nextAyah(for: surah)
            onSelect(ReaderDestination(surahNumber: surah.number, ayah: targetAyah))
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    // Surah number badge
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                        Text("\(surah.number)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(accentColor)
                    }
                    .frame(width: 44, height: 44)

                    // Surah info
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(surah.vietnameseName)
                            .font(.headline)
                            .foregroundStyle(primaryText)

                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Text("\(surah.ayahCount) câu")
                                .font(.caption)
                                .foregroundStyle(secondaryText)

                            Text("•")
                                .font(.caption)
                                .foregroundStyle(secondaryText.opacity(0.5))

                            Text(progressText(for: surah))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(progressColor(for: surah))
                        }
                    }

                    Spacer()

                    // Progress indicator
                    progressIndicator(for: surah)
                }
                .padding(.vertical, DesignTokens.Spacing.md)
                .padding(.horizontal, DesignTokens.Spacing.lg)

                // Progress bar at bottom
                progressBar(for: surah)
            }
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
        }
        .buttonStyle(.plain)
    }

    private func progressBar(for surah: Surah) -> some View {
        GeometryReader { geometry in
            let progress = readingProgressStore.progress(for: surah)
            let clamped = min(max(progress, 0), 1)
            let fillWidth = geometry.size.width * CGFloat(clamped)

            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(secondaryText.opacity(0.1))

                // Progress fill
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.8), accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth)
            }
            .frame(height: 3)
            .opacity(clamped > 0 ? 1 : 0)
            .animation(.easeInOut(duration: 0.35), value: clamped)
        }
        .frame(height: 3)
        .allowsHitTesting(false)
    }

    private func progressIndicator(for surah: Surah) -> some View {
        let progress = readingProgressStore.progress(for: surah)
        let clamped = min(max(progress, 0), 1)
        let percentage = Int(clamped * 100)

        return ZStack {
            Circle()
                .stroke(secondaryText.opacity(0.15), lineWidth: 3)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    accentColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if clamped > 0 {
                Text("\(percentage)%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accentColor)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(secondaryText.opacity(0.5))
            }
        }
        .frame(width: 40, height: 40)
        .animation(.easeInOut(duration: 0.35), value: clamped)
    }

    private func progressText(for surah: Surah) -> String {
        let progress = readingProgressStore.progress(for: surah)
        let clamped = min(max(progress, 0), 1)

        if clamped >= 1.0 {
            return "Hoàn thành"
        } else if clamped > 0 {
            return "Đang đọc"
        } else {
            return "Chưa đọc"
        }
    }

    private func progressColor(for surah: Surah) -> Color {
        let progress = readingProgressStore.progress(for: surah)
        let clamped = min(max(progress, 0), 1)

        if clamped >= 1.0 {
            return .green
        } else if clamped > 0 {
            return accentColor
        } else {
            return secondaryText.opacity(0.7)
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

#Preview {
    SurahsPage(theme: .dawn) { _ in }
        .environmentObject(ReadingProgressStore())
        .environmentObject(QuranDataStore())
}
