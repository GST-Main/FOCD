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
            .combineLatest(inputManager.$lastCapslockPressedTime)
            .subscribe(on: DispatchQueue.global())
            .filter { [weak self] (uiElement, lastCapslockTime) in
                // Avoid PDM
                guard self?.PDM == false else {
                    return false
                }
                
                // 마지막 캡스락 입력으로부터 최소 30초 이상
                guard -lastCapslockTime.timeIntervalSinceNow > 30 else {
                    return false
                }
                
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
            }.sink { [weak self] _ in
                // TODO: Fuck it like an animal
            }
        
        // On PDM
        appObserver.windowCreationPublisher
            .receive(on: DispatchQueue.main)
            .filter { [weak self] _ in
                self?.PDM == true
            }
            .sink { _ in
                // TODO: Fuck the caught popup
            }
    }
}
