import Foundation

enum ScannerState: Equatable {
    case preparing
    case scanning
    case denied
    case unavailable
}
