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

        let store = PreferenceStore(repository: mock)
        #expect(store.enablediCloud)
        #expect(!store.enabledAutoSave)
        #expect(!store.enabledInfiniteScroll)
        #expect(store.appearanceMode == .dark)
        #expect(mock.setEnablediCloudCalls.isEmpty)
        #expect(mock.setEnabledAutoSaveCalls.isEmpty)
        #expect(mock.setEnabledInfiniteScrollCalls.isEmpty)
        #expect(mock.setAppearanceModeCalls.isEmpty)
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
