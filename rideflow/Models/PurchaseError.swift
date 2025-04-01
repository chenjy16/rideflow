import Foundation

enum PurchaseError: LocalizedError {
    case initializationError(String)
    case userCancelled
    case pending
    case failed(Error)
    case unknown
    case networkError
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .initializationError(let message):
            return "Initialization failed: \(message)"
        case .userCancelled:
            return "Purchase canceled"
        case .pending:
            return "Purchase is in progress"
        case .failed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .unknown:
            return "Unknown error"
        case .networkError:
            return "Network connection error"
        case .verificationFailed:
            return "Purchase verification failed"
        }
    }
}
