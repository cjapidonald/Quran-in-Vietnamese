import Foundation
import Combine
import CloudKit

/// Coordinates all CloudKit sync operations
@MainActor
final class CloudKitCoordinator: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var lastSyncError: Error?

    private let favoritesSync: CloudKitFavoritesSync
    private let progressSync: CloudKitProgressSync
    private let cloudAuthManager: CloudAuthManager

    private var syncTask: Task<Void, Never>?
    private var autoSyncTimer: Timer?

    init(
        favoritesStore: FavoritesStore,
        progressStore: ReadingProgressStore,
        quranStore: QuranDataStore,
        cloudAuthManager: CloudAuthManager
    ) {
        self.favoritesSync = CloudKitFavoritesSync(favoritesStore: favoritesStore)
        self.progressSync = CloudKitProgressSync(progressStore: progressStore, quranStore: quranStore)
        self.cloudAuthManager = cloudAuthManager

        setupAutoSync()
    }

    deinit {
        autoSyncTimer?.invalidate()
        syncTask?.cancel()
    }

    // MARK: - Public API

    /// Sync all data (favorites, notes, progress)
    func syncAll(force: Bool = false) {
        // Cancel existing sync if running
        syncTask?.cancel()

        syncTask = Task {
            guard cloudAuthManager.isSignedIn else {
                print("⚠️ Not signed in, skipping sync")
                return
            }

            // Debounce: Don't sync if we just synced recently (unless forced)
            if !force, let lastSync = lastSyncDate, Date().timeIntervalSince(lastSync) < 30 {
                print("⏭️ Skipping sync - synced recently")
                return
            }

            isSyncing = true
            lastSyncError = nil

            do {
                // Run all syncs in parallel
                async let favSync = favoritesSync.syncAll()
                async let progSync = progressSync.syncAll()

                await favSync
                await progSync

                lastSyncDate = Date()
                print("✅ CloudKit sync completed successfully")
            } catch {
                lastSyncError = error
                print("❌ CloudKit sync failed: \(error.localizedDescription)")
            }

            isSyncing = false
        }
    }

    /// Sync only favorites and notes
    func syncFavoritesAndNotes() {
        guard cloudAuthManager.isSignedIn else { return }

        Task {
            do {
                try await favoritesSync.syncFavorites()
                try await favoritesSync.syncNotes()
                lastSyncDate = Date()
            } catch {
                lastSyncError = error
                print("❌ Favorites sync failed: \(error)")
            }
        }
    }

    /// Sync only reading progress
    func syncProgress() {
        guard cloudAuthManager.isSignedIn else { return }

        Task {
            do {
                try await progressSync.syncProgress()
                lastSyncDate = Date()
            } catch {
                lastSyncError = error
                print("❌ Progress sync failed: \(error)")
            }
        }
    }

    // MARK: - Individual Operations

    /// Upload a single favorite immediately
    func uploadFavorite(ayahID: String) {
        guard cloudAuthManager.isSignedIn else { return }

        Task {
            do {
                try await favoritesSync.uploadFavorite(ayahID: ayahID)
            } catch {
                print("❌ Failed to upload favorite \(ayahID): \(error)")
            }
        }
    }

    /// Delete a single favorite immediately
    func deleteFavorite(ayahID: String) {
        guard cloudAuthManager.isSignedIn else { return }

        Task {
            do {
                try await favoritesSync.deleteFavorite(ayahID: ayahID)
            } catch {
                print("❌ Failed to delete favorite \(ayahID): \(error)")
            }
        }
    }

    /// Upload a single note immediately
    func uploadNote(ayahID: String, noteText: String) {
        guard cloudAuthManager.isSignedIn else { return }

        Task {
            do {
                try await favoritesSync.uploadNote(ayahID: ayahID, noteText: noteText)
            } catch {
                print("❌ Failed to upload note for \(ayahID): \(error)")
            }
        }
    }

    /// Upload progress for a specific surah immediately
    func uploadProgress(for surah: Surah) {
        guard cloudAuthManager.isSignedIn else { return }

        Task {
            do {
                try await progressSync.uploadProgress(for: surah)
            } catch {
                print("❌ Failed to upload progress for Surah \(surah.number): \(error)")
            }
        }
    }

    // MARK: - Auto Sync

    private func setupAutoSync() {
        // Sync every 5 minutes when app is active
        autoSyncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.syncAll()
        }
    }

    func startAutoSync() {
        autoSyncTimer?.invalidate()
        setupAutoSync()
    }

    func stopAutoSync() {
        autoSyncTimer?.invalidate()
    }

    // MARK: - Lifecycle Hooks

    /// Call this when user signs in
    func handleSignIn() {
        print("🔄 User signed in - starting initial sync")
        syncAll(force: true)
        startAutoSync()
    }

    /// Call this when user signs out
    func handleSignOut() {
        print("🔄 User signed out - stopping auto sync")
        stopAutoSync()
        syncTask?.cancel()
        lastSyncDate = nil
        lastSyncError = nil
    }

    /// Call this when app becomes active
    func handleAppDidBecomeActive() {
        if cloudAuthManager.isSignedIn {
            syncAll()
        }
    }

    /// Call this when app will resign active
    func handleAppWillResignActive() {
        if cloudAuthManager.isSignedIn {
            // Do a final sync before going to background
            syncAll(force: true)
        }
    }
}
