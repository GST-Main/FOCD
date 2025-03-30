import ApplicationServices
import os

struct UIElement {
    var raw: AXUIElement
    var pid: pid_t {
        var id: pid_t = -1
        AXUIElementGetPid(raw, &id)
        return id
    }
    static let logger = Logger(subsystem: "FOCD", category: "UIElement")

    init(_ rawObject: AXUIElement) {
        self.raw = rawObject
    }
    
    private var attributeNamesCFString: [CFString] {
        var names: CFArray?
        let error = AXUIElementCopyAttributeNames(raw, &names)
        
        if error == .noValue || error == .attributeUnsupported {
            return []
        }
        
        guard error == .success else {
            Self.logger.error("Failed to get AX attribute names in PID \(pid): \(error)")
            return []
        }
        
        guard let names = names as? [CFString] else {
            Self.logger.error("Cating failed in PID \(pid)")
            return []
        }
        
        return names
    }
    
    var attributeNames: [String] {
        return attributeNamesCFString as [String]
    }
    
    var attributes: [AttributeName: Any?] {
        let attributes = attributeNames.map { attribute -> (AttributeName, Any?) in
            var cfObject: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(raw, attribute as CFString, &cfObject)
            var value: Any?
            if result == .success, let cfObject {
                value = Self.unpack(cfObject)
            } else if result == .noValue {
                value = nil
            }
            
            return (AttributeName(attribute), value)
        }
        
        return Dictionary(uniqueKeysWithValues: attributes)
    }
}

extension UIElement {
    fileprivate static func unpack(_ cfObject: CFTypeRef) -> Any {
        if let stringValue = cfObject as? String {
            return stringValue
        } else if let booleanValue = cfObject as? Bool {
            return booleanValue
        } else if let intValue = cfObject as? Int {
            return intValue
        } else if let doubleValue = cfObject as? Double {
            return doubleValue
        } else if let urlValue = cfObject as? URL {
            return urlValue
        } else if let arrayValue = cfObject as? [AnyObject] {
            return arrayValue.map(unpack)
        } else {
            let typeID = CFGetTypeID(cfObject)
            switch typeID {
            case AXUIElementGetTypeID():
                return UIElement(cfObject as! AXUIElement)
            case AXValueGetTypeID():
                let type = AXValueGetType(cfObject as! AXValue)
                switch type {
                case .axError:
                    var temp: AXError = .success
                    guard AXValueGetValue(cfObject as! AXValue, type, &temp) else {
                        return cfObject
                    }
                    return temp
                case .cfRange:
                    var temp: CFRange = CFRange()
                    guard AXValueGetValue(cfObject as! AXValue, type, &temp) else {
                        return cfObject
                    }
                    return temp
                case .cgPoint:
                    var temp: CGPoint = CGPoint.zero
                    guard AXValueGetValue(cfObject as! AXValue, type, &temp) else {
                        return cfObject
                    }
                    return temp
                case .cgRect:
                    var temp: CGRect = CGRect.zero
                    guard AXValueGetValue(cfObject as! AXValue, type, &temp) else {
                        return cfObject
                    }
                    return temp
                case .cgSize:
                    var temp: CGSize = CGSize.zero
                    guard AXValueGetValue(cfObject as! AXValue, type, &temp) else {
                        return cfObject
                    }
                    return temp
                case .illegal:
                    return "ILLEGAL"
                @unknown default:
                    return cfObject
                }
            default:
                return cfObject
            }
        }
    }
}

extension UIElement: CustomStringConvertible {
    var description: String {
        let role = attributes[.role] as? String ?? "Unknown"
        return "UIElement<\(role)>"
    }
}

extension UIElement {
    struct AttributeName: RawRepresentable, Hashable {
        let rawValue: String
        
        init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension UIElement.AttributeName: ExpressibleByStringLiteral, CustomStringConvertible {
    public init(stringLiteral value: String) {
        self.init(value)
    }
    
    public var description: String {
        self.rawValue
    }
}

extension UIElement.AttributeName {
    // Known names
    /// `String`
    static let id: Self = "AXIdentifier"
    /// `Bool`
    static let main: Self = "AXMain"
    /// ?
    static let proxy: Self = "AXProxy"
    /// ``UIElement``
    static let parent: Self = "AXParent"
    /// `[UIElement]`
    static let children: Self = "AXChildren"
    /// `[UIElement]`
    static let childrenInNavigationOrder: Self = "AXChildrenInNavigationOrder"
    /// `String`
    static let title: Self = "AXTitle"
    static let titleUIElement: Self = "AXTitleUIElement"
    /// `String`
    static let role: Self = "AXRole"
    /// `String`
    static let roleDescription: Self = "AXRoleDescription"
    /// `String`
    static let subrole: Self = "AXSubrole"
    
    /// `CGSize`
    static let size: Self = "AXSize"
    /// `CGFrame`
    static let frame: Self = "AXFrame"
    /// `CGPoint`
    static let position: Self = "AXPosition"
    /// `CGFrame` maybe
    static let growArea: Self = "AXGrowArea"
    /// `CGPoint`
    static let activationPoint: Self = "AXActivationPoint"
    /// `Bool`
    static let focused: Self = "AXFocused"
    
    static let defaultButton: Self = "AXDefaultButton"
    static let cancelButton: Self = "AXCancelButton"
    static let fullScreenButton: Self = "AXFullScreenButton"
    static let minimizeButton: Self = "AXMinimizeButton"
    static let closeButton: Self = "AXCloseButton"
    static let zoomButton: Self = "AXZoomButton"
    static let toolbarButton: Self = "AXToolbarButton"

    static let fullScreen: Self = "AXFullScreen"
    static let minimized: Self = "AXMinimized"
    static let modal: Self = "AXModal"
    
    static let document: Self = "AXDocument"
    static let sections: Self = "AXSections"
}
