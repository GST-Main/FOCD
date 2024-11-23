import AppKit
import os

let app = NSApplication.shared
let delegate = AppDelegate()
let logger = Logger(subsystem: "FOCD", category: "")
app.delegate = delegate
app.setActivationPolicy(.accessory)
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
