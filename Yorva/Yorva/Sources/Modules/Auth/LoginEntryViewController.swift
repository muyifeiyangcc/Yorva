//
//  LoginEntryViewController.swift
//  Yorva
//
//  登录入口（铁律 2 / 4 / 3 / 13）
//  - I'm New：直接进入首页游客态；不校验协议 CheckBox（铁律 4）
//  - Sign In By Email：未勾选弹窗提示，勾选后方可 push 邮箱登录（铁律 4）
//  - Privacy Policy / Terms of Service：push 网页容器到 https://www.baidu.com（铁律 3）
//  - 协议 CheckBox 默认未选中
//

import UIKit
import SnapKit

final class LoginEntryViewController: BaseViewController {

    /// 来自游客拦截流程的标识；用于登录成功后回到根 Tab 页
    var fromGuestFlow: Bool = false

    override var pageBackgroundColor: UIColor { AppTheme.bgSplash }
    override var isSecondaryLevel: Bool { fromGuestFlow }

    private let brandLabel = UILabel()
    private let taglineLabel = UILabel()
    private let signInEmailButton = PrimaryButton(title: "Sign In By Email")
    private let imNewButton = TextLinkButton(title: "I'm New")
    private let checkbox = UIButton(type: .custom)
    private let agreementTextView = UITextView()
    private var isAgreed: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupHierarchy()
        applyAutoLayoutConstraints()
    }

    override func setupHierarchy() {
        brandLabel.font = AppFont.splash(32)
        brandLabel.textColor = AppTheme.olive
        brandLabel.text = "Yorva"
        taglineLabel.font = AppFont.bodySecondary()
        taglineLabel.textColor = AppTheme.textSecondary
        taglineLabel.text = "Makeroom for less."

        checkbox.setImage(UIImage(systemName: "square")?.withTintColor(AppTheme.stone, renderingMode: .alwaysOriginal), for: .normal)
        checkbox.setImage(UIImage(systemName: "checkmark.square.fill")?.withTintColor(AppTheme.primary, renderingMode: .alwaysOriginal), for: .selected)
        checkbox.addAction(UIAction { [weak self] _ in
            self?.checkbox.isSelected.toggle()
            self?.isAgreed = self?.checkbox.isSelected ?? false
        }, for: .touchUpInside)

        agreementTextView.isEditable = false
        agreementTextView.isScrollEnabled = false
        agreementTextView.backgroundColor = .clear
        agreementTextView.delegate = self
        agreementTextView.dataDetectorTypes = .link
        agreementTextView.textContainerInset = .zero
        agreementTextView.textContainer.lineFragmentPadding = 0
        agreementTextView.attributedText = agreementAttributed()
        agreementTextView.linkTextAttributes = [
            .foregroundColor: AppTheme.textLink,
            .font: AppFont.buttonTextLink()
        ]

        signInEmailButton.addAction(UIAction { [weak self] _ in self?.handleSignInByEmail() }, for: .touchUpInside)
        imNewButton.addAction(UIAction { [weak self] _ in self?.handleGuest() }, for: .touchUpInside)

        [brandLabel, taglineLabel, signInEmailButton, imNewButton, checkbox, agreementTextView].forEach { view.addSubview($0) }
    }

    private func agreementAttributed() -> NSAttributedString {
        let attr = NSMutableAttributedString(string: "I have read and agree to the ", attributes: [
            .font: AppFont.bodySecondary(), .foregroundColor: AppTheme.textSecondary])
        let tos = NSAttributedString(string: "Terms of Service", attributes: [
            .font: AppFont.buttonTextLink(), .foregroundColor: AppTheme.textLink, .link: URL(string: "tos")!])
        let and = NSAttributedString(string: " and ", attributes: [
            .font: AppFont.bodySecondary(), .foregroundColor: AppTheme.textSecondary])
        let privacy = NSAttributedString(string: "Privacy Policy", attributes: [
            .font: AppFont.buttonTextLink(), .foregroundColor: AppTheme.textLink, .link: URL(string: "privacy")!])
        attr.append(tos); attr.append(and); attr.append(privacy)
        return attr
    }

    override func applyAutoLayoutConstraints() {
        brandLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(80)
            make.centerX.equalToSuperview()
        }
        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(brandLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        signInEmailButton.snp.makeConstraints { make in
            make.top.equalTo(taglineLabel.snp.bottom).offset(80)
            make.left.right.equalToSuperview().inset(24)
        }
        imNewButton.snp.makeConstraints { make in
            make.top.equalTo(signInEmailButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
        checkbox.snp.makeConstraints { make in
            make.top.equalTo(imNewButton.snp.bottom).offset(40)
            make.left.equalToSuperview().offset(24)
            make.size.equalTo(20)
        }
        agreementTextView.snp.makeConstraints { make in
            make.centerY.equalTo(checkbox)
            make.left.equalTo(checkbox.snp.right).offset(8)
            make.right.equalToSuperview().inset(24)
        }
    }

    // MARK: - Actions

    private func handleSignInByEmail() {
        // 铁律 4：未勾选 CheckBox 弹窗提示，不允许进入邮箱登录页
        guard isAgreed else {
            let alert = UIAlertController(title: "Agreement Required",
                                         message: "Please read and agree to the agreement first.",
                                         preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let emailVC = EmailLoginViewController()
        navigationController?.pushViewController(emailVC, animated: true)
    }

    private func handleGuest() {
        // 铁律 4：游客入口不校验 CheckBox 选中状态，直接放行
        RootCoordinator.shared.routeGuestToMain()
    }
}

// 协议文字点击跳转（铁律 3：跳转固定链接 https://www.baidu.com）
extension LoginEntryViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let web = WebContainerViewController()
        web.title = URL.absoluteString == "tos" ? "Terms of Service" : "Privacy Policy"
        web.targetURL = URL(string: "https://www.baidu.com")
        navigationController?.pushViewController(web, animated: true)
        return false
    }
}
