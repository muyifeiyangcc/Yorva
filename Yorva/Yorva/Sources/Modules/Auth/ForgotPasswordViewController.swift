//
//  ForgotPasswordViewController.swift
//  Yorva
//
//  找回密码：保存成功后回到登录页
//

import UIKit
import SnapKit

final class ForgotPasswordViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let emailField = UITextField()
    private let newPasswordField = UITextField()
    private let confirmField = UITextField()
    private let saveButton = PrimaryButton(title: "Save")
    private let errorLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Forgot Password"
        setupHierarchy()
        applyAutoLayoutConstraints()
    }

    override func setupHierarchy() {
        emailField.configureYorvaField(placeholder: "Email")
        emailField.keyboardType = .emailAddress
        newPasswordField.configureYorvaField(placeholder: "New password (8+ chars)")
        newPasswordField.isSecureTextEntry = true
        confirmField.configureYorvaField(placeholder: "Confirm new password")
        confirmField.isSecureTextEntry = true
        errorLabel.font = AppFont.textFieldError()
        errorLabel.textColor = AppTheme.textError
        errorLabel.numberOfLines = 0
        saveButton.addAction(UIAction { [weak self] _ in self?.attemptSave() }, for: .touchUpInside)
        [emailField, newPasswordField, confirmField, errorLabel, saveButton].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        emailField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
        newPasswordField.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(16)
            make.left.right.height.equalTo(emailField)
        }
        confirmField.snp.makeConstraints { make in
            make.top.equalTo(newPasswordField.snp.bottom).offset(16)
            make.left.right.height.equalTo(emailField)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(confirmField.snp.bottom).offset(8)
            make.left.right.equalTo(emailField)
        }
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(16)
            make.left.right.equalTo(emailField)
        }
    }

    private func attemptSave() {
        let email = emailField.text ?? ""
        let pwd = newPasswordField.text ?? ""
        let confirm = confirmField.text ?? ""
        guard email.isValidEmail else { errorLabel.text = "Please enter a valid email."; return }
        guard pwd.count >= 8 else { errorLabel.text = "Password must be at least 8 characters."; return }
        guard pwd == confirm else { errorLabel.text = "Passwords do not match."; return }
        let result = AccountManager.shared.resetPassword(email: email, newPassword: pwd)
        switch result {
        case .success:
            Toast.show("Password updated. Please sign in.")
            navigationController?.popToRootViewController(animated: true)
        case .failure(let err):
            errorLabel.text = err.userMessage
        }
    }
}
