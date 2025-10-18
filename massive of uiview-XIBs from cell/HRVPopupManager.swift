// Файл: HRVPopupManager.swift (НОВЫЙ ФАЙЛ)
import UIKit

class HRVPopupManager {
    static let shared = HRVPopupManager()
    private var currentPopup: HRVResultPopupView?
    private var dismissTimer: Timer?

    private init() {}

    func showPopup(with status: HRVStatus) {
        DispatchQueue.main.async {
            self.currentPopup?.removeFromSuperview()
            self.dismissTimer?.invalidate()

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

            let popup = HRVResultPopupView()
            popup.configure(with: status)
            self.currentPopup = popup
            window.addSubview(popup)

            let screenWidth = window.bounds.width
            popup.transform = CGAffineTransform(translationX: -screenWidth, y: 0)

            NSLayoutConstraint.activate([
                popup.leadingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                popup.trailingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                popup.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])

            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                popup.transform = .identity
            })

            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
                self?.dismissPopup()
            }
        }
    }

    private func dismissPopup() {
        guard let popup = currentPopup else { return }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            let screenWidth = popup.window?.bounds.width ?? 0
            popup.transform = CGAffineTransform(translationX: screenWidth, y: 0)
        }) { _ in
            popup.removeFromSuperview()
            if self.currentPopup == popup {
                self.currentPopup = nil
            }
        }
    }
}
