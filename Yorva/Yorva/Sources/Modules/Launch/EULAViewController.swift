//
//  EULAViewController.swift
//  Yorva
//
//  EULA 首次启动弹窗（铁律 1）
//  - App 首次启动自动弹出 EULA 界面
//  - 点击「同意」：本地持久化记录同意状态，进入 App 主页，终身不再弹出
//  - 点击「Cancel」：直接强制退出 App
//  - 仅作为临时弹层，不改变导航层级（铁律 13）
//

import UIKit
import SnapKit

final class EULAViewController: BaseViewController {

    var onAgree: (() -> Void)?
    var onCancel: (() -> Void)?

    override var pageBackgroundColor: UIColor { .clear }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.overlay
        modalPresentationStyle = .overFullScreen
        transitioningDelegate = nil

        let card = UIView()
        card.backgroundColor = AppTheme.bgPrimary
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(300)
        }

        let title = UILabel()
        title.font = AppFont.eulaTitle()
        title.textColor = AppTheme.ink
        title.text = "End User License Agreement"
        title.numberOfLines = 0
        title.textAlignment = .center

        let body = UILabel()
        body.font = AppFont.eulaBody()
        body.textColor = AppTheme.textSecondary
        body.numberOfLines = 0
        body.textAlignment = .left
        body.text = """
        Welcome to Yorva. By continuing you agree to our End User License Agreement, Privacy Policy and Terms of Service.

        Yorva helps you record daily choices, share moments, and discover thoughtful prompts. By tapping Agree you confirm that you accept these terms and that you are at least the age required in your region to use Yorva.

        You can manage your account, content and connections at any time from Settings.
        """

        let divider = UIView(); divider.backgroundColor = AppTheme.divider
        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.setTitleColor(AppTheme.textSecondary, for: .normal)
        cancel.titleLabel?.font = AppFont.buttonSecondary()
        cancel.addAction(UIAction { [weak self] _ in self?.onCancel?() }, for: .touchUpInside)
        let agree = UIButton(type: .system)
        agree.setTitle("Agree", for: .normal)
        agree.setTitleColor(AppTheme.primary, for: .normal)
        agree.titleLabel?.font = AppFont.buttonPrimary()
        agree.addAction(UIAction { [weak self] _ in
            EULAStore.agree()           // 本地持久化（铁律 1：仅首次生效）
            self?.onAgree?()
        }, for: .touchUpInside)
        let vDivider = UIView(); vDivider.backgroundColor = AppTheme.divider

        [title, body, divider, cancel, vDivider, agree].forEach { card.addSubview($0) }
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(16)
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
        }
        divider.snp.makeConstraints { make in
            make.top.equalTo(body.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        cancel.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.left.bottom.equalToSuperview()
            make.height.equalTo(48)
            make.right.equalTo(vDivider.snp.left)
        }
        vDivider.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(1)
        }
        agree.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(48)
            make.left.equalTo(vDivider.snp.right)
        }
    }
}
