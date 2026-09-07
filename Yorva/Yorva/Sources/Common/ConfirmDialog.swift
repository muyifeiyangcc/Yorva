//
//  ConfirmDialog.swift
//  Yorva
//
//  全局统一的自定义确认弹窗：动态高度、双按钮、品牌色样式。
//

import UIKit
import SnapKit

final class ConfirmDialog {

    static func show(title: String,
                     message: String,
                     confirmTitle: String = "Confirm",
                     cancelTitle: String = "Cancel",
                     isDestructive: Bool = false,
                     onConfirm: @escaping () -> Void,
                     onCancel: (() -> Void)? = nil) {
        guard let host = UIApplication.shared.activeKeyWindow else { return }

        let overlay = UIView()
        overlay.backgroundColor = AppTheme.overlay
        host.addSubview(overlay)
        overlay.snp.makeConstraints { make in make.edges.equalToSuperview() }

        let card = UIView()
        card.backgroundColor = UIColor(hex: 0xFAF9F3)
        card.layer.cornerRadius = 26
        card.layer.masksToBounds = true
        overlay.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(19)
            make.width.lessThanOrEqualTo(468)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = AppTheme.ink
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 16, weight: .regular)
        messageLabel.textColor = UIColor(hex: 0x7B7E77)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle(cancelTitle, for: .normal)
        cancelButton.setTitleColor(AppTheme.ink, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cancelButton.backgroundColor = UIColor(hex: 0xEEF0E9)
        cancelButton.layer.cornerRadius = 15

        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle(confirmTitle, for: .normal)
        // The confirmation action always uses the app's black ink color,
        // including destructive flows; destructive styling is conveyed by
        // the action copy and confirmation step rather than red text.
        confirmButton.setTitleColor(AppTheme.ink, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        confirmButton.backgroundColor = UIColor(hex: 0xD9FF3F)
        confirmButton.layer.cornerRadius = 15

        let buttonsStack = UIStackView(arrangedSubviews: [cancelButton, confirmButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 9
        buttonsStack.distribution = .fillEqually
        card.addSubview(titleLabel)
        card.addSubview(messageLabel)
        card.addSubview(buttonsStack)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(38)
            make.left.right.equalToSuperview().inset(20)
        }
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
        }
        buttonsStack.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(18)
            make.height.equalTo(45)
            make.bottom.equalToSuperview().inset(16)
        }

        let close: (Bool) -> Void = { confirmed in
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0
            }) { _ in
                overlay.removeFromSuperview()
                if confirmed { onConfirm() } else { onCancel?() }
            }
        }
        cancelButton.addAction(UIAction { _ in close(false) }, for: .touchUpInside)
        confirmButton.addAction(UIAction { _ in close(true) }, for: .touchUpInside)

        overlay.alpha = 0
        UIView.animate(withDuration: 0.2) { overlay.alpha = 1 }
    }

    /// 金币不足弹窗：展示余额与所需金额，提供 Recharge 按钮进入充值页
    static func showInsufficientCoins(needed: Int,
                                      onRecharge: @escaping () -> Void) {
        let balance = CurrencyManager.shared.coins
        show(
            title: "Not enough coins",
            message: "You need \(needed) Coins but only have \(balance). Recharge to continue.",
            confirmTitle: "Recharge",
            cancelTitle: "Cancel",
            onConfirm: onRecharge
        )
    }
}
