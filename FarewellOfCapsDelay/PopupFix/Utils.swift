import ApplicationServices

extension AXError: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
            case .success: "success"
            case .failure: "failure"
            case .illegalArgument: "illegalArgument"
            case .invalidUIElement: "invalidUIElement"
            case .invalidUIElementObserver: "invalidUIElementObserver"
            case .cannotComplete: "cannotComplete"
            case .attributeUnsupported: "attributeUnsupported"
            case .actionUnsupported: "actionUnsupported"
            case .notificationUnsupported: "notificationUnsupported"
            case .notImplemented: "notImplemented"
            case .notificationAlreadyRegistered: "notificationAlreadyRegistered"
            case .notificationNotRegistered: "notificationNotRegistered"
            case .apiDisabled: "apiDisabled"
            case .noValue: "noValue"
            case .parameterizedAttributeUnsupported: "parameterizedAttributeUnsupported"
            case .notEnoughPrecision: "notEnoughPrecision"
            @unknown default: "fuck"
        }
    }
}

extension Date {
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSS"
        return formatter
    }()
    
    var timestamp: String {
        return Self.timestampFormatter.string(from: self)
    }
}
