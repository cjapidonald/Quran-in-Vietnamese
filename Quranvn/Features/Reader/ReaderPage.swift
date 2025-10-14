import SwiftUI

struct ReaderPage: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
    @EnvironmentObject private var readingProgressStore: ReadingProgressStore
    @EnvironmentObject private var quranStore: QuranDataStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var isShowingFullPlayer = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ThemeManager.backgroundGradient(style: readerStore.selectedGradient, for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                        header
                        actionButtons
                        currentLayoutPreview
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.top, DesignTokens.Spacing.xl)
                    .padding(.bottom, appState.isMiniPlayerVisible ? 120 : DesignTokens.Spacing.xl)
                }

                if appState.isMiniPlayerVisible {
                    MiniPlayerBar {
                        isShowingFullPlayer = true
                    }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                        .padding(.bottom, DesignTokens.Spacing.lg)
                }
            }
            .navigationDestination(isPresented: $appState.showSurahDashboard) {
                ReaderDashboardView(
                    initialSurah: destinationSurah,
                    initialAyah: appState.pendingReaderDestination?.ayah
                )
                .environmentObject(readingProgressStore)
                .onAppear {
                    appState.pendingReaderDestination = nil
                }
            }
            .navigationDestination(isPresented: $isShowingFullPlayer) {
                FullPlayerView()
            }
        }
        .tint(accentColor)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Đọc")
                .font(.largeTitle.bold())
                .foregroundStyle(primaryText)
            Text("Các thao tác nhanh cho trải nghiệm đọc")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            PrimaryButton(
                title: "Mở chương",
                subtitle: "Đi tới bảng điều khiển chương mô phỏng",
                icon: "book",
                theme: readerStore.selectedGradient
            ) {
                appState.showSurahDashboard = true
            }

            PrimaryButton(
                title: readerStore.isFullScreen ? "Thoát toàn màn hình" : "Vào toàn màn hình",
                subtitle: readerStore.isFullScreen ? "Đang hiển thị chế độ chìm đắm" : "Đang hiển thị bố cục tiêu chuẩn",
                icon: "arrow.up.left.and.arrow.down.right",
                theme: readerStore.selectedGradient
            ) {
                withAnimation { readerStore.toggleFullScreen() }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Chuyển ngôn ngữ")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(ReaderLanguage.allCases) { option in
                        SegmentPill(
                            title: option.displayTitle,
                            isSelected: readerStore.isLanguageEnabled(option),
                            theme: readerStore.selectedGradient
                        ) {
                            withAnimation(.easeInOut) {
                                readerStore.toggleLanguage(option)
                            }
                        }
                    }
                }
            }

            PrimaryButton(
                title: appState.isMiniPlayerVisible ? "Ẩn trình phát mini" : "Hiện trình phát mini",
                subtitle: "Hiển thị thanh phát thử nghiệm",
                icon: "play.rectangle.on.rectangle",
                theme: readerStore.selectedGradient
            ) {
                withAnimation(.spring) {
                    if appState.alwaysShowMiniPlayer {
                        appState.showMiniPlayer = true
                    } else {
                        appState.showMiniPlayer.toggle()
                    }
                }
            }
        }
    }

    private var currentLayoutPreview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Xem trước")
                .font(.headline)
                .foregroundStyle(primaryText)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if readerStore.isFullScreen {
                    Text("Trình đọc toàn màn hình")
                        .font(.title3.bold())
                        .foregroundStyle(primaryText)
                    Text("Chế độ chìm đắm ẩn thanh điều hướng và tập trung vào từng câu kinh.")
                        .foregroundStyle(secondaryText)
                } else {
                    Text("Bố cục trình đọc tiêu chuẩn")
                        .font(.title3.bold())
                        .foregroundStyle(primaryText)
                    Text("Hiển thị tiêu đề, điều khiển và khung dịch bên cạnh.")
                        .foregroundStyle(secondaryText)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Chế độ hiển thị: \(readerStore.isFlowMode ? "Dạng dòng" : "Theo câu")")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(secondaryText)

                    Text("Ngôn ngữ: \(activeLanguageSummary)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(secondaryText)

                    Text("Cỡ chữ: \(Int(readerStore.fontSize)) pt")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(secondaryText)
                }
                .padding(.top, DesignTokens.Spacing.sm)
            }
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
        }
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: readerStore.selectedGradient, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: readerStore.selectedGradient, colorScheme: colorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: readerStore.selectedGradient, colorScheme: colorScheme)
    }

    private var destinationSurah: Surah? {
        guard let destination = appState.pendingReaderDestination else { return nil }
        return quranStore.surah(number: destination.surahNumber)
    }

    private var activeLanguageSummary: String {
        let active = ReaderLanguage.allCases.filter { readerStore.isLanguageEnabled($0) }
        if active.isEmpty {
            return ReaderLanguage.arabic.displayTitle
        }
        return active.map(\.displayTitle).joined(separator: ", ")
    }
}

#Preview {
    ReaderPage()
        .environmentObject(AppState())
        .environmentObject(ReaderStore())
        .environmentObject(ReadingProgressStore())
        .environmentObject(QuranDataStore())
}
