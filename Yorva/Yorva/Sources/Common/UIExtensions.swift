//
//  UIExtensions.swift
//  Yorva
//
//

import UIKit


extension UIView {
    func pinEdges(to superview: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom)
        ])
    }
    func pinEdgesToSafeArea(to superview: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -insets.bottom)
        ])
    }
    func roundCorners(radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
    func applyShadow(color: UIColor = .black,
                     opacity: Float = 0.1,
                     radius: CGFloat = 6,
                     offset: CGSize = CGSize(width: 0, height: 2)) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.masksToBounds = false
    }
}


extension UIViewController {
    var topbarHeight: CGFloat {
        let statusBar = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        return max(statusBar, 20) + (navigationController?.navigationBar.bounds.height ?? 44)
    }
    var safeTopInset: CGFloat {
        view.window?.safeAreaInsets.top ?? max(20, view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20)
    }
    var safeBottomInset: CGFloat {
        view.window?.safeAreaInsets.bottom ?? 0
    }
}


extension Date {
    func timeAgoDisplay() -> String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval/60))m ago" }
        if interval < 86400 { return "\(Int(interval/3600))h ago" }
        if interval < 604800 { return "\(Int(interval/86400))d ago" }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: self)
    }
    func shortHMString() -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: self)
    }
}


extension String {
    var isValidEmail: Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: self)
    }
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}


extension UIColor {
    static var placeholderTint: UIColor {
        let palette: [UIColor] = [
            AppTheme.primary, AppTheme.olive, AppTheme.coins, AppTheme.diamonds,
            AppTheme.success, AppTheme.warning, AppTheme.link, AppTheme.cream
        ]
        return palette.randomElement() ?? AppTheme.primary
    }
}

extension UIApplication {
    var activeKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}


func dispatchMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
}
