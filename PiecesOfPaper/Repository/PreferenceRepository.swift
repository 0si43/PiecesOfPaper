import Foundation

protocol PreferenceRepositoryProtocol {
    func getEnablediCloud() -> Bool
    func setEnablediCloud(_ value: Bool)
    func getEnabledAutoSave() -> Bool
    func setEnabledAutoSave(_ value: Bool)
    func getEnabledInfiniteScroll() -> Bool
    func setEnabledInfiniteScroll(_ value: Bool)
    func getAppearanceMode() -> AppearanceMode
    func setAppearanceMode(_ value: AppearanceMode)
    func getListOrder(directoryName: String) -> ListOrder
    func setListOrder(directoryName: String, listOrder: ListOrder)
}

struct PreferenceRepository: PreferenceRepositoryProtocol {
    private let iCloudDisabledKey = "iCloud_disabled"
    private let autoSaveDisabledKey = "autosave_disabled"
    private let infiniteScrollKey = "infinite_scroll_disabled"
    private let appearanceModeKey = "appearance_mode"
    private let listOrderKey = "com.pop.listOrder."

    func getEnablediCloud() -> Bool {
        !UserDefaults.standard.bool(forKey: iCloudDisabledKey)
    }

    func setEnablediCloud(_ value: Bool) {
        UserDefaults.standard.set(!value, forKey: iCloudDisabledKey)
    }

    func getEnabledAutoSave() -> Bool {
        !UserDefaults.standard.bool(forKey: autoSaveDisabledKey)
    }

    func setEnabledAutoSave(_ value: Bool) {
        UserDefaults.standard.set(!value, forKey: autoSaveDisabledKey)
    }

    func getEnabledInfiniteScroll() -> Bool {
        !UserDefaults.standard.bool(forKey: infiniteScrollKey)
    }

    func setEnabledInfiniteScroll(_ value: Bool) {
        UserDefaults.standard.set(!value, forKey: infiniteScrollKey)
    }

    // Stored as its raw value, not through the Bool keys' "*_disabled" inversion
    // (that trick only makes UserDefaults' false default mean "enabled") nor the
    // JSONEncoder path ListOrder needs: an absent string already means .system
    func getAppearanceMode() -> AppearanceMode {
        guard let rawValue = UserDefaults.standard.string(forKey: appearanceModeKey) else { return .system }
        return AppearanceMode(rawValue: rawValue) ?? .system
    }

    func setAppearanceMode(_ value: AppearanceMode) {
        UserDefaults.standard.set(value.rawValue, forKey: appearanceModeKey)
    }

    func getListOrder(directoryName: String) -> ListOrder {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: listOrderKey + directoryName),
           let listOrder = try? decoder.decode(ListOrder.self, from: data) {
            return listOrder
        } else {
            return ListOrder()
        }
    }

    func setListOrder(directoryName: String, listOrder: ListOrder) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(listOrder) else { return }
        UserDefaults.standard.set(data, forKey: listOrderKey + directoryName)
    }
}
