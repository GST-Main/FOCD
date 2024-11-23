import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    var statusBar: NSStatusBar!
    var statusBarItem: NSStatusItem?
    let statusBarMenu: NSMenu = NSMenu()
    let inputManager = InputManager()
    
    @UserDefault(key: "com.GST.focd.pref.showStatusMenuItem") var showStatusMenuItem: Bool = true
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Show hidden status bar icon on duplicated launching
        let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!)
        if runningApp.count > 1 {
            runningApp.first!.activate()
            app.terminate(self)
            return
        }
        
        statusBar = NSStatusBar.system

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
        
        let chineseMenuItem = NSMenuItem()
        chineseMenuItem.title = "中文"
        chineseMenuItem.target = self
        chineseMenuItem.action = #selector(setInputSourceChinese)
        chineseMenuItem.identifier = NSUserInterfaceItemIdentifier("menuItem.chinese")
        
        let hideBarItemMenuItem = NSMenuItem()
        hideBarItemMenuItem.title = "상태 바 아이콘 숨기기"
        hideBarItemMenuItem.target = self
        hideBarItemMenuItem.action = #selector(hideBarItem)
        
        let quitMenuItem = NSMenuItem()
        quitMenuItem.title = "종료"
        quitMenuItem.target = self
        quitMenuItem.action = #selector(quit)
        
        statusBarMenu.addItem(englishMenuItem)
        statusBarMenu.addItem(koreanMenuItem)
        statusBarMenu.addItem(japaneseMenuItem)
        statusBarMenu.addItem(chineseMenuItem)
        statusBarMenu.addItem(.separator())
        statusBarMenu.addItem(hideBarItemMenuItem)
        statusBarMenu.addItem(quitMenuItem)
        
        if showStatusMenuItem {
            createBarItem()
        }
        
        inputManager.start()
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        if !showStatusMenuItem {
            showStatusMenuItem = true
            createBarItem()
        }
    }
    
    func createBarItem() {
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "capslock.fill", accessibilityDescription: nil)
                        
            statusBarItem?.menu = statusBarMenu
        } else {
            logger.info("No status bar button.")
        }
    }
    
    func removeBarItem() {
        guard let statusBarItem else {
            logger.info("No status bar item.")
            return
        }
        
        statusBar.removeStatusItem(statusBarItem)
        self.statusBarItem = nil
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
        case NSUserInterfaceItemIdentifier("menuItem.chinese"):
            if InputSourceManager.Language.chinese.inputSource == nil {
                menuItem.state = .off
                return false
            }
            if InputSourceManager.currentInputSource == .chinese {
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
            InputSourceManager.setInputSource(to: .english)
        }
    }
    
    @objc func setInputSourceKorean() {
        if InputSourceManager.currentInputSource != .korean {
            InputSourceManager.setInputSource(to: .korean)
        }
    }
    
    @objc func setInputSourceJapanese() {
        if InputSourceManager.currentInputSource != .japanese {
            InputSourceManager.setInputSource(to: .japanese)
        }
    }
    
    @objc func setInputSourceChinese() {
        if InputSourceManager.currentInputSource != .chinese {
            InputSourceManager.setInputSource(to: .chinese)
        }
    }
    
    @objc func hideBarItem() {
        showStatusMenuItem = false
        removeBarItem()
    }
    
    @objc func quit() {
        app.terminate(self)
    }
}

