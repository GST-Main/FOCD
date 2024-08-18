import Cocoa
import InputMethodKit

final class InputSourceManager {
    static var currentInputSource: Language {
        if Language.korean.inputSource!.isSelected {
            return .korean
        } else if Language.english.inputSource!.isSelected {
            return .english
        } else if Language.japanese.inputSource?.isSelected == true {
            return .japanese
        } else {
            logger.error("Failed to retrieve current input source.")
            return .english
        }
    }
    
    static func setInputSource(as language: Language) {
        if language == .japanese {
            guard Language.japanese.inputSource != nil else {
                logger.error("Attempted to set Japanese input source but could not find it.")
                return
            }
        }
        TISSelectInputSource(language.inputSource!)
    }
    
    struct Language: Equatable {
        let inputSource: TISInputSource?
        
        private init(_ inputSource: TISInputSource?) {
            self.inputSource = inputSource
        }
        
        private static let inputSources = {
            let inputSources = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
            return inputSources
        }()
        
        static let korean = {
            guard let inputSource = inputSources.first(where: { $0.id == "com.apple.inputmethod.Korean.2SetKorean" }) else {
                logger.fault("Failed to find Korean input source from list.")
                fatalError("Failed to find Korean input source from list.")
            }
            return Language(inputSource)
        }()
        static let english = {
            guard let inputSource = inputSources.first(where: { $0.id == "com.apple.keylayout.ABC" }) else {
                logger.fault("Failed to find Korean input source from list.")
                fatalError("Failed to find Korean input source from list.")
            }
            return Language(inputSource)
        }()
        static let japanese = {
            let inputSource = inputSources.first { $0.id == "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese" }
            if inputSource == nil {
                logger.info("No Japanese input source in list.")
            }
            return Language(inputSource)
        }()
    }
}


extension TISInputSource {
    private func getProperty(_ key: CFString) -> AnyObject? {
        guard let cfType = TISGetInputSourceProperty(self, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var category: String {
        return getProperty(kTISPropertyInputSourceCategory) as! String
    }

    var isKeyboardInputSource: Bool {
        return category == (kTISCategoryKeyboardInputSource as String)
    }

    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }

    var isSelected: Bool {
        return getProperty(kTISPropertyInputSourceIsSelected) as! Bool
    }

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }

    var isCJKV: Bool {
        if let lang = sourceLanguages.first {
            return ["ko", "ja", "vi"].contains(lang) || lang.hasPrefix("zh")
        }
        return false
    }
}
