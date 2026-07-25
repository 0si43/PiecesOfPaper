import Testing
import Foundation
@testable import Pieces_of_Paper

struct CloudAvailabilityTests {
    private static let containerUrl = URL(fileURLWithPath: "/container/Documents")

    @Test func determine_isUserDisabled_wheneverToggleIsOff() {
        for hasAccount in [true, false] {
            for containerUrl in [Self.containerUrl, nil] {
                let availability = CloudAvailability.determine(enablediCloud: false,
                                                               hasAccount: hasAccount,
                                                               containerUrl: containerUrl)
                #expect(availability == .userDisabled)
            }
        }
    }

    @Test func determine_isSignedOut_whenToggleOnButNoAccount() {
        for containerUrl in [Self.containerUrl, nil] {
            let availability = CloudAvailability.determine(enablediCloud: true,
                                                           hasAccount: false,
                                                           containerUrl: containerUrl)
            #expect(availability == .signedOut)
        }
    }

    @Test func determine_isDriveUnavailable_whenAccountExistsButContainerMissing() {
        let availability = CloudAvailability.determine(enablediCloud: true,
                                                       hasAccount: true,
                                                       containerUrl: nil)
        #expect(availability == .driveUnavailable)
    }

    @Test func determine_isAvailable_whenAllConditionsMet() {
        let availability = CloudAvailability.determine(enablediCloud: true,
                                                       hasAccount: true,
                                                       containerUrl: Self.containerUrl)
        #expect(availability == .available)
    }

    @Test func isDegraded_isTrueOnlyWheniCloudIsOnButUnusable() {
        #expect(CloudAvailability.signedOut.isDegraded)
        #expect(CloudAvailability.driveUnavailable.isDegraded)
        #expect(!CloudAvailability.available.isDegraded)
        #expect(!CloudAvailability.userDisabled.isDegraded)
    }
}
