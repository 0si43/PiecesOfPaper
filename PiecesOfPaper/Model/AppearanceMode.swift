import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    // The case names are the persisted raw values, so the display text lives in
    // `label` instead: renaming a case would reset every stored choice to .system
    case system, light, dark

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
