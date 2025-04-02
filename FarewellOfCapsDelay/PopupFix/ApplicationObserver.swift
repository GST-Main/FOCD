import ApplicationServices
import Combine
import Cocoa
import os

fileprivate let axWindowCreatedNotification = kAXWindowCreatedNotification as CFString

final class ApplicationObserver {
    typealias Observation = (
        observer: AXObserver,
        uiElement: AXUIElement,
        runLoop: CFRunLoop,
        runLoopSource: CFRunLoopSource
    )
    
    var isRunning: Bool = false
    
    // Current observee
    private(set) var pid: pid_t?
    private(set) var observation: Observation?
    
    fileprivate let workspaceSubject = PassthroughSubject<Notification, Never>()
    let appStatePublisher: AnyPublisher<Notification, Never>
    fileprivate let windowCreationSubject = PassthroughSubject<UIElement, Never>()
    let windowCreationPublisher: AnyPublisher<UIElement, Never>
    
    private static let workspaceWatchList = [
        NSWorkspace.didLaunchApplicationNotification,
        NSWorkspace.didTerminateApplicationNotification,
        NSWorkspace.didActivateApplicationNotification,
        NSWorkspace.didDeactivateApplicationNotification,
    ]
    private var workspaceSubscriptions: [AnyCancellable] = []
    private var appStateSubscription: AnyCancellable? = nil

    fileprivate let logger = Logger(subsystem: "FOCD",
                                    category: "ApplicationObserver")
    
    // Singleton only
    private init() {
        self.appStatePublisher = workspaceSubject.eraseToAnyPublisher()
        self.windowCreationPublisher = windowCreationSubject.eraseToAnyPublisher()
    }
    static let global = ApplicationObserver()
    
    deinit {
        if observation != nil {
            stopObservingApplication()
        }
    }

    func start() {
        if isRunning {
            logger.info("Attept to start ApplicationObserver but it is already running")
        }
        Self.workspaceWatchList.map {
            NSWorkspace.shared.notificationCenter.publisher(for: $0)
        }.forEach {
            $0.subscribe(workspaceSubject)
                .store(in: &workspaceSubscriptions)
        }
        
        // TODO: 화면이 꺼졌다 켜져도 계속해서 작동하는 지 확인
        let appStateSubscription = appStatePublisher
            .subscribe(on: DispatchQueue.global())
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .delay(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier {
                    self?.observeApplication(pid)
                } else {
                    self?.stopObservingApplication()
                }
            }
        self.appStateSubscription = appStateSubscription
        isRunning = true
    }
    
    func stop() {
        if !isRunning {
            logger.info("Attempt to stop ApplicationObserver but it is not running")
        }
        stopObservingApplication()
        workspaceSubscriptions = []
        appStateSubscription = nil
        isRunning = false
    }
    
    /// Start observation
    ///
    /// - Note: Automatically stops the current observation if exists.
    private func observeApplication(_ pid: pid_t) {
        logger.log("Start observation")
        if self.pid != nil {
            logger.log("Found another observation, stopping")
            stopObservingApplication()
        }
        
        let app = AXUIElementCreateApplication(pid)
        
        var observer: AXObserver?
        let result = AXObserverCreate(pid, callback, &observer)
        // ???: Is it ok to run on main runloop?
        let runLoop = RunLoop.current.getCFRunLoop()
        if result == .success, let observer{
            AXObserverAddNotification(observer,
                                      app,
                                      axWindowCreatedNotification,
                                      nil)
            
            let runloopSource = AXObserverGetRunLoopSource(observer)
            CFRunLoopAddSource(runLoop,
                               runloopSource,
                               .defaultMode)
            
            self.pid = pid
            observation = (observer, app, runLoop, runloopSource)
        }
    }
    
    private func stopObservingApplication() {
        if let (observer, uiElement, runLoop, runLoopSource) = observation {
            logger.log("Stop observation")
            AXObserverRemoveNotification(observer,
                                         uiElement,
                                         axWindowCreatedNotification)
            CFRunLoopRemoveSource(runLoop,
                                  runLoopSource,
                                  .defaultMode)
            pid = nil
            observation = nil
        } else {
            logger.info("Attept to stop observation but observation is nil")
        }
    }
}

fileprivate func callback(
    _: AXObserver,
    uiElement: AXUIElement,
    notification: CFString,
    _: UnsafeMutableRawPointer?
) {
    ApplicationObserver.global.logger.debug("\(Date.now.timestamp) \(notification)")
    ApplicationObserver.global.windowCreationSubject.send(UIElement(uiElement))
}
