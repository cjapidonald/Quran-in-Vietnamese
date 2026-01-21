import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

// MARK: - Reader Destination

/// Navigation destination for deep links and surah selection
struct ReaderDestination {
    let surahNumber: Int
    let ayah: Int
}

// MARK: - Safari View

#if canImport(SafariServices)
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#else
struct SafariView: View {
    let url: URL

    var body: some View {
        EmptyView()
    }
}
#endif
