import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    var isMuted = false
    var statusBar: NSStatusBar!
    var statusBarItem: NSStatusItem!
    let inputManager = InputManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "capslock.fill", accessibilityDescription: nil)
            
            let englishMenuItem = NSMenuItem()
            englishMenuItem.title = "English"
            englishMenuItem.target = self
            englishMenuItem.action = #selector(setInputSourceEnglish)
            englishMenuItem.identifier = NSUserInterfaceItemIdentifier("menuItem.english")
            
            let koreanMenuItem = NSMenuItem()
            koreanMenuItem.title = "한국어"
            koreanMenuItem.target = self
            koreanMenuItem.action = #selector(setInputSourceKorean)
            koreanMenuItem.identifier = NSUserInterfaceItemIdentifier("menuItem.korean")
            
            let japaneseMenuItem = NSMenuItem()
            japaneseMenuItem.title = "日本語"
            japaneseMenuItem.target = self
            japaneseMenuItem.action = #selector(setInputSourceJapanese)
            japaneseMenuItem.identifier = NSUserInterfaceItemIdentifier("menuItem.japanese")
            
            let quitMenuItem = NSMenuItem()
            quitMenuItem.title = "Quit"
            quitMenuItem.target = self
            quitMenuItem.action = #selector(quit)
            
            let mainMenu = NSMenu()
            mainMenu.addItem(englishMenuItem)
            mainMenu.addItem(koreanMenuItem)
            mainMenu.addItem(japaneseMenuItem)
            mainMenu.addItem(.separator())
            mainMenu.addItem(quitMenuItem)
            
            statusBarItem.menu = mainMenu
        }
        
        inputManager.start()
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.identifier {
        case NSUserInterfaceItemIdentifier("menuItem.english"): 
            if InputSourceManager.currentInputSource == .english {
                menuItem.state = .on
            } else {
                menuItem.state = .off
            }
        case NSUserInterfaceItemIdentifier("menuItem.korean"):
            if InputSourceManager.currentInputSource == .korean {
                menuItem.state = .on
            } else {
                menuItem.state = .off
            }
        case NSUserInterfaceItemIdentifier("menuItem.japanese"):
            if InputSourceManager.Language.japanese.inputSource == nil {
                menuItem.state = .off
                return false
            }
            if InputSourceManager.currentInputSource == .japanese {
                menuItem.state = .on
            } else {
                menuItem.state = .off
            }
        default: return true
        }
        
        return true
    }

    @objc func setInputSourceEnglish() {
        if InputSourceManager.currentInputSource != .english {
            InputSourceManager.setInputSource(as: .english)
        }
    }
    
    @objc func setInputSourceKorean() {
        if InputSourceManager.currentInputSource != .korean {
            InputSourceManager.setInputSource(as: .korean)
        }
    }
    
    @objc func setInputSourceJapanese() {
        if InputSourceManager.currentInputSource != .japanese {
            InputSourceManager.setInputSource(as: .japanese)
        }
    }
    
    @objc func quit() {
        app.terminate(self)
    }
}

