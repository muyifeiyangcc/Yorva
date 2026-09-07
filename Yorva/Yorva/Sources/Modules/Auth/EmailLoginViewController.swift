//
//  EmailLoginViewController.swift
//  Yorva
//
//  邮箱登录（铁律 4 + 铁律 10）
//

import UIKit
import SnapKit

final class EmailLoginViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AuthDesign.backgroundColor }
    override var isSecondaryLevel: Bool { true }

    private let backButton = AuthDesign.makeBackButton()
    private let headerSeparator = AuthDesign.makeSeparator()
    private let titleLabel = AuthDesign.makeTitleLabel()
    private let subtitleLabel = AuthDesign.makeSubtitleLabel()
    private let formCard = AuthFormBackgroundView()
    private let emailCaption = AuthDesign.makeFieldCaption("EMAIL")
    private let passwordCaption = AuthDesign.makeFieldCaption("PASSWORD")
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let forgotButton = UIButton(type: .system)
    private let signInButton = AuthBottomButton(title: "Sign in")
    private let errorLabel = UILabel()

    override func shouldUseScrollContainer() -> Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupHierarchy() {
        titleLabel.attributedText = AuthDesign.makeTitle("Keep what\nmatters close.")
        subtitleLabel.text = "Sign in to return to your thoughtful corner of the internet."

        emailField.configureAuthField(placeholder: "you@example.com")
        emailField.keyboardType = .emailAddress
        passwordField.configureAuthField(placeholder: "Your password")
        passwordField.isSecureTextEntry = true

        forgotButton.setAttributedTitle(AuthDesign.makeLinkTitle("Forgot password?"), for: .normal)
        forgotButton.addAction(UIAction { [weak self] _ in
            let vc = ForgotPasswordViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)

        errorLabel.font = AppFont.textFieldError()
        errorLabel.textColor = AppTheme.textError
        errorLabel.numberOfLines = 0

        backButton.addAction(UIAction { [weak self] _ in self?.handleBackTapped() }, for: .touchUpInside)
        signInButton.addAction(UIAction { [weak self] _ in self?.attemptLogin() }, for: .touchUpInside)

        let host = self.view!
        self.view.addSubview(backButton)
        [headerSeparator, titleLabel, subtitleLabel, formCard].forEach { host.addSubview($0) }
        [emailCaption, passwordCaption, emailField, passwordField, forgotButton].forEach {
            $0.isUserInteractionEnabled = true
            host.addSubview($0)
        }
        host.addSubview(errorLabel)
        self.view.addSubview(signInButton)
    }

    override func applyAutoLayoutConstraints() {
        let host = self.view!
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(34)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(94)
            make.left.right.equalTo(host).inset(23)
        }
        headerSeparator.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(62)
            make.left.right.equalTo(host)
            make.height.equalTo(1)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalTo(titleLabel)
        }
        formCard.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(36)
            make.left.right.equalTo(host).inset(23)
            make.height.equalTo(218)
        }
        emailCaption.snp.makeConstraints { make in
            make.top.equalTo(formCard).offset(21)
            make.left.right.equalTo(formCard).inset(17)
        }
        emailField.snp.makeConstraints { make in
            make.top.equalTo(emailCaption.snp.bottom).offset(7)
            make.left.right.equalTo(emailCaption)
            make.height.equalTo(43)
        }
        passwordCaption.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(15)
            make.left.right.equalTo(emailCaption)
        }
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(passwordCaption.snp.bottom).offset(7)
            make.left.right.equalTo(emailCaption)
            make.height.equalTo(43)
        }
        forgotButton.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(7)
            make.right.equalTo(formCard).inset(17)
            make.height.equalTo(24)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(formCard.snp.bottom).offset(6)
            make.left.right.equalTo(formCard)
        }
        signInButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(18)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func attemptLogin() {
        let email = emailField.text ?? ""
        let password = passwordField.text ?? ""
        guard email.isValidEmail else { errorLabel.text = "Please enter a valid email."; return }
        guard password.count >= 8 else { errorLabel.text = "Password must be at least 8 characters."; return }
        errorLabel.text = ""
        let result = AccountManager.shared.login(email: email, password: password)
        switch result {
        case .success(let user):
            if !AccountManager.shared.isProfileComplete(user) {
                let vc = CompleteProfileViewController()
                navigationController?.pushViewController(vc, animated: true)
            } else {
                RootCoordinator.shared.showMainFlow(in: view.window!)
            }
        case .failure(let err):
            errorLabel.text = err.userMessage
        }
    }
}

// MARK: - Shared auth visual components

enum AuthDesign {
    static let backgroundColor = UIColor(hex: 0xFAF9F3)
    static let lime = UIColor(hex: 0xD7FF35)

    static func makeBackButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.accessibilityLabel = "Back"
        return button
    }

    static func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = AppTheme.ink
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.adjustsFontSizeToFitWidth = false
        return label
    }

    static func makeTitle(_ text: String, size: CGFloat = 36) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = -2
        paragraph.alignment = .left
        return NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: .bold),
            .foregroundColor: AppTheme.ink,
            .paragraphStyle: paragraph
        ])
    }

    static func makeSubtitleLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor(hex: 0x74766F)
        label.font = .systemFont(ofSize: 13, weight: .regular)
        return label
    }

    static func makeSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = UIColor(hex: 0xDFDED8)
        return separator
    }

    static func makeFieldCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor(hex: 0x6F716B),
            .kern: 0.8
        ])
        return label
    }

    static func makeHintLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(hex: 0x62655D)
        label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        return label
    }

    static func makeLinkTitle(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor(hex: 0x73756F),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ])
    }
}

final class AuthFormBackgroundView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: 0xD9FF3F)
        layer.cornerRadius = 24
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 10)

        // Figma gradient stops supplied for the form container:
        // 0% #D9FF3F → 100% #EFFFB1.
        gradientLayer.colors = [
            UIColor(hex: 0xD9FF3F).cgColor,
            UIColor(hex: 0xEFFFB1).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = 24
        gradientLayer.masksToBounds = true
        layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    required init?(coder: NSCoder) { fatalError() }
}

final class AuthBottomButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .highlighted)
        titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        backgroundColor = UIColor(hex: 0x0D110F)
        layer.cornerRadius = 14
        layer.masksToBounds = false
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 10
        layer.shadowOffset = .zero
    }

    required init?(coder: NSCoder) { fatalError() }
}

extension UITextField {
    /// 旧页面仍使用的通用输入框样式；保留该入口避免影响非登录表单。
    func configureYorvaField(placeholder: String) {
        font = AppFont.textFieldInput()
        textColor = AppTheme.ink
        backgroundColor = AppTheme.bgRoot
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = AppTheme.divider.cgColor
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        self.leftView = leftView
        self.leftViewMode = .always
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
            .foregroundColor: AppTheme.stone,
            .font: AppFont.textFieldInput()
        ])
        autocapitalizationType = .none
        autocorrectionType = .no
    }

    func configureAuthField(placeholder: String) {
        font = .systemFont(ofSize: 13, weight: .regular)
        textColor = AppTheme.ink
        backgroundColor = UIColor(hex: 0xF8FFE0)
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: 0xD9DDD1).cgColor
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        self.leftView = leftView
        self.leftViewMode = .always
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
            .foregroundColor: UIColor(hex: 0x9A9D95),
            .font: UIFont.systemFont(ofSize: 13, weight: .regular)
        ])
        autocapitalizationType = .none
        autocorrectionType = .no
    }
}
