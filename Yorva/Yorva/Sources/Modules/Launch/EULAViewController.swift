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
        card.backgroundColor = UIColor(hex: 0xFAF9F3)
        card.layer.cornerRadius = 26
        card.layer.masksToBounds = true
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(26)
        }

        let title = UILabel()
        title.font = .systemFont(ofSize: 24, weight: .bold)
        title.textColor = AppTheme.ink
        title.text = "EULA"
        title.numberOfLines = 0
        title.textAlignment = .center

        let body = UILabel()
        body.font = .systemFont(ofSize: 12, weight: .regular)
        body.textColor = UIColor(hex: 0x7B7E77)
        body.numberOfLines = 0
        body.textAlignment = .center
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 2
        paragraph.paragraphSpacing = 8
        let bodyText = """
        Welcome to Yorva! To ensure a safe, respectful, and positive community for all minimalist enthusiasts, the following content is strictly prohibited:

        1. Child Harm & Exploitation: Any content related to child harm, abuse, or pornography detrimental to minors.

        2. Misinformation & Unauthorized Disclosures: Fake or harmful messages concerning recent or current events, as well as malicious exposure or unauthorized leaking of proprietary or private user information.

        3. Objectionable Content: Any form of violence, bullying, hate speech, explicit pornography, or other abusive material that disrupts the minimalist community atmosphere.

        If we discover any content violating these guidelines (including but not limited to the above), your content will be removed, and your account may be permanently banned.

        By clicking "I agree", you acknowledge and agree to our Terms of Use and Privacy Policy.
        """
        body.attributedText = NSAttributedString(string: bodyText.trimmingCharacters(in: .whitespacesAndNewlines), attributes: [
            .font: body.font as Any,
            .foregroundColor: body.textColor as Any,
            .paragraphStyle: paragraph
        ])

        let bodyScroll = UIScrollView()
        bodyScroll.showsVerticalScrollIndicator = false
        bodyScroll.alwaysBounceVertical = false
        bodyScroll.addSubview(body)

        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.setTitleColor(AppTheme.ink, for: .normal)
        cancel.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        cancel.backgroundColor = UIColor(hex: 0xEEF0E9)
        cancel.layer.cornerRadius = 14
        cancel.addAction(UIAction { [weak self] _ in self?.onCancel?() }, for: .touchUpInside)
        let agree = UIButton(type: .system)
        agree.setTitle("I agree", for: .normal)
        agree.setTitleColor(AppTheme.ink, for: .normal)
        agree.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        agree.backgroundColor = UIColor(hex: 0xD9FF3F)
        agree.layer.cornerRadius = 14
        agree.addAction(UIAction { [weak self] _ in
            EULAStore.agree()           // 本地持久化（铁律 1：仅首次生效）
            self?.onAgree?()
        }, for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [cancel, agree])
        buttons.axis = .horizontal
        buttons.spacing = 9
        buttons.distribution = .fillEqually
        [title, bodyScroll, buttons].forEach { card.addSubview($0) }

        let layoutBounds = view.bounds.width > 0 ? view.bounds : UIScreen.main.bounds
        let cardWidth = max(0, min(layoutBounds.width - 52, 468))
        let textWidth = max(1, cardWidth - 40)
        body.preferredMaxLayoutWidth = textWidth
        let titleHeight = title.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height
        let bodyContentHeight = body.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height
        let fixedCardHeight = 36 + ceil(titleHeight) + 12 + 24 + 52 + 18
        let maximumCardHeight = max(fixedCardHeight, layoutBounds.height - 114)
        let bodyHeight = min(bodyContentHeight, maximumCardHeight - fixedCardHeight)

        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(36)
            make.left.right.equalToSuperview().inset(20)
        }
        bodyScroll.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(max(1, bodyHeight))
        }
        body.snp.makeConstraints { make in
            make.edges.equalTo(bodyScroll.contentLayoutGuide)
            make.width.equalTo(bodyScroll.frameLayoutGuide)
        }
        buttons.snp.makeConstraints { make in
            make.top.equalTo(bodyScroll.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().inset(18)
        }
    }
}
