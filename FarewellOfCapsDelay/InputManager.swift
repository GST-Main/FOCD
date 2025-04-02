import IOKit.hid
import AppKit

final class InputManager {
    private var hid: IOHIDManager!
    private var isShiftPressed = false
    private var isOptionPressed = false
    private(set) var isCapslockOn = false
    private var tertiaryIM: InputSourceManager.Language?
    
    @Published var lastCapslockPressedTime: Date = Date()
    
    private init() {
        _ = InputSourceManager.currentInputSource // Initialize static variable
        if InputSourceManager.Language.japanese.inputSource != nil {
            tertiaryIM = .japanese
        } else if InputSourceManager.Language.chinese.inputSource != nil {
            tertiaryIM = .chinese
        } else {
            tertiaryIM = nil
        }
        
        if #available(macOS 15.2, *) {
            // Watch capslock state
            NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                guard let self else { return }
                guard !event.modifierFlags.contains(.shift) else { return }
                
                // 캡스락 이벤트가 발생하고 나서 캡스락 상태를 설정
                if !isCapslockOn && event.modifierFlags.contains(.capsLock) {
                    if event.keyCode == Keys.capsLock {
                        self.setCapslockState(false)
                    }
                    
                    // 캡스락 끄는 동작을 처리하면 비정상적으로 동작하는 것으로 보임 (원인불명)
                    // 무시하면 알아서 꺼지므로 따로 처리 하지 말 것
                }
            }
        }
    }
    
    public static let shared = InputManager()

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
            lastCapslockPressedTime = .now
            
            if isShiftPressed {
                // Activate/Deactivate capslock + set to eng
                isCapslockOn.toggle()
                if InputSourceManager.currentInputSource != .english {
                    InputSourceManager.setInputSource(to: .english)
                }
                break
            } else if isCapslockOn {
                // Deactivate capslock only
                isCapslockOn = false
                if #unavailable(macOS 15.2) {
                    setCapslockState(false)
                }
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
        
        
        if #unavailable(macOS 15.2) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [self] in
                self.isCapslockOn = getCapslockState()
            }
        }
    }
    
    private func setCapslockState(_ state: Bool) {
        var ioConnect: io_connect_t = .init(0)
        let ioService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        IOServiceOpen(ioService, mach_task_self_, UInt32(kIOHIDParamConnectType), &ioConnect)
        IOHIDSetModifierLockState(ioConnect, Int32(kIOHIDCapsLockState), state)
        
        IOServiceClose(ioConnect)
    }
    
    // Unused
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
