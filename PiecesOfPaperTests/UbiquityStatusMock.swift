import Foundation
@testable import Pieces_of_Paper

struct UbiquityStatusMock: UbiquityStatusProviding {
    var hasAccount = true
    var containerUrl: URL? = URL(fileURLWithPath: "/container/Documents")
}
