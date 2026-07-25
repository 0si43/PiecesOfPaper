import Foundation

/// Why the app is (or is not) using iCloud storage right now.
/// Pure decision logic; live system inputs come from `UbiquityStatusProviding`.
enum CloudAvailability: Equatable {
    case available
    case userDisabled
    case signedOut
    case driveUnavailable

    static func determine(enablediCloud: Bool, hasAccount: Bool, containerUrl: URL?) -> CloudAvailability {
        guard enablediCloud else { return .userDisabled }
        guard hasAccount else { return .signedOut }
        return containerUrl != nil ? .available : .driveUnavailable
    }

    /// iCloud is on in app settings but notes are effectively local
    var isDegraded: Bool {
        self == .signedOut || self == .driveUnavailable
    }
}

protocol UbiquityStatusProviding {
    var hasAccount: Bool { get }
    var containerUrl: URL? { get }
}

struct UbiquityStatusProvider: UbiquityStatusProviding {
    var hasAccount: Bool { FileManager.default.ubiquityIdentityToken != nil }
    var containerUrl: URL? { FilePath.iCloudUrl }
}
