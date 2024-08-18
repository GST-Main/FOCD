import IOKit.hid

class InputManager {
    private var hid: IOHIDManager!
    private var isShiftPressed = false
    private var isOptionPressed = false

    func start() {
        let hid = IOHIDManagerCreate(kCFAllocatorDefault, 0)
        IOHIDManagerSetDeviceMatching(
            hid,
            [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,   // Generic Desktop Page (0x01)
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard] as CFDictionary // Keyboard (0x06, Collection Application)
        )
        IOHIDManagerSetInputValueMatching(
            hid,
            [kIOHIDElementUsagePageKey: kHIDPage_KeyboardOrKeypad] as CFDictionary // Keyboard/Keypad (0x07, Selectors or Dynamic Flags)
        )
        
        let callback: IOHIDValueCallback = { context, result, sender, value in
            guard result == kIOReturnSuccess else { return }
            guard let context = context else { return }
            let unmanagedSelf = Unmanaged<InputManager>.fromOpaque(context).takeUnretainedValue()
            
            unmanagedSelf.checkInput(value)
        }
        IOHIDManagerRegisterInputValueCallback(hid, callback, Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerScheduleWithRunLoop(hid, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

        let res = IOHIDManagerOpen(hid, 0)
        if res != kIOReturnSuccess {
            logger.fault("Failed to initialize hid")
            IOHIDManagerClose(hid, 0)
            // TODO: Failed to open (initialize), throw it
        }
        
        self.hid = hid
    }
    
    private func checkInput(_ value: IOHIDValue) {
        let usage = IOHIDElementGetUsage(IOHIDValueGetElement(value))
        let keyState = IOHIDValueGetIntegerValue(value) != 0 ? KeyState.keyDown : KeyState.keyUp
                
        switch (usage, keyState) {
        case (Keys.capsLock, .keyDown):
            if isShiftPressed {
                if InputSourceManager.currentInputSource != .english {
                    InputSourceManager.setInputSource(as: .english)
                }
                break
            }
            
            setCapslockState(false)
            if isOptionPressed {
                if InputSourceManager.currentInputSource != .japanese {
                    InputSourceManager.setInputSource(as: .japanese)
                } else {
                    InputSourceManager.setInputSource(as: .english)
                }
            } else {
                if InputSourceManager.currentInputSource != .english {
                    InputSourceManager.setInputSource(as: .english)
                } else {
                    InputSourceManager.setInputSource(as: .korean)
                }
            }
        case (Keys.lShift, .keyDown): fallthrough
        case (Keys.rShift, .keyDown):
            isShiftPressed = true
        case (Keys.lShift, .keyUp): fallthrough
        case (Keys.rShift, .keyUp):
            isShiftPressed = false
        case (Keys.lOption, .keyDown): fallthrough
        case (Keys.rOption, .keyDown):
            isOptionPressed = true
        case (Keys.lOption, .keyUp): fallthrough
        case (Keys.rOption, .keyUp):
            isOptionPressed = false
            
        default: return
        }
    }
    
    private func setCapslockState(_ state: Bool) {
        var ioConnect: io_connect_t = .init(0)
        let ioService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        IOServiceOpen(ioService, mach_task_self_, UInt32(kIOHIDParamConnectType), &ioConnect)
        
        IOHIDSetModifierLockState(ioConnect, Int32(kIOHIDCapsLockState), state)
        
        IOServiceClose(ioConnect)
    }
    
    private func getCapslockState() -> Bool {
        var ioConnect: io_connect_t = .init(0)
        let ioService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        IOServiceOpen(ioService, mach_task_self_, UInt32(kIOHIDParamConnectType), &ioConnect)

        var modifierLockState = false
        IOHIDGetModifierLockState(ioConnect, Int32(kIOHIDCapsLockState), &modifierLockState)

        IOServiceClose(ioConnect)
        
        return modifierLockState
    }
    
    private struct Keys {
        static let capsLock: UInt32 = 0x39
        static let lShift: UInt32 = 0xE1
        static let rShift: UInt32 = 0xE5
        static let lOption: UInt32 = 0xE2
        static let rOption: UInt32 = 0xE6
    }
    
    private enum KeyState {
        case keyDown, keyUp
    }
}
