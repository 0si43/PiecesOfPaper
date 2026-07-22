import Foundation

@Observable
@MainActor
final class PreferenceStore {
    private let repository: PreferenceRepositoryProtocol

    var enablediCloud: Bool {
        didSet {
            repository.setEnablediCloud(enablediCloud)
            FilePath.makeDirectoryIfNeeded()
        }
    }

    var enabledAutoSave: Bool {
        didSet {
            repository.setEnabledAutoSave(enabledAutoSave)
        }
    }

    var enabledInfiniteScroll: Bool {
        didSet {
            repository.setEnabledInfiniteScroll(enabledInfiniteScroll)
        }
    }

    var shouldGrantiCloud: Bool {
        guard enablediCloud else { return false }
        return FileManager.default.ubiquityIdentityToken == nil
    }

    init(repository: PreferenceRepositoryProtocol = PreferenceRepository()) {
        self.repository = repository
        self.enablediCloud = repository.getEnablediCloud()
        self.enabledAutoSave = repository.getEnabledAutoSave()
        self.enabledInfiniteScroll = repository.getEnabledInfiniteScroll()
    }
}
