import IOKit.hid

class InputManager {
    private var hid: IOHIDManager!
    private var isShiftPressed = false
    private var isOptionPressed = false
    private var isCapslockEnabled = false
    private var tertiaryIM: InputSourceManager.Language?
    
    init() {
        _ = InputSourceManager.currentInputSource // Initialize static variable
        if InputSourceManager.Language.japanese.inputSource != nil {
            tertiaryIM = .japanese
        } else if InputSourceManager.Language.chinese.inputSource != nil {
            tertiaryIM = .chinese
        } else {
            tertiaryIM = nil
        }
    }

    func start() {
        let hid = IOHIDManagerCreate(kCFAllocatorDefault, 0)
        
        let deviceFilter = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,  // Generic Desktop Page (0x01)
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard         // Keyboard (0x06, Collection Application)
        ] as CFDictionary
        IOHIDManagerSetDeviceMatching(hid, deviceFilter)
        
        var inputValueFilter = [
            Keys.capsLock,
            Keys.lShift,
            Keys.rShift,
        ]
        
        if tertiaryIM != nil {
            inputValueFilter.append(contentsOf: [
                Keys.lOption,
                Keys.rOption
            ])
        }
        
        let filter = inputValueFilter.map {
            [kIOHIDElementUsageKey: $0] as CFDictionary
        } as CFArray
        IOHIDManagerSetInputValueMatchingMultiple(hid, filter)
        
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
                    InputSourceManager.setInputSource(to: .english)
                }
                break
            }
            
            if !isCapslockEnabled {
                setCapslockState(false)
            } else {
                break
            }

            if tertiaryIM != nil && isOptionPressed {
                if InputSourceManager.currentInputSource != tertiaryIM! {
                    InputSourceManager.setInputSource(to: tertiaryIM!)
                } else {
                    InputSourceManager.setInputSource(to: .english)
                }
                break
            }
            
            if InputSourceManager.currentInputSource != .english {
                InputSourceManager.setInputSource(to: .english)
            } else {
                InputSourceManager.setInputSource(to: .korean)
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [self] in
            self.isCapslockEnabled = getCapslockState()
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
