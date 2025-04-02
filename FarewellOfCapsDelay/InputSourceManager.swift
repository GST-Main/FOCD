import Cocoa
import InputMethodKit

enum InputSourceManager {
    static var currentInputSource: Language {
        if Language.korean.inputSource!.isSelected {
            return .korean
        } else if Language.english.inputSource!.isSelected {
            return .english
        } else if Language.japanese.inputSource?.isSelected == true {
            return .japanese
        } else if Language.chinese.inputSource?.isSelected == true {
            return .chinese
        } else {
            logger.error("Failed to retrieve current input source.")
            return .english
        }
    }
    
    static func setInputSource(to language: Language) {
        if language == .japanese {
            guard Language.japanese.inputSource != nil else {
                logger.error("Attempted to set to Japanese input source but could not find it.")
                return
            }
        }
        
        // Workaround for TISSelectInputSource KCJV issue
        if language != .english {
            TISSelectInputSource(Language.english.inputSource!)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) { // 씹힘 방지를 위해 딜레이
            TISSelectInputSource(Language.english.inputSource!)
            TISSelectInputSource(language.inputSource!)
            
            if language == .korean {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 씹혔는지 확인하고 다시시도
                    let currentTIS = TISInputSource.current
                    if currentTIS.id != "com.apple.keylayout.2SetHangul" &&
                       currentTIS.id != language.inputSource!.id {
                        logger.error("씹힘 감지 다시시도")
                        TISSelectInputSource(Language.english.inputSource!)
                        TISSelectInputSource(language.inputSource!)
                    }
                }
            }
        }
    }
    
    /// 빠르게 다른 언어로 전환했다 돌아오기.
    ///
    /// 팝업 픽스 전용
    static func rapidDummyAction() {
        let current = currentInputSource
        if current == .english {
            TISSelectInputSource(Language.korean.inputSource!)
            TISSelectInputSource(Language.english.inputSource!)
        } else {
            TISSelectInputSource(Language.english.inputSource!)
            TISSelectInputSource(current.inputSource!)
        }
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
        static let chinese = {
            let inputSource = inputSources.first { $0.id == "com.apple.inputmethod.SCIM.ITABC" }
            if inputSource == nil {
                logger.info("No Chinese input source in list.")
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
    
    static var current: TISInputSource {
        return TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
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
}
