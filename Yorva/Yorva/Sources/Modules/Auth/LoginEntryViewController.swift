//
//  LoginEntryViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

private final class LaunchPillButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(AppTheme.ink, for: .normal)
        setTitleColor(AppTheme.textSecondary, for: .highlighted)
        titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        backgroundColor = .white
        layer.masksToBounds = true
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    required init?(coder: NSCoder) { fatalError() }
}

final class LoginEntryViewController: BaseViewController {

    var fromGuestFlow: Bool = false

    override var pageBackgroundColor: UIColor { AppTheme.bgSplash }
    override var isSecondaryLevel: Bool { fromGuestFlow }

    private let backgroundImageView = UIImageView(image: UIImage(named: "lau"))
    private let signInEmailButton = LaunchPillButton(title: "Sign In By Email")
    private let imNewButton = LaunchPillButton(title: "I’m New")
    private let footerLabel = UILabel()
    private let signUpButton = UIButton(type: .system)
    private let footerStack = UIStackView()
    private let checkbox = UIButton(type: .custom)
    private let agreementTextView = UITextView()
    private var isAgreed: Bool = false

    override func viewDidLoad() {
        // BaseViewController invokes setupHierarchy/applyAutoLayoutConstraints through
        // its lifecycle hooks. Calling them again here would duplicate every subview.
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupHierarchy() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.isUserInteractionEnabled = false
        view.addSubview(backgroundImageView)

        configureActionButton(signInEmailButton)
        configureActionButton(imNewButton)

        footerLabel.attributedText = NSAttributedString(
            string: "Don’t have an account?",
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.white
            ]
        )
        footerLabel.textAlignment = .natural

        let signUpAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor(hex: 0xD7FF35),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        signUpButton.setAttributedTitle(NSAttributedString(string: "Sign up", attributes: signUpAttributes), for: .normal)
        signUpButton.setAttributedTitle(NSAttributedString(string: "Sign up", attributes: signUpAttributes.merging([
            .foregroundColor: UIColor(hex: 0xB8D92A)
        ]) { _, new in new }), for: .highlighted)
        footerStack.axis = .horizontal
        footerStack.alignment = .center
        footerStack.spacing = 3
        footerStack.addArrangedSubview(footerLabel)
        footerStack.addArrangedSubview(signUpButton)

        checkbox.setImage(
            UIImage(systemName: "circle")?.withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        checkbox.setImage(
            UIImage(systemName: "checkmark.circle.fill")?.withTintColor(UIColor(hex: 0xD7FF35), renderingMode: .alwaysOriginal),
            for: .selected
        )
        checkbox.accessibilityLabel = "Agreement"
        checkbox.addAction(UIAction { [weak self] _ in
            self?.checkbox.isSelected.toggle()
            self?.isAgreed = self?.checkbox.isSelected ?? false
        }, for: .touchUpInside)

        agreementTextView.isEditable = false
        agreementTextView.isSelectable = true
        agreementTextView.isScrollEnabled = false
        agreementTextView.backgroundColor = .clear
        agreementTextView.delegate = self
        agreementTextView.textContainerInset = .zero
        agreementTextView.textContainer.lineFragmentPadding = 0
        agreementTextView.attributedText = agreementAttributed()
        agreementTextView.linkTextAttributes = [
            .foregroundColor: UIColor(hex: 0xD7FF35),
            .font: UIFont.systemFont(ofSize: 10.5, weight: .medium),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        signInEmailButton.addAction(UIAction { [weak self] _ in self?.handleSignInByEmail() }, for: .touchUpInside)
        imNewButton.addAction(UIAction { [weak self] _ in self?.handleGuest() }, for: .touchUpInside)
        // Footer sign-up opens the existing registration screen; the separate
        // “I’m New” button keeps its original guest-entry behavior.
        signUpButton.addAction(UIAction { [weak self] _ in
            guard let self = self, self.isAgreed else {
                self?.showAgreementRequiredPrompt()
                return
            }
            let vc = RegisterViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)

        [signInEmailButton, imNewButton, footerStack, checkbox, agreementTextView].forEach {
            view.addSubview($0)
        }
    }

    private func configureActionButton(_ button: UIButton) {
        button.accessibilityTraits = .button
    }

    private func agreementAttributed() -> NSAttributedString {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10.5, weight: .regular),
            .foregroundColor: UIColor.white
        ]
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10.5, weight: .medium),
            .foregroundColor: UIColor(hex: 0xD7FF35),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        let attr = NSMutableAttributedString(
            string: "By continuing you agree to our ",
            attributes: baseAttributes
        )
        attr.append(NSAttributedString(
            string: "Terms of Service",
            attributes: linkAttributes.merging([.link: URL(string: "tos")!]) { _, new in new }
        ))
        attr.append(NSAttributedString(string: " and ", attributes: baseAttributes))
        attr.append(NSAttributedString(
            string: "Privacy Policy",
            attributes: linkAttributes.merging([.link: URL(string: "privacy")!]) { _, new in new }
        ))
        return attr
    }

    override func applyAutoLayoutConstraints() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // These bottom offsets map directly to the 375×812 reference artwork;
        // anchoring the group to the view bottom keeps the composition stable on
        // other heights while allowing the system status/home areas to remain visible.
        imNewButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(45)
            make.height.equalTo(44)
            make.bottom.equalTo(view.snp.bottom).inset(162)
        }
        signInEmailButton.snp.makeConstraints { make in
            make.left.right.equalTo(imNewButton)
            make.height.equalTo(44)
            make.top.equalTo(imNewButton.snp.bottom).offset(20)
        }
        footerStack.snp.makeConstraints { make in
            make.top.equalTo(signInEmailButton.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }
        agreementTextView.snp.makeConstraints { make in
            make.top.equalTo(footerStack.snp.bottom).offset(14)
            make.left.equalToSuperview().offset(66)
            make.right.equalToSuperview().inset(48)
            make.height.equalTo(28)
            make.bottom.equalTo(view.snp.bottom).inset(18)
        }
        checkbox.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(48)
            make.top.equalTo(agreementTextView.snp.top).offset(1)
            make.size.equalTo(14)
        }
    }

    // MARK: - Actions

    private func handleSignInByEmail() {
        guard isAgreed else {
            showAgreementRequiredPrompt()
            return
        }
        let emailVC = EmailLoginViewController()
        navigationController?.pushViewController(emailVC, animated: true)
    }

    private func showAgreementRequiredPrompt() {
        ConfirmDialog.show(title: "Agreement Required",
                           message: "Please read and agree to the agreement first.",
                           confirmTitle: "OK", cancelTitle: "Cancel",
                           onConfirm: {})
    }

    private func handleGuest() {
        RootCoordinator.shared.routeGuestToMain()
    }
}

extension LoginEntryViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        let web = WebContainerViewController()
        if url.absoluteString == "tos" {
            web.title = "Terms of Service"
            web.targetURL = Foundation.URL(string: "https://sites.google.com/view/yorva/users")
        } else {
            web.title = "Privacy Policy"
            web.targetURL = Foundation.URL(string: "https://sites.google.com/view/yorva/privacy")
        }
        navigationController?.pushViewController(web, animated: true)
        return false
    }
}
