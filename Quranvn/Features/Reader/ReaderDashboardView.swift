import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

struct ReaderDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedSurah: SurahPlaceholder
    @State private var ayahs: [AyahPlaceholder]
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

    private let surahOptions = SurahPlaceholder.examples

    init() {
        let initialSurah = SurahPlaceholder.examples.first ?? SurahPlaceholder(name: "Placeholder", index: 1)
        _selectedSurah = State(initialValue: initialSurah)
        _ayahs = State(initialValue: ReaderDashboardView.generateAyahs(for: initialSurah))
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: DesignTokens.Spacing.lg) {
                ReaderToolbar()

                ScrollView {
                    LazyVStack(spacing: readerStore.isFlowMode ? DesignTokens.Spacing.md : DesignTokens.Spacing.lg) {
                        surahHeader
                        ForEach(ayahs) { ayah in
                            ayahCard(for: ayah)
                        }
                    }
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.top, DesignTokens.Spacing.xl)
        }
        .ignoresSafeArea(edges: readerStore.isFullScreen ? .all : .horizontal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: DesignTokens.Spacing.md) {
                if appState.showMiniPlayer {
                    MiniPlayerBar {
                        isShowingFullPlayer = true
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                SurahDock(
                    surahs: surahOptions,
                    selectedSurah: $selectedSurah
                ) { surah in
                    updateAyahs(for: surah)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.lg)
            .background(.clear)
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
        .navigationDestination(isPresented: $isShowingFullPlayer) {
            FullPlayerView()
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

    private func ayahCard(for ayah: AyahPlaceholder) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    if readerStore.showArabic {
                        Text("آية Placeholder #\(ayah.number)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(primaryText)
                    }

                    if readerStore.showVietnamese {
                        Text("Đây là đoạn văn mô phỏng cho câu số \(ayah.number).")
                            .font(translationFont)
                            .foregroundStyle(translationText)
                            .lineSpacing(4)
                    }

                    if readerStore.showEnglish {
                        Text("This is placeholder translation content for ayah \(ayah.number).")
                            .font(translationFont)
                            .foregroundStyle(translationText)
                            .lineSpacing(4)
                    }
                }

                Spacer(minLength: DesignTokens.Spacing.sm)

                Image(systemName: "heart.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.pink)
                    .opacity(favoriteAyahs.contains(ayah.id) ? 1 : 0)
                    .scaleEffect(favoriteAyahs.contains(ayah.id) ? 1.1 : 0.5)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: favoriteAyahs.contains(ayah.id))
            }

            if let notes = ayahNotes[ayah.id], !notes.isEmpty {
                Divider()
                    .blendMode(.overlay)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    ForEach(Array(notes.enumerated()), id: \.offset) { entry in
                        Text("Note \(entry.offset + 1): \(entry.element)")
                            .font(.footnote)
                            .foregroundStyle(secondaryText.opacity(0.85))
                    }
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.large)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            toggleFavorite(for: ayah.id)
        }
        .contextMenu {
            Button {
                showToast(message: "No content yet")
            } label: {
                Label("Copy Ayah", systemImage: "doc.on.doc")
                    .foregroundStyle(secondaryText.opacity(0.6))
            }

            Button {
                safariURL = URL(string: "https://chat.openai.com")
                isShowingSafari = true
            } label: {
                Label("Ask ChatGPT", systemImage: "sparkles")
            }

            Button {
                prepareNote(for: ayah.id)
            } label: {
                Label("Add Note", systemImage: "square.and.pencil")
            }
        }
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

    private func updateAyahs(for surah: SurahPlaceholder) {
        selectedSurah = surah
        ayahs = ReaderDashboardView.generateAyahs(for: surah)
        favoriteAyahs.removeAll()
        ayahNotes.removeAll()
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
                Text("Add a Note")
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
            .navigationTitle("Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresentingNoteSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
            Text("Mode: \(readerStore.isFlowMode ? "Flow" : "Verse")")
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
        .system(size: readerStore.fontSize, weight: .regular, design: .default)
    }

    private static func generateAyahs(for surah: SurahPlaceholder) -> [AyahPlaceholder] {
        let baseCount = 6 + (surah.index % 5) * 2
        return (1...baseCount).map { AyahPlaceholder(number: $0) }
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
        SurahPlaceholder(name: "Al-Anfāl", index: 8)
    ]
}
