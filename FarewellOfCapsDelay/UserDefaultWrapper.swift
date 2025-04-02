// From my personal library

import Foundation

/// A property wrapper that saves wrapped value automatically to user defaults.
///
/// A property wrapped by this wrapper is automatically saved to user defaults. Every time you change the value, saves will be automatically done. After the property initialization, the value will be loaded value or `nil` if there's no saved value.
///
/// The wrapped type must be `Optional` and conforms to ``UserDefaultApplicable`` which implements saving and loading methods to user defaults.
/// `Int`, `Double`, `Bool`, `String`, `Array`, `Dictionary`, `Set`, `URL` conforms to ``UserDefaultApplicable`` by default.
///
/// ```swift
/// @UserDefault(key: "com.GST.sample.testInteger")
/// var testInteger: Int?
///
/// // This value will be saved.
/// testInteger = 100
/// ```
/// In example, `testInteger` have `100` or `nil` on declaration.
///
/// ## Limitation
/// - `Dictionary`'s `Key` must be `String`.
/// - `Array` and `Set`'s `Element` must not be optional. (There's no contraints about those demands)
@propertyWrapper
public struct UserDefault<T> where T: UserDefaultApplicable {
    public var key: String
    private let userDefaults = UserDefaults.standard
    
    public init<S>(key: String) where T == Optional<S> {
        self.key = key
        self.savedValue = T.load(userDefaults: userDefaults, key: key, default: nil)
    }
    
    public init(wrappedValue: T, key: String) {
        self.key = key
        if let saved = T.load(userDefaults: userDefaults, key: key) {
            self.savedValue = saved
        } else {
            self.savedValue = wrappedValue
            T.save(newValue: wrappedValue, userDefaults: userDefaults, key: key)
        }
    }
    
    private var savedValue: T {
        didSet {
            T.save(newValue: savedValue, userDefaults: userDefaults, key: key)
        }
    }
    
    public var wrappedValue: T {
        get {
            return savedValue
        }
        set {
            savedValue = newValue
        }
    }
}

/// Rrequirements to wrap a property with ``UserDefault``.
///
/// Conform to this protocol to apply ``UserDefault`` property wrapper. The value must be the conforming type itself.
public protocol UserDefaultApplicable where T == Self {
    associatedtype T
    /// Save a new value to user defaults.
    ///
    /// This function is called every time you changed the wrapped value.
    static func save(newValue: T, userDefaults: UserDefaults, key: String)
    
    /// Load a saved value in user defaults.
    ///
    /// This function is called at initialization of a wrapped variable.
    static func load(userDefaults: UserDefaults, key: String, default: T) -> T
    
    /// Load a saved value in user defaults.
    ///
    /// This function is called at initialization of a wrapped variable.
    static func load(userDefaults: UserDefaults, key: String) -> T?
}

public extension UserDefaultApplicable {
    static func load(userDefaults: UserDefaults, key: String, default: T) -> T {
        if let saved = T.load(userDefaults: userDefaults, key: key) {
            return saved
        } else {
            return `default`
        }
    }
}

/// Conformance to ``UserDefaultApplicable`` by built-in user defaults methods.
///
/// Do not conform to this protocol. This protocol serves default implementation of ``UserDefaultApplicable`` to some built-in types like `Int`, `String`, etc.
/// - Note: Even though some `NSObjects`, such as `NSNumber` or `NSDate`, can be saved to user defaults, those types are not conforms to this protocol. This is limitation of Swift that non-final classes can not conform any protocol which has `T == Self` generic constraints.
public protocol _UserDefaultApplicableDefault: UserDefaultApplicable {
    
}
public extension _UserDefaultApplicableDefault {
    static func save(newValue: T, userDefaults: UserDefaults, key: String) {
        userDefaults.set(newValue, forKey: key)
    }
    
    static func load(userDefaults: UserDefaults, key: String) -> T? {
        let value = userDefaults.value(forKey: key) as! T?
        if let value {
            return value
        } else {
            return nil
        }
    }
}

extension Bool: _UserDefaultApplicableDefault {}
extension Int: _UserDefaultApplicableDefault {}
extension Int8: _UserDefaultApplicableDefault {}
extension Int16: _UserDefaultApplicableDefault {}
extension Int32: _UserDefaultApplicableDefault {}
extension Int64: _UserDefaultApplicableDefault {}
extension UInt: _UserDefaultApplicableDefault {}
extension UInt8: _UserDefaultApplicableDefault {}
extension UInt16: _UserDefaultApplicableDefault {}
extension UInt32: _UserDefaultApplicableDefault {}
extension UInt64: _UserDefaultApplicableDefault {}
extension Double: _UserDefaultApplicableDefault {}
extension Float: _UserDefaultApplicableDefault {}
extension Dictionary: UserDefaultApplicable where Key == String, Value: UserDefaultApplicable {}
extension Dictionary: _UserDefaultApplicableDefault where Key == String, Value: UserDefaultApplicable {}
extension Array: _UserDefaultApplicableDefault {}
extension String: _UserDefaultApplicableDefault {}
extension Date: _UserDefaultApplicableDefault {}

extension URL: UserDefaultApplicable {
    public static func save(newValue: URL, userDefaults: UserDefaults, key: String) {
        userDefaults.set(newValue, forKey: key)
    }
    
    public static func load(userDefaults: UserDefaults, key: String) -> URL? {
        let value = userDefaults.url(forKey: key)
        if let value {
            return value
        } else {
            return nil
        }
    }
}

extension Set: UserDefaultApplicable {
    public static func save(newValue: Set<Element>, userDefaults: UserDefaults, key: String) {
        userDefaults.set(Array(newValue), forKey: key)
    }
    
    public static func load(userDefaults: UserDefaults, key: String) -> Set<Element>? {
        let value = userDefaults.array(forKey: key) as! [Element]?
        if let value {
            return Set(value)
        } else {
            return nil
        }
    }
}

extension Optional: UserDefaultApplicable where Wrapped: UserDefaultApplicable {
    public static func save(newValue: Wrapped?, userDefaults: UserDefaults, key: String) {
        if let newValue {
            Wrapped.save(newValue: newValue, userDefaults: userDefaults, key: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    public static func load(userDefaults: UserDefaults, key: String) -> Wrapped?? {
        if let saved = Wrapped.load(userDefaults: userDefaults, key: key) {
            return saved
        } else {
            return nil as Wrapped??
        }
    }
    
    public static func load(userDefaults: UserDefaults, key: String, default: T = nil) -> Wrapped? {
        return Wrapped.load(userDefaults: userDefaults, key: key)
    }
}
