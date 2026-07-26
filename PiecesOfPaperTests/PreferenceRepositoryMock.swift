import Foundation
@testable import Pieces_of_Paper

final class PreferenceRepositoryMock: PreferenceRepositoryProtocol {
    var enablediCloud = false
    var enabledAutoSave = true
    var enabledInfiniteScroll = true
    var appearanceMode: AppearanceMode = .system
    var lastSeenWhatsNewVersion: String?
    var listOrders: [String: ListOrder] = [:]
    private(set) var setEnablediCloudCalls: [Bool] = []
    private(set) var setEnabledAutoSaveCalls: [Bool] = []
    private(set) var setEnabledInfiniteScrollCalls: [Bool] = []
    private(set) var setAppearanceModeCalls: [AppearanceMode] = []
    private(set) var setLastSeenWhatsNewVersionCalls: [String] = []
    private(set) var setListOrderCalls: [(directoryName: String, listOrder: ListOrder)] = []

    func getEnablediCloud() -> Bool { enablediCloud }

    func setEnablediCloud(_ value: Bool) {
        enablediCloud = value
        setEnablediCloudCalls.append(value)
    }

    func getEnabledAutoSave() -> Bool { enabledAutoSave }

    func setEnabledAutoSave(_ value: Bool) {
        enabledAutoSave = value
        setEnabledAutoSaveCalls.append(value)
    }

    func getEnabledInfiniteScroll() -> Bool { enabledInfiniteScroll }

    func setEnabledInfiniteScroll(_ value: Bool) {
        enabledInfiniteScroll = value
        setEnabledInfiniteScrollCalls.append(value)
    }

    func getAppearanceMode() -> AppearanceMode { appearanceMode }

    func setAppearanceMode(_ value: AppearanceMode) {
        appearanceMode = value
        setAppearanceModeCalls.append(value)
    }

    func getLastSeenWhatsNewVersion() -> String? { lastSeenWhatsNewVersion }

    func setLastSeenWhatsNewVersion(_ value: String) {
        lastSeenWhatsNewVersion = value
        setLastSeenWhatsNewVersionCalls.append(value)
    }

    func getListOrder(directoryName: String) -> ListOrder {
        listOrders[directoryName] ?? ListOrder()
    }

    func setListOrder(directoryName: String, listOrder: ListOrder) {
        listOrders[directoryName] = listOrder
        setListOrderCalls.append((directoryName, listOrder))
    }
}
