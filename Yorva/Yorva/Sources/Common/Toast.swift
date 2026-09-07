//
//  Toast.swift
//  Yorva
//
//  全局轻量 Toast 提示（半透明黑底白字，符合 ios-design-spec Toast 规范）
//

import UIKit
import SnapKit

enum Toast {
    static func show(_ message: String, in window: UIWindow? = nil, duration: TimeInterval = 1.6) {
        guard let host = window ?? UIApplication.shared.activeKeyWindow else { return }
        let toast = ToastView()
        toast.label.text = message
        host.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalTo(host)
            make.bottom.equalTo(host.safeAreaLayoutGuide).offset(-40)
            make.leading.greaterThanOrEqualTo(host).offset(40)
            make.trailing.lessThanOrEqualTo(host).offset(-40)
        }
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 10)
        UIView.animate(withDuration: 0.25) {
            toast.alpha = 1
            toast.transform = .identity
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.25, animations: {
                    toast.alpha = 0
                    toast.transform = CGAffineTransform(translationX: 0, y: 10)
                }) { _ in toast.removeFromSuperview() }
            }
        }
    }
}

private final class ToastView: UIView {
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 12
        layer.masksToBounds = true
        label.font = AppFont.toast()
        label.textColor = AppTheme.textOnPrimary
        label.numberOfLines = 0
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16))
        }
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError() }
}
