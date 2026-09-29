import Foundation

public enum AIError: Error, LocalizedError {
    case invalidRequest
    case authenticationFailed
    case networkUnavailable
    case rateLimited
    case serverError
    case invalidResponse
    case contentUnavailable
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "The request was invalid."
        case .authenticationFailed:
            return "Authentication failed. Please check your connection."
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError:
            return "The AI service is currently unavailable. Please try again later."
        case .invalidResponse:
            return "Received an unexpected response from the AI service."
        case .contentUnavailable:
            return "The requested content is currently unavailable."
        case .timeout:
            return "The request timed out. Please try again."
        }
    }
}
