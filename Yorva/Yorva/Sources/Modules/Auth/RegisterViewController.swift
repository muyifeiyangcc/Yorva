//
//  RegisterViewController.swift
//  Yorva
//
//  注册（铁律 9 初始金币为 0 + 铁律 10 预置账号规则）
//

import UIKit
import SnapKit

final class RegisterViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let confirmField = UITextField()
    private let signUpButton = PrimaryButton(title: "Sign up")
    private let errorLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign Up"
        setupHierarchy()
        applyAutoLayoutConstraints()
    }

    override func setupHierarchy() {
        emailField.configureYorvaField(placeholder: "Email")
        emailField.keyboardType = .emailAddress
        passwordField.configureYorvaField(placeholder: "Password (8+ chars)")
        passwordField.isSecureTextEntry = true
        confirmField.configureYorvaField(placeholder: "Confirm password")
        confirmField.isSecureTextEntry = true
        errorLabel.font = AppFont.textFieldError()
        errorLabel.textColor = AppTheme.textError
        errorLabel.numberOfLines = 0
        signUpButton.addAction(UIAction { [weak self] _ in self?.attemptRegister() }, for: .touchUpInside)
        [emailField, passwordField, confirmField, errorLabel, signUpButton].forEach { view.addSubview($0) }
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
        confirmField.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(16)
            make.left.right.height.equalTo(emailField)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(confirmField.snp.bottom).offset(8)
            make.left.right.equalTo(emailField)
        }
        signUpButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(16)
            make.left.right.equalTo(emailField)
        }
    }

    private func attemptRegister() {
        let email = emailField.text ?? ""
        let password = passwordField.text ?? ""
        let confirm = confirmField.text ?? ""
        guard email.isValidEmail else { errorLabel.text = "Please enter a valid email."; return }
        guard password.count >= 8 else { errorLabel.text = "Password must be at least 8 characters."; return }
        guard password == confirm else { errorLabel.text = "Passwords do not match."; return }
        errorLabel.text = ""
        switch AccountManager.shared.register(email: email, password: password) {
        case .success:
            // 注册成功：进入完善资料页（资料不完整）
            let vc = CompleteProfileViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .failure(let err):
            errorLabel.text = err.userMessage
        }
    }
}
