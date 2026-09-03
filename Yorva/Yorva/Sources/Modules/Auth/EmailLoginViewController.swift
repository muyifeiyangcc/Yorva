//
//  EmailLoginViewController.swift
//  Yorva
//
//  邮箱登录（铁律 4 + 铁律 10）
//

import UIKit
import SnapKit

final class EmailLoginViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let forgotButton = TextLinkButton(title: "Forgot password?")
    private let signInButton = PrimaryButton(title: "Sign in")
    private let errorLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign In"
        setupHierarchy()
        applyAutoLayoutConstraints()
    }

    override func setupHierarchy() {
        emailField.configureYorvaField(placeholder: "Email")
        emailField.keyboardType = .emailAddress
        passwordField.configureYorvaField(placeholder: "Password")
        passwordField.isSecureTextEntry = true
        errorLabel.font = AppFont.textFieldError()
        errorLabel.textColor = AppTheme.textError
        errorLabel.numberOfLines = 0
        signInButton.addAction(UIAction { [weak self] _ in self?.attemptLogin() }, for: .touchUpInside)
        forgotButton.addAction(UIAction { [weak self] _ in
            let vc = ForgotPasswordViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        [emailField, passwordField, errorLabel, signInButton, forgotButton].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        emailField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(16)
            make.left.right.height.equalTo(emailField)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(8)
            make.left.right.equalTo(passwordField)
        }
        signInButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(16)
            make.left.right.equalTo(passwordField)
        }
        forgotButton.snp.makeConstraints { make in
            make.top.equalTo(signInButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
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

extension UITextField {
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
            .foregroundColor: AppTheme.stone, .font: AppFont.textFieldInput()
        ])
        autocapitalizationType = .none
        autocorrectionType = .no
    }
}
