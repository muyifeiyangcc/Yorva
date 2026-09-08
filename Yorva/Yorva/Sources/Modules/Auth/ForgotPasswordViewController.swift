//
//  ForgotPasswordViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class ForgotPasswordViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AuthDesign.backgroundColor }
    override var isSecondaryLevel: Bool { true }

    private let backButton = AuthDesign.makeBackButton()
    private let headerSeparator = AuthDesign.makeSeparator()
    private let titleLabel = AuthDesign.makeTitleLabel()
    private let subtitleLabel = AuthDesign.makeSubtitleLabel()
    private let formCard = AuthFormBackgroundView()
    private let emailCaption = AuthDesign.makeFieldCaption("EMAIL")
    private let newPasswordCaption = AuthDesign.makeFieldCaption("NEW PASSWORD")
    private let confirmCaption = AuthDesign.makeFieldCaption("CONFIRM NEW PASSWORD")
    private let emailHint = AuthDesign.makeHintLabel("We'll use this to find your account.")
    private let emailField = UITextField()
    private let newPasswordField = UITextField()
    private let confirmField = UITextField()
    private let saveButton = AuthBottomButton(title: "Save")
    private let errorLabel = UILabel()

    override func shouldUseScrollContainer() -> Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupHierarchy() {
        titleLabel.attributedText = AuthDesign.makeTitle("Create a\nnew password.")
        subtitleLabel.text = "Enter your email and choose a fresh password to get back to your Yorva."

        emailField.configureAuthField(placeholder: "you@example.com")
        emailField.keyboardType = .emailAddress
        newPasswordField.configureAuthField(placeholder: "At least 8 characters")
        newPasswordField.isSecureTextEntry = true
        confirmField.configureAuthField(placeholder: "Re-enter your password")
        confirmField.isSecureTextEntry = true

        errorLabel.font = AppFont.textFieldError()
        errorLabel.textColor = AppTheme.textError
        errorLabel.numberOfLines = 0
        backButton.addAction(UIAction { [weak self] _ in self?.handleBackTapped() }, for: .touchUpInside)
        saveButton.addAction(UIAction { [weak self] _ in self?.attemptSave() }, for: .touchUpInside)

        let host = self.view!
        view.addSubview(backButton)
        [headerSeparator, titleLabel, subtitleLabel, formCard, errorLabel].forEach { host.addSubview($0) }
        [emailCaption, emailField, emailHint, newPasswordCaption, newPasswordField,
         confirmCaption, confirmField].forEach {
            $0.isUserInteractionEnabled = true
            host.addSubview($0)
        }
        view.addSubview(saveButton)
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
            make.top.equalTo(subtitleLabel.snp.bottom).offset(25)
            make.left.right.equalTo(host).inset(23)
            make.height.equalTo(293)
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
        emailHint.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(5)
            make.left.right.equalTo(emailCaption)
        }
        newPasswordCaption.snp.makeConstraints { make in
            make.top.equalTo(emailHint.snp.bottom).offset(15)
            make.left.right.equalTo(emailCaption)
        }
        newPasswordField.snp.makeConstraints { make in
            make.top.equalTo(newPasswordCaption.snp.bottom).offset(7)
            make.left.right.equalTo(emailCaption)
            make.height.equalTo(43)
        }
        confirmCaption.snp.makeConstraints { make in
            make.top.equalTo(newPasswordField.snp.bottom).offset(19)
            make.left.right.equalTo(emailCaption)
        }
        confirmField.snp.makeConstraints { make in
            make.top.equalTo(confirmCaption.snp.bottom).offset(7)
            make.left.right.equalTo(emailCaption)
            make.height.equalTo(43)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(formCard.snp.bottom).offset(6)
            make.left.right.equalTo(formCard)
        }
        saveButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(18)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
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
