import Foundation

struct SendMarker: Equatable {
    let isLoaded: Bool
    let count: Int

    func follows(_ previous: SendMarker) -> Bool {
        previous.isLoaded && isLoaded && count > previous.count
    }
}
