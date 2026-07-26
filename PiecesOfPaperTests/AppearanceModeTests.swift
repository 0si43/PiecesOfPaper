import Testing
import SwiftUI
@testable import Pieces_of_Paper

struct AppearanceModeTests {
    // The raw values are the UserDefaults payload: renaming a case silently
    // resets every existing choice to .system
    @Test func test_rawValues_areStable() {
        #expect(AppearanceMode.system.rawValue == "system")
        #expect(AppearanceMode.light.rawValue == "light")
        #expect(AppearanceMode.dark.rawValue == "dark")
    }

    @Test func test_colorScheme_isNilOnlyForSystem() {
        #expect(AppearanceMode.system.colorScheme == nil)
        #expect(AppearanceMode.light.colorScheme == .light)
        #expect(AppearanceMode.dark.colorScheme == .dark)
    }

    @Test func test_allCases_areOfferedInSystemLightDarkOrder() {
        #expect(AppearanceMode.allCases == [.system, .light, .dark])
    }
}
