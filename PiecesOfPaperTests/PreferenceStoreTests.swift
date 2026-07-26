import Testing
@testable import Pieces_of_Paper

@MainActor
struct PreferenceStoreTests {
    @Test func test_init_readsValuesWithoutRePersisting() {
        let mock = PreferenceRepositoryMock()
        mock.enablediCloud = true
        mock.enabledAutoSave = false
        mock.enabledInfiniteScroll = false
        mock.appearanceMode = .dark
        mock.lastSeenWhatsNewVersion = "4.0.0"

        let store = PreferenceStore(repository: mock)
        #expect(store.enablediCloud)
        #expect(!store.enabledAutoSave)
        #expect(!store.enabledInfiniteScroll)
        #expect(store.appearanceMode == .dark)
        #expect(store.lastSeenWhatsNewVersion == "4.0.0")
        #expect(mock.setEnablediCloudCalls.isEmpty)
        #expect(mock.setEnabledAutoSaveCalls.isEmpty)
        #expect(mock.setEnabledInfiniteScrollCalls.isEmpty)
        #expect(mock.setAppearanceModeCalls.isEmpty)
        #expect(mock.setLastSeenWhatsNewVersionCalls.isEmpty)
    }

    @Test func test_enablediCloud_persistsOnChange() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        store.enablediCloud = true
        #expect(mock.setEnablediCloudCalls == [true])
        #expect(mock.getEnablediCloud())
    }

    @Test func test_enabledAutoSave_persistsOnChange() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        store.enabledAutoSave = false
        #expect(mock.setEnabledAutoSaveCalls == [false])
        #expect(!mock.getEnabledAutoSave())
    }

    @Test func test_enabledInfiniteScroll_persistsOnChange() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        store.enabledInfiniteScroll = false
        #expect(mock.setEnabledInfiniteScrollCalls == [false])
        #expect(!mock.getEnabledInfiniteScroll())
    }

    @Test func test_appearanceMode_persistsOnChange() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        store.appearanceMode = .light
        #expect(mock.setAppearanceModeCalls == [.light])
        #expect(mock.getAppearanceMode() == .light)
    }

    @Test func test_markWhatsNewSeen_persistsTheVersion() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        store.markWhatsNewSeen(version: "4.0.0")
        #expect(store.lastSeenWhatsNewVersion == "4.0.0")
        #expect(mock.setLastSeenWhatsNewVersionCalls == ["4.0.0"])
        #expect(mock.getLastSeenWhatsNewVersion() == "4.0.0")
    }

    @Test func test_markWhatsNewSeen_clearsTheUnseenFlag() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        #expect(store.hasUnseenWhatsNew(latestVersion: "4.0.0"))
        store.markWhatsNewSeen(version: "4.0.0")
        #expect(!store.hasUnseenWhatsNew(latestVersion: "4.0.0"))
    }

    // An absent key is what an upgrade from a version without the page looks like
    @Test func test_hasUnseenWhatsNew_isTrue_whenNothingSeenYet() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        #expect(store.hasUnseenWhatsNew(latestVersion: "4.0.0"))
    }

    @Test func test_hasUnseenWhatsNew_isFalse_whenLatestAlreadySeen() {
        let mock = PreferenceRepositoryMock()
        mock.lastSeenWhatsNewVersion = "4.0.0"
        let store = PreferenceStore(repository: mock)
        #expect(!store.hasUnseenWhatsNew(latestVersion: "4.0.0"))
    }

    @Test func test_hasUnseenWhatsNew_isTrue_whenOnlyAnOlderVersionSeen() {
        let mock = PreferenceRepositoryMock()
        mock.lastSeenWhatsNewVersion = "4.0.0"
        let store = PreferenceStore(repository: mock)
        #expect(store.hasUnseenWhatsNew(latestVersion: "4.1.0"))
    }

    @Test func test_cloudAvailability_isUserDisabled_wheniCloudToggleOff() {
        let mock = PreferenceRepositoryMock()
        mock.enablediCloud = false
        let store = PreferenceStore(repository: mock, ubiquityStatus: UbiquityStatusMock())
        #expect(store.cloudAvailability == .userDisabled)
    }

    @Test func test_cloudAvailability_isSignedOut_whenNoAccount() {
        let mock = PreferenceRepositoryMock()
        mock.enablediCloud = true
        let store = PreferenceStore(repository: mock,
                                    ubiquityStatus: UbiquityStatusMock(hasAccount: false, containerUrl: nil))
        #expect(store.cloudAvailability == .signedOut)
    }

    @Test func test_cloudAvailability_isDriveUnavailable_whenContainerMissing() {
        let mock = PreferenceRepositoryMock()
        mock.enablediCloud = true
        let store = PreferenceStore(repository: mock,
                                    ubiquityStatus: UbiquityStatusMock(hasAccount: true, containerUrl: nil))
        #expect(store.cloudAvailability == .driveUnavailable)
    }

    @Test func test_cloudAvailability_isAvailable_whenAllConditionsMet() {
        let mock = PreferenceRepositoryMock()
        mock.enablediCloud = true
        let store = PreferenceStore(repository: mock, ubiquityStatus: UbiquityStatusMock())
        #expect(store.cloudAvailability == .available)
    }

    @Test func test_cloudAvailability_refreshesWhenToggleChanges() {
        let mock = PreferenceRepositoryMock()
        mock.enablediCloud = false
        let store = PreferenceStore(repository: mock, ubiquityStatus: UbiquityStatusMock())
        #expect(store.cloudAvailability == .userDisabled)
        store.enablediCloud = true
        #expect(store.cloudAvailability == .available)
    }
}
