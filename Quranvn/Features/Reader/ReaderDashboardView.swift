import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

struct ReaderDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSurah: SurahPlaceholder
    @State private var ayahs: [AyahPlaceholder]
    @State private var scrollTarget: UUID?
    @State private var favoriteAyahs: Set<UUID> = []
    @State private var ayahNotes: [UUID: [String]] = [:]
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var safariURL: URL?
    @State private var isShowingSafari = false
    @State private var isPresentingNoteSheet = false
    @State private var noteDraft = ""
    @State private var noteAyahID: UUID?
    @State private var isShowingFullPlayer = false
    @State private var highlightedAyahID: UUID?
    @State private var highlightIsActive = false
    @State private var hasActivatedHighlight = false
    @State private var lastHandledLanguageEnforcementID: UUID?
    init(initialSurah: SurahPlaceholder? = nil, initialAyah: Int? = nil, highlightAyah: Int? = nil) {
        let defaultSurah = SurahPlaceholder.examples.first ?? SurahPlaceholder(name: "Tạm thời", index: 1)
        let resolvedSurah = initialSurah ?? defaultSurah
        let highlightTarget = highlightAyah ?? initialAyah
        var generatedAyahs = ReaderDashboardView.generateAyahs(for: resolvedSurah)

        if let highlightTarget,
           !generatedAyahs.contains(where: { $0.number == highlightTarget }) {
            generatedAyahs.append(AyahPlaceholder(number: highlightTarget))
            generatedAyahs.sort { $0.number < $1.number }
        }

        _selectedSurah = State(initialValue: resolvedSurah)
        _ayahs = State(initialValue: generatedAyahs)
        if let ayahNumber = highlightTarget ?? initialAyah,
           let targetID = ReaderDashboardView.scrollIdentifier(for: ayahNumber, in: generatedAyahs) {
            _scrollTarget = State(initialValue: targetID)
            _highlightedAyahID = State(initialValue: targetID)
        } else {
            _scrollTarget = State(initialValue: nil)
            _highlightedAyahID = State(initialValue: nil)
        }
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
        .simultaneousGesture(exitFullScreenGesture)
        .highPriorityGesture(backNavigationGesture)
        .navigationDestination(isPresented: $isShowingFullPlayer) {
            FullPlayerView()
        }
        .onChange(of: readerStore.lastLanguageEnforcementID) { _, newValue in
            guard let newValue, newValue != lastHandledLanguageEnforcementID else { return }
            lastHandledLanguageEnforcementID = newValue
            showToast(message: "Luôn bật ít nhất một ngôn ngữ")
        }
        .onAppear {
            applyDebugAyahOverrideIfNeeded()
        }
#if DEBUG
        .onChange(of: appState.debugAyahCountOverride) {
            applyDebugAyahOverrideIfNeeded()
        }
#endif
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

    private func ayahCard(for ayah: AyahPlaceholder) -> some View {
        let isHighlighted = highlightIsActive && highlightedAyahID == ayah.id

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                if readerStore.showArabic {
                    Text("آية minh họa #\(ayah.number)")
                        .font(arabicFont)
                        .foregroundStyle(primaryText)
                }

                if readerStore.showVietnamese {
                    Text("Đây là đoạn văn mô phỏng cho câu số \(ayah.number).")
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isHighlighted {
                Rectangle()
                    .fill(highlightColor.opacity(colorScheme == .dark ? 0.28 : 0.18))
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .overlay(alignment: .leading) {
            if isHighlighted {
                Rectangle()
                    .fill(highlightColor)
                    .frame(width: 4)
                    .cornerRadius(2)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomLeading) {
            Divider()
                .blendMode(.overlay)
                .opacity(0.4)
        }
        .contentShape(Rectangle())
        .scaleEffect(isHighlighted ? 1.01 : 1)
        .animation(.spring(response: 0.55, dampingFraction: 0.75), value: isHighlighted)
        .onTapGesture(count: 2) {
            toggleFavorite(for: ayah.id)
        }
        .contextMenu {
            Button {
                showToast(message: "Chưa có nội dung")
            } label: {
                Label("Sao chép câu kinh", systemImage: "doc.on.doc")
                    .foregroundStyle(secondaryText.opacity(0.6))
            }

            Button {
                askChantGPT(for: ayah)
            } label: {
                Label("Hỏi ChantGPT", systemImage: "sparkles")
            }

            Button {
                prepareNote(for: ayah.id)
            } label: {
                Label("Thêm ghi chú", systemImage: "square.and.pencil")
            }
        }
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

    private func toggleFavorite(for id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            if favoriteAyahs.contains(id) {
                favoriteAyahs.remove(id)
            } else {
                favoriteAyahs.insert(id)
            }
        }
    }

    private func prepareNote(for id: UUID) {
        noteAyahID = id
        noteDraft = ""
        isPresentingNoteSheet = true
    }

    private func askChantGPT(for ayah: AyahPlaceholder) {
        guard let url = chantGPTURL(for: ayah) else {
            showToast(message: "Không thể mở ChantGPT ngay bây giờ")
            return
        }

        safariURL = url
        isShowingSafari = true
    }

    private func chantGPTURL(for ayah: AyahPlaceholder) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "chantgpt.com"
        components.queryItems = [
            URLQueryItem(name: "q", value: chantGPTPrompt(for: ayah))
        ]

        if let url = components.url {
            return url
        }

        components.host = "www.chantgpt.com"
        return components.url
    }

    private func chantGPTPrompt(for ayah: AyahPlaceholder) -> String {
        "Hãy giải thích ý nghĩa và bối cảnh câu kinh số \(ayah.number) trong chương \(selectedSurah.vietnameseName) của Kinh Qur'an."
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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(selectedSurah.name)
                .font(.title2.weight(.semibold))
                .foregroundStyle(primaryText)
            Text("Chế độ hiển thị: \(readerStore.isFlowMode ? "Dạng dòng" : "Theo câu")")
                .font(.footnote.weight(.medium))
                .foregroundStyle(secondaryText.opacity(0.8))
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

    private func resolvedAyahs(for surah: SurahPlaceholder) -> [AyahPlaceholder] {
#if DEBUG
        if let override = appState.debugAyahCountOverride, override > 0 {
            return (1...override).map { AyahPlaceholder(number: $0) }
        }
#endif
        return ReaderDashboardView.generateAyahs(for: surah)
    }

    private func applyDebugAyahOverrideIfNeeded() {
#if DEBUG
        let updated = resolvedAyahs(for: selectedSurah)
        let currentNumbers = ayahs.map(\.number)
        let updatedNumbers = updated.map(\.number)

        guard currentNumbers != updatedNumbers else { return }

        ayahs = updated
        favoriteAyahs.removeAll()
        ayahNotes.removeAll()
        scrollTarget = nil
        highlightedAyahID = nil
        highlightIsActive = false
        hasActivatedHighlight = false
#endif
    }

    private static func generateAyahs(for surah: SurahPlaceholder) -> [AyahPlaceholder] {
        let baseCount = 6 + (surah.index % 5) * 2
        return (1...baseCount).map { AyahPlaceholder(number: $0) }
    }

    private static func scrollIdentifier(for ayahNumber: Int, in ayahs: [AyahPlaceholder]) -> UUID? {
        if let match = ayahs.first(where: { $0.number == ayahNumber }) {
            return match.id
        }
        return ayahs.last?.id
    }

    private func scrollTo(_ id: UUID, using proxy: ScrollViewProxy) {
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

    private var backNavigationGesture: some Gesture {
        DragGesture(minimumDistance: 40, coordinateSpace: .local)
            .onEnded { value in
                guard !readerStore.isFullScreen else { return }

                let horizontalTranslation = value.translation.width
                let verticalTranslation = abs(value.translation.height)

                if horizontalTranslation > 80, horizontalTranslation > verticalTranslation {
                    navigateBackToSurahs()
                }
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

struct AyahPlaceholder: Identifiable, Hashable {
    let id = UUID()
    let number: Int
}

struct SurahPlaceholder: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let index: Int

    static let examples: [SurahPlaceholder] = [
        SurahPlaceholder(name: "Al-Fātiḥah", index: 1),
        SurahPlaceholder(name: "Al-Baqarah", index: 2),
        SurahPlaceholder(name: "Āl ʿImrān", index: 3),
        SurahPlaceholder(name: "An-Nisāʾ", index: 4),
        SurahPlaceholder(name: "Al-Mā'idah", index: 5),
        SurahPlaceholder(name: "Al-An'ām", index: 6),
        SurahPlaceholder(name: "Al-A'rāf", index: 7),
        SurahPlaceholder(name: "Al-Anfāl", index: 8),
        SurahPlaceholder(name: "Al-Kahf", index: 18)
    ]
}

struct ReaderDestination {
    let surah: SurahPlaceholder
    let ayah: Int
}

extension SurahPlaceholder {
    var vietnameseName: String {
        if let mapped = Self.vietnameseTitles[index] {
            return mapped
        }
        return name
    }

    private static let vietnameseTitles: [Int: String] = [
        1: "Al-Fātiḥah — Lời Mở Đầu",
        2: "Al-Baqarah — Con Bò Cái",
        3: "Āl ʿImrān — Gia Đình Imran",
        4: "An-Nisāʾ — Phụ Nữ",
        5: "Al-Mā'idah — Bàn Tiệc",
        6: "Al-An'ām — Đàn Gia Súc",
        7: "Al-A'rāf — Thành Trì Cao",
        8: "Al-Anfāl — Chiến Lợi Phẩm",
        18: "Al-Kahf — Hang Động"
    ]
}
