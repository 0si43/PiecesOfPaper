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

    var appearanceMode: AppearanceMode {
        didSet {
            repository.setAppearanceMode(appearanceMode)
        }
    }

    // Written through markWhatsNewSeen instead of the didSet the other preferences use:
    // an optional is already initialized to nil before init runs, so the seeding
    // assignment below counts as a mutation and would re-persist on every launch
    private(set) var lastSeenWhatsNewVersion: String?

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
        self.appearanceMode = repository.getAppearanceMode()
        self.lastSeenWhatsNewVersion = repository.getLastSeenWhatsNewVersion()
        refreshCloudAvailability()
    }

    // Takes the version rather than reading ReleaseNote.all: the Store layer receives
    // Model values through the repository, and the rule stays testable against
    // orderings the shipped release list does not contain
    func hasUnseenWhatsNew(latestVersion: String) -> Bool {
        lastSeenWhatsNewVersion != latestVersion
    }

    func markWhatsNewSeen(version: String) {
        lastSeenWhatsNewVersion = version
        repository.setLastSeenWhatsNewVersion(version)
    }

    func refreshCloudAvailability() {
        cloudAvailability = CloudAvailability.determine(enablediCloud: enablediCloud,
                                                        hasAccount: ubiquityStatus.hasAccount,
                                                        containerUrl: ubiquityStatus.containerUrl)
    }
}
