//
//  ConfirmDialog.swift
//  Yorva
//
//  通用确认弹窗（铁律 6 金币/钻石扣费确认 / 删除账号二次确认 / 拉黑二次确认）
//  - 白底卡片 + 40% 黑遮罩，符合 ios-design-spec 弹层背景
//

import UIKit
import SnapKit

final class ConfirmDialog {

    /// 简化显示入口
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 描述（如本次消耗数额 / 删除账号不可恢复）
    ///   - confirmTitle: 确认按钮文字
    ///   - cancelTitle: 取消按钮文字
    ///   - isDestructive: 是否破坏性操作（按钮文字变红）
    ///   - onConfirm: 确认回调
    ///   - onCancel: 取消回调
    static func show(title: String,
                     message: String,
                     confirmTitle: String = "Confirm",
                     cancelTitle: String = "Cancel",
                     isDestructive: Bool = false,
                     onConfirm: @escaping () -> Void,
                     onCancel: (() -> Void)? = nil) {
        guard let host = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.keyWindow else { return }

        let overlay = UIView()
        overlay.backgroundColor = AppTheme.overlay
        host.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }

        let card = UIView()
        card.backgroundColor = AppTheme.bgPrimary
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        overlay.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(280)
        }

        let titleLabel = UILabel()
        titleLabel.font = AppFont.navTitle()
        titleLabel.textColor = AppTheme.ink
        titleLabel.text = title
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.font = AppFont.body()
        messageLabel.textColor = AppTheme.textSecondary
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.text = message

        let divider = UIView(); divider.backgroundColor = AppTheme.divider

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle(cancelTitle, for: .normal)
        cancelButton.setTitleColor(AppTheme.textSecondary, for: .normal)
        cancelButton.titleLabel?.font = AppFont.buttonSecondary()
        cancelButton.tag = 0

        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle(confirmTitle, for: .normal)
        confirmButton.titleLabel?.font = AppFont.buttonPrimary()
        confirmButton.setTitleColor(isDestructive ? AppTheme.error : AppTheme.primary, for: .normal)
        confirmButton.tag = 1

        let vDivider = UIView(); vDivider.backgroundColor = AppTheme.divider

        [titleLabel, messageLabel, divider, cancelButton, vDivider, confirmButton].forEach { card.addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(16)
        }
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(16)
        }
        divider.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.left.bottom.equalToSuperview()
            make.height.equalTo(46)
            make.width.equalTo(host).priority(.low)
        }
        vDivider.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(1)
        }
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(46)
            make.left.equalTo(vDivider.snp.right)
        }
        cancelButton.snp.makeConstraints { make in
            make.right.equalTo(vDivider.snp.left)
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
}
