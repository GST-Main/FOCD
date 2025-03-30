import Foundation
import Combine

final class PopupFucker {
    let inputManager = InputManager.shared
    let appObserver = ApplicationObserver.global
    var cancellables: Set<AnyCancellable> = []
    /// PDM (Popup Destruction Mode)
    var PDM = false
    
    // Strategey - fuckItMode: temporarily pause to listen observer
    func start() {
        if !appObserver.isRunning {
            appObserver.start()
        }
        
        // Not on PDM
        appObserver.windowCreationPublisher
            .subscribe(on: DispatchQueue.global())
            .filter { [weak self] _ in
                guard let self else { return false }
                
                // Avoid PDM
                guard PDM == false else {
                    return false
                }
                
                // 마지막 캡스락 입력으로부터 최소 30초 이상
                guard -inputManager.lastCapslockPressedTime.timeIntervalSinceNow > 30 else {
                    return false
                }
                
                return true
            }
            .filterPopup()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] popup in
                Task {
                    await self?.enterPDM(with: popup)
                }
            }
            .store(in: &cancellables)
        
        // On PDM
        appObserver.windowCreationPublisher
            .receive(on: DispatchQueue.main)
            .filter { [weak self] _ in
                self?.PDM == true
            }
            .filterPopup()
            .sink { [weak self] popup in
                // TODO: Fuck the caught popup
                Task {
                    await self?.destroyPopup(popup)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        cancellables = []
        if appObserver.isRunning {
            appObserver.stop()
        }
    }
    
    func enterPDM(with popup: UIElement) async {
        PDM = true
        await destroyPopup(popup)
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        PDM = false
    }
    
    func destroyPopup(_ popup: UIElement, repeating count: Int = 8) async {
        let hiddenPosition = CGPoint(x: 30_000, y: 30_000)
        popup.setPosition(to: hiddenPosition)
        
        let task = Task {
            do {
                for _ in 0..<count {
                    popup.setPosition(to: hiddenPosition)
                    
                    try await Task.sleep(nanoseconds: 16_666_667) // 1/60s
                }
            } catch {
                
            }
        }
        
        _ = await task.value
    }
}

extension Publisher where Output == UIElement {
    func filterPopup() -> Publishers.Filter<Self> {
        self.filter { uiElement in
            // 다음 규칙을 모두 충족하면 한영팝업
            // 더 느슨하거나 엄격한 규칙이 필요할 수도 있음
            let attributes = uiElement.attributes
            guard let subrole = attributes[.subrole] as? String, subrole == "AXDialog" else {
                return false
            }
            guard let isMain = attributes[.main] as? Bool, !isMain else {
                return false
            }
            
            let children = uiElement.attributes[.children] as? [UIElement]
            guard let children,
                  children.count == 1,
                  let firstChild = children.first else {
                return false
            }
            
            guard let role = firstChild.attributes[.role] as? String,
                  role == "AXButton" else {
                return false
            }
            
            return true
        }
    }
}
