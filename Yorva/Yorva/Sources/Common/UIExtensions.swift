//
//  UIExtensions.swift
//  Yorva
//
//  UIKit 通用扩展：UIView/UIViewController/Date/String 等
//

import UIKit

// MARK: - UIView 便捷布局（SnapKit 之外的轻量包装，避免硬编码 frame）

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

// MARK: - UIViewController 通用工具

extension UIViewController {
    /// 当前可见的导航栏高度（含状态栏 / 灵动岛 / 刘海差异化适配）
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

// MARK: - Date 格式化

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

// MARK: - String 校验

extension String {
    var isValidEmail: Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: self)
    }
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

// MARK: - UIColor 随机占位（数据层生成占位头像底色时使用）

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

// MARK: - 延时主线程（用于过渡动画 / 加载占位）

func dispatchMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
}
