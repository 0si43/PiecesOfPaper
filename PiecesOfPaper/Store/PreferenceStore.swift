import Foundation

@Observable
@MainActor
final class PreferenceStore {
    private let repository: PreferenceRepositoryProtocol
    private let ubiquityStatus: UbiquityStatusProviding

    var enablediCloud: Bool {
        didSet {
            repository.setEnablediCloud(enablediCloud)
            FilePath.makeDirectoryIfNeeded()
            refreshCloudAvailability()
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

    // Stored, not computed: the system inputs (account, container URL) are not
    // observable, so views would never re-render on a computed property
    private(set) var cloudAvailability: CloudAvailability = .userDisabled

    init(repository: PreferenceRepositoryProtocol = PreferenceRepository(),
         ubiquityStatus: UbiquityStatusProviding = UbiquityStatusProvider()) {
        self.repository = repository
        self.ubiquityStatus = ubiquityStatus
        self.enablediCloud = repository.getEnablediCloud()
        self.enabledAutoSave = repository.getEnabledAutoSave()
        self.enabledInfiniteScroll = repository.getEnabledInfiniteScroll()
        refreshCloudAvailability()
    }

    func refreshCloudAvailability() {
        cloudAvailability = CloudAvailability.determine(enablediCloud: enablediCloud,
                                                        hasAccount: ubiquityStatus.hasAccount,
                                                        containerUrl: ubiquityStatus.containerUrl)
    }
}
