import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

struct ReaderDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
    @EnvironmentObject private var readingProgressStore: ReadingProgressStore
    @EnvironmentObject private var quranStore: QuranDataStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSurahID: Int
    @State private var ayahs: [Ayah] = []
    @State private var scrollTarget: String?
    @State private var favoriteAyahs: Set<String> = []
    @State private var ayahNotes: [String: [String]] = [:]
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var safariURL: URL?
    @State private var isShowingSafari = false
    @State private var isPresentingNoteSheet = false
    @State private var noteDraft = ""
    @State private var noteAyahID: String?
    @State private var isShowingFullPlayer = false
    @State private var highlightedAyahID: String?
    @State private var highlightIsActive = false
    @State private var hasActivatedHighlight = false
    @State private var lastHandledLanguageEnforcementID: UUID?
    @State private var pendingInitialAyah: Int?
    @State private var progressUpdateTask: Task<Void, Never>?
    @State private var lastRecordedAyah: Int?
    init(initialSurah: Surah? = nil, initialAyah: Int? = nil, highlightAyah: Int? = nil) {
        let resolvedSurahID = initialSurah?.number ?? 1
        _selectedSurahID = State(initialValue: resolvedSurahID)
        let targetAyah = highlightAyah ?? initialAyah
        _pendingInitialAyah = State(initialValue: targetAyah)
        _scrollTarget = State(initialValue: nil)
        _highlightedAyahID = State(initialValue: nil)
    }

    private var selectedSurah: Surah {
        if let match = quranStore.surah(number: selectedSurahID) {
            return match
        }

        guard let fallback = quranStore.surahs.first else {
            fatalError("Không tìm thấy dữ liệu chương Kinh Qur'an")
        }

        return fallback
    }

    private var readerHorizontalPadding: CGFloat {
        readerStore.isFullScreen ? DesignTokens.Spacing.sm : DesignTokens.Spacing.md
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: DesignTokens.Spacing.lg) {
                if !readerStore.isFullScreen {
                    ReaderToolbar()
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: readerStore.isFlowMode ? DesignTokens.Spacing.md : DesignTokens.Spacing.lg) {
                            surahHeader
                            ForEach(ayahs) { ayah in
                                ayahCard(for: ayah)
                                    .id(ayah.id)
                            }
                        }
                        .padding(.bottom, DesignTokens.Spacing.xl)
                    }
                    .scrollIndicators(.hidden)
                    .onAppear {
                        guard let target = scrollTarget else { return }
                        scrollTo(target, using: proxy)
                    }
                    .onChange(of: scrollTarget) { _, target in
                        guard let target else { return }
                        scrollTo(target, using: proxy)
                    }
                    .onAppear {
                        activateHighlightIfNeeded()
                    }
                }
            }
            .padding(.horizontal, readerHorizontalPadding)
            .padding(.top, DesignTokens.Spacing.xl)
            .padding(.bottom, readerStore.isFullScreen ? DesignTokens.Spacing.xl : 0)
        }
        .ignoresSafeArea(edges: readerStore.isFullScreen ? .all : .horizontal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Group {
                if !readerStore.isFullScreen {
                    Group {
                        if appState.isMiniPlayerVisible {
                            MiniPlayerBar {
                                isShowingFullPlayer = true
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, readerHorizontalPadding)
                    .padding(.top, DesignTokens.Spacing.md)
                    .padding(.bottom, readerHorizontalPadding)
                    .background(.clear)
                }
            }
        }
        .sheet(isPresented: $isShowingSafari) {
            if let safariURL {
                SafariView(url: safariURL)
            }
        }
        .sheet(isPresented: $isPresentingNoteSheet, onDismiss: resetNoteDraft) {
            noteSheet
        }
        .overlay(toastView, alignment: .top)
        .overlay(fullScreenControls, alignment: .topTrailing)
        .contentShape(Rectangle())
        .simultaneousGesture(exitFullScreenGesture)
        .simultaneousGesture(navigationGesture)
        .navigationDestination(isPresented: $isShowingFullPlayer) {
            FullPlayerView()
        }
        .onChange(of: readerStore.lastLanguageEnforcementID) { _, newValue in
            guard let newValue, newValue != lastHandledLanguageEnforcementID else { return }
            lastHandledLanguageEnforcementID = newValue
            showToast(message: "Luôn bật ít nhất một ngôn ngữ")
        }
        .onAppear {
            refreshAyahs(forceReset: true)
        }
#if DEBUG
        .onChange(of: appState.debugAyahCountOverride) { _, _ in
            refreshAyahs(forceReset: true)
        }
#endif
        .onChange(of: selectedSurahID) { _, _ in
            pendingInitialAyah = 1
            refreshAyahs(forceReset: true)
        }
    }

    private var background: some View {
        ThemeManager.backgroundGradient(style: readerStore.selectedGradient, for: colorScheme)
            .overlay(
                readerStore.isFullScreen
                    ? Color.black.opacity(colorScheme == .dark ? 0.35 : 0.25)
                    : Color.clear
            )
            .ignoresSafeArea()
    }

    private func ayahCard(for ayah: Ayah) -> some View {
        let isHighlighted = highlightIsActive && highlightedAyahID == ayah.id
        let arabicIncludesNumber = readerStore.showArabic && !readerStore.showVietnamese

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                if readerStore.showArabic {
                    Text(formattedAyahText(ayah.arabic, number: ayah.number, includeNumber: arabicIncludesNumber))
                        .font(arabicFont)
                        .foregroundStyle(primaryText)
                }

                if readerStore.showVietnamese {
                    Text(formattedAyahText(ayah.vietnamese, number: ayah.number, includeNumber: true))
                        .font(translationFont)
                        .foregroundStyle(translationText)
                        .lineSpacing(4)
                }
            }
            .overlay(alignment: .topTrailing) {
                favoriteBadge(isActive: favoriteAyahs.contains(ayah.id))
            }

            if let notes = ayahNotes[ayah.id], !notes.isEmpty {
                Divider()
                    .blendMode(.overlay)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    ForEach(Array(notes.enumerated()), id: \.offset) { entry in
                        Text("Ghi chú \(entry.offset + 1): \(entry.element)")
                            .font(.footnote)
                            .foregroundStyle(secondaryText.opacity(0.85))
                    }
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isHighlighted {
                Rectangle()
                    .fill(highlightColor.opacity(colorScheme == .dark ? 0.28 : 0.18))
            }
        }
        .overlay(alignment: .leading) {
            if isHighlighted {
                Rectangle()
                    .fill(highlightColor)
                    .frame(width: 4)
                    .cornerRadius(2)
            }
        }
        .overlay(alignment: .bottomLeading) {
            Divider()
                .blendMode(.overlay)
                .opacity(0.4)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            toggleFavorite(for: ayah.id)
        }
        .onAppear {
            recordProgress(for: ayah)
        }
        .contextMenu {
            Button {
                showToast(message: "Chưa có nội dung")
            } label: {
                Label("Sao chép câu kinh", systemImage: "doc.on.doc")
                    .foregroundStyle(secondaryText.opacity(0.6))
            }

            Button {
                askChatGPT(for: ayah)
            } label: {
                Label("Hỏi ChatGPT", systemImage: "sparkles")
            }

            Button {
                prepareNote(for: ayah.id)
            } label: {
                Label("Thêm ghi chú", systemImage: "square.and.pencil")
            }
        }
    }

    private func recordProgress(for ayah: Ayah) {
        // Cancel previous pending update
        progressUpdateTask?.cancel()

        // Only update if this is a new ayah
        guard lastRecordedAyah != ayah.number else { return }

        // Debounce: wait 0.5s before actually recording to avoid writing during scroll
        progressUpdateTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            guard !Task.isCancelled else { return }

            await MainActor.run {
                lastRecordedAyah = ayah.number
                let totalAyahs = max(ayahs.count, selectedSurah.ayahCount)
                readingProgressStore.markAyah(ayah.number, asReadIn: selectedSurah, totalAyahs: totalAyahs)
            }
        }
    }

    private func formattedAyahText(_ text: String, number: Int, includeNumber: Bool) -> String {
        guard includeNumber else { return text }
        return "\(text) \(number)"
    }

    private func favoriteBadge(isActive: Bool) -> some View {
        Image(systemName: "heart.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.pink)
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1.1 : 0.5)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isActive)
            .allowsHitTesting(false)
            .accessibilityHidden(!isActive)
    }

    private func toggleFavorite(for id: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            if favoriteAyahs.contains(id) {
                favoriteAyahs.remove(id)
            } else {
                favoriteAyahs.insert(id)
            }
        }
    }

    private func prepareNote(for id: String) {
        noteAyahID = id
        noteDraft = ""
        isPresentingNoteSheet = true
    }

    private func askChatGPT(for ayah: Ayah) {
        guard let url = chatGPTURL(for: ayah) else {
            showToast(message: "Không thể mở ChatGPT ngay bây giờ")
            return
        }

        safariURL = url
        isShowingSafari = true
    }

    private func chatGPTURL(for ayah: Ayah) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "chat.openai.com"
        components.queryItems = [
            URLQueryItem(name: "q", value: chatGPTPrompt(for: ayah))
        ]

        if let url = components.url {
            return url
        }

        components.host = "www.chat.openai.com"
        return components.url
    }

    private func chatGPTPrompt(for ayah: Ayah) -> String {
        let surahName = selectedSurah.vietnameseName
        return "Hãy giải thích ý nghĩa và bối cảnh câu kinh số \(ayah.number) trong chương \(surahName) của Kinh Qur'an."
    }

    private func showToast(message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showToast = false
            }
        }
    }

    private func resetNoteDraft() {
        noteDraft = ""
        noteAyahID = nil
    }

    private var noteSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Thêm ghi chú")
                    .font(.title3.bold())
                TextEditor(text: $noteDraft)
                    .frame(minHeight: 160)
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(Color(.secondarySystemBackground))
                    )
                Spacer()
            }
            .padding()
            .navigationTitle("Ghi chú")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") {
                        isPresentingNoteSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        saveNote()
                        isPresentingNoteSheet = false
                    }
                    .disabled(noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveNote() {
        guard let id = noteAyahID else { return }
        let trimmed = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var notes = ayahNotes[id] ?? []
        notes.append(trimmed)
        ayahNotes[id] = notes
    }

    private var toastView: some View {
        Group {
            if showToast, let toastMessage {
                Text(toastMessage)
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)
                    .padding(.top, DesignTokens.Spacing.lg)
            }
        }
    }

    private var surahHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(selectedSurah.arabicName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(primaryText)
                Text(selectedSurah.vietnameseName)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(secondaryText)
                Text("Chế độ hiển thị: \(readerStore.isFlowMode ? "Dạng dòng" : "Theo câu")")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(secondaryText.opacity(0.8))
            }

            SurahDock(
                surahs: quranStore.surahs,
                selectedSurahNumber: $selectedSurahID
            ) { surah in
                pendingInitialAyah = 1
                showToast(message: "Đang chuyển đến \(surah.vietnameseName)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: readerStore.selectedGradient, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: readerStore.selectedGradient, colorScheme: colorScheme)
    }

    private var translationText: Color {
        readerStore.translationTextColor(for: colorScheme)
    }

    private var translationFont: Font {
        readerStore.translationFont(for: readerStore.fontSize)
    }

    private var arabicFont: Font {
        readerStore.arabicFont(for: readerStore.fontSize)
    }

    private var highlightColor: Color {
        ThemeManager.accentColor(for: readerStore.selectedGradient, colorScheme: colorScheme)
    }

    private func resolvedAyahs(for surah: Surah) -> [Ayah] {
#if DEBUG
        if let override = appState.debugAyahCountOverride, override > 0 {
            return (1...override).map { number in
                Ayah(
                    id: "\(surah.number):\(number)",
                    number: number,
                    arabic: "آية giả lập #\(number)",
                    vietnamese: "Đây là câu giả lập số \(number)."
                )
            }
        }
#endif
        return surah.ayahs
    }

    private func refreshAyahs(forceReset: Bool = false) {
        let updated = resolvedAyahs(for: selectedSurah)
        let currentIDs = ayahs.map(\.id)
        let updatedIDs = updated.map(\.id)

        guard forceReset || currentIDs != updatedIDs else { return }

        ayahs = updated
        favoriteAyahs.removeAll()
        ayahNotes.removeAll()

        if let target = pendingInitialAyah,
           let targetID = ReaderDashboardView.scrollIdentifier(for: target, in: updated) {
            scrollTarget = targetID
            highlightedAyahID = targetID
            pendingInitialAyah = nil
        } else {
            scrollTarget = nil
            highlightedAyahID = nil
        }

        highlightIsActive = false
        hasActivatedHighlight = false
    }

    private static func scrollIdentifier(for ayahNumber: Int, in ayahs: [Ayah]) -> String? {
        if let match = ayahs.first(where: { $0.number == ayahNumber }) {
            return match.id
        }
        return ayahs.last?.id
    }

    private func scrollTo(_ id: String, using proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut) {
                proxy.scrollTo(id, anchor: .top)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            activateHighlightIfNeeded()
        }
    }

    private func activateHighlightIfNeeded() {
        guard !hasActivatedHighlight, highlightedAyahID != nil else { return }
        hasActivatedHighlight = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                highlightIsActive = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    highlightIsActive = false
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    highlightedAyahID = nil
                }
            }
        }
    }

    private var fullScreenControls: some View {
        Group {
            if readerStore.isFullScreen {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    fullScreenControlButton(title: "Đóng") {
                        exitFullScreen()
                    }

                    fullScreenControlButton(title: "A−", isEnabled: readerStore.canDecreaseFontSize) {
                        readerStore.decreaseFontSize()
                    }

                    fullScreenControlButton(title: "A+", isEnabled: readerStore.canIncreaseFontSize) {
                        readerStore.increaseFontSize()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(.thinMaterial, in: Capsule())
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.18), radius: 18, x: 0, y: 12)
                .padding(.top, DesignTokens.Spacing.xl)
                .padding(.trailing, DesignTokens.Spacing.xl)
            }
        }
    }

    private func fullScreenControlButton(title: String, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(primaryText.opacity(isEnabled ? 1 : 0.45))
                .padding(.vertical, DesignTokens.Spacing.xs)
                .padding(.horizontal, DesignTokens.Spacing.sm)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
        .contentShape(Rectangle())
    }

    private func exitFullScreen() {
        guard readerStore.isFullScreen else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            readerStore.toggleFullScreen()
        }
    }

    private func navigateBackToSurahs() {
        appState.showSurahDashboard = false
        dismiss()
    }

    private func navigateToSettings() {
        appState.showSurahDashboard = false
        dismiss()
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                appState.selectedTab = .settings
            }
        }
    }

    private var exitFullScreenGesture: some Gesture {
        DragGesture(minimumDistance: 25, coordinateSpace: .local)
            .onEnded { value in
                guard readerStore.isFullScreen else { return }

                let verticalTranslation = value.translation.height
                let horizontalTranslation = abs(value.translation.width)

                if verticalTranslation > 80, verticalTranslation > horizontalTranslation {
                    exitFullScreen()
                }
            }
    }

    private var navigationGesture: some Gesture {
        DragGesture(minimumDistance: 80, coordinateSpace: .local)
            .onEnded(handleNavigationSwipe)
    }

    private func handleNavigationSwipe(_ value: DragGesture.Value) {
        guard !readerStore.isFullScreen else { return }

        let horizontalTranslation = value.translation.width
        let absoluteHorizontalTranslation = abs(horizontalTranslation)
        let verticalTranslation = abs(value.translation.height)

        guard absoluteHorizontalTranslation > 60, absoluteHorizontalTranslation > verticalTranslation else { return }

        if horizontalTranslation > 0 {
            navigateBackToSurahs()
        } else {
            navigateToSettings()
        }
    }
}

#if canImport(SafariServices)
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#else
private struct SafariView: View {
    let url: URL

    var body: some View {
        EmptyView()
    }
}
#endif

struct ReaderDestination {
    let surahNumber: Int
    let ayah: Int
}
