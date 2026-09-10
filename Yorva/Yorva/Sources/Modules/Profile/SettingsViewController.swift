//
//  SettingsViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class SettingsViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let navTitleLabel = UILabel()
    private let navDivider = UIView()
    private let titleLabel = UILabel()
    private let accountSectionLabel = UILabel()
    private let legalSectionLabel = UILabel()
    private let actionsSectionLabel = UILabel()
    private let accountCard = UIView()
    private let legalCard = UIView()
    private let actionsCard = UIView()

    private enum Row {
        case blockList, privacy, terms, logOut, deleteAccount

        var title: String {
            switch self {
            case .blockList: return "Block List"
            case .privacy: return "Privacy Policy"
            case .terms: return "Terms of Service"
            case .logOut: return "Log Out"
            case .deleteAccount: return "Delete Account"
            }
        }

        var subtitle: String {
            switch self {
            case .blockList: return "Manage people you've blocked"
            case .privacy: return "How Yorva handles your information"
            case .terms: return "The rules for using Yorva"
            case .logOut: return "Sign out of this account"
            case .deleteAccount: return "Permanently remove your account"
            }
        }

        var icon: String {
            switch self {
            case .blockList: return "person.badge.minus"
            case .privacy: return "doc.text"
            case .terms: return "newspaper"
            case .logOut: return "rectangle.portrait.and.arrow.right"
            case .deleteAccount: return "trash"
            }
        }

        var isDestructive: Bool { self == .logOut || self == .deleteAccount }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupHierarchy() {
        topBar.backgroundColor = UIColor(hex: 0xFAF9F3)
        backButton.setImage(UIImage(systemName: "chevron.backward")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 18
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        backButton.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        navTitleLabel.attributedText = NSAttributedString(string: "SETTINGS", attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x7B7E77),
            .kern: 1.8
        ])
        navTitleLabel.textAlignment = .center
        navDivider.backgroundColor = UIColor(hex: 0xE1E0D9)

        titleLabel.text = "Settings."
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = AppTheme.ink
        configureSectionLabel(accountSectionLabel, title: "ACCOUNT & SAFETY")
        configureSectionLabel(legalSectionLabel, title: "LEGAL")
        configureSectionLabel(actionsSectionLabel, title: "ACCOUNT ACTIONS")

        configureCard(accountCard, rows: [
            makeRow(.blockList) { [weak self] in self?.openBlockList() }
        ])
        configureCard(legalCard, rows: [
            makeRow(.privacy) { [weak self] in self?.openLegal(title: "Privacy Policy") },
            makeRow(.terms) { [weak self] in self?.openLegal(title: "Terms of Service") }
        ])
        configureCard(actionsCard, rows: [
            makeRow(.logOut) { [weak self] in self?.confirmLogout() },
            makeRow(.deleteAccount) { [weak self] in self?.confirmDeleteAccount() }
        ])
        actionsCard.layer.borderColor = UIColor(hex: 0xF1CFC8).cgColor

        [backButton, navTitleLabel].forEach { topBar.addSubview($0) }
        [topBar, navDivider, titleLabel, accountSectionLabel, legalSectionLabel,
         actionsSectionLabel, accountCard, legalCard, actionsCard].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        topBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(106)
        }
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(6)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(36)
        }
        navTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }
        navDivider.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(-1)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(17)
        }
        accountSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(20)
        }
        accountCard.snp.makeConstraints { make in
            make.top.equalTo(accountSectionLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(64)
        }
        legalSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(accountCard.snp.bottom).offset(20)
            make.left.equalTo(accountSectionLabel)
        }
        legalCard.snp.makeConstraints { make in
            make.top.equalTo(legalSectionLabel.snp.bottom).offset(8)
            make.left.right.equalTo(accountCard)
            make.height.equalTo(128)
        }
        actionsSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(legalCard.snp.bottom).offset(20)
            make.left.equalTo(accountSectionLabel)
        }
        actionsCard.snp.makeConstraints { make in
            make.top.equalTo(actionsSectionLabel.snp.bottom).offset(8)
            make.left.right.equalTo(accountCard)
            make.height.equalTo(126)
        }
    }

    private func configureSectionLabel(_ label: UILabel, title: String) {
        label.attributedText = NSAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor(hex: 0x85857D),
            .kern: 1.2
        ])
    }

    private func configureCard(_ card: UIView, rows: [UIView]) {
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        card.layer.masksToBounds = true
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 0
        card.addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    private func makeRow(_ row: Row, action: @escaping () -> Void) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.snp.makeConstraints { make in make.height.equalTo(64) }

        let iconView = UIView()
        iconView.backgroundColor = row.isDestructive ? UIColor(hex: 0xFFF0ED) : UIColor(hex: 0xF0F0E9)
        iconView.layer.cornerRadius = 14
        let icon = UIImageView(image: UIImage(systemName: row.icon)?.withTintColor(row.isDestructive ? UIColor(hex: 0xB33A2E) : AppTheme.ink, renderingMode: .alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        let title = UILabel()
        title.text = row.title
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = row.isDestructive ? UIColor(hex: 0xB33A2E) : AppTheme.ink
        let subtitle = UILabel()
        subtitle.text = row.subtitle
        subtitle.font = .systemFont(ofSize: 10, weight: .regular)
        subtitle.textColor = UIColor(hex: 0x85857D)
        let chevron = UILabel()
        chevron.text = "›"
        chevron.font = .systemFont(ofSize: 18, weight: .regular)
        chevron.textColor = UIColor(hex: 0x85857D)
        [iconView, title, subtitle, chevron].forEach { container.addSubview($0) }
        iconView.addSubview(icon)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(16)
        }
        title.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.top.equalToSuperview().offset(15)
            make.right.equalTo(chevron.snp.left).offset(-8)
        }
        subtitle.snp.makeConstraints { make in
            make.left.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(2)
            make.right.equalTo(title)
        }
        chevron.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(12)
        }
        let button = UIButton(type: .custom)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        container.addSubview(button)
        button.snp.makeConstraints { make in make.edges.equalToSuperview() }
        let divider = UIView()
        divider.backgroundColor = UIColor(hex: 0xE8E6DF)
        container.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        return container
    }

    private func openBlockList() {
        navigationController?.pushViewController(BlockListViewController(), animated: true)
    }

    private func openLegal(title: String) {
        let vc = WebContainerViewController()
        vc.title = title
        vc.targetURL = URL(string: title == "Privacy Policy"
            ? "https://sites.google.com/view/yorva/privacy"
            : "https://sites.google.com/view/yorva/users")
        navigationController?.pushViewController(vc, animated: true)
    }

    private func confirmLogout() {
        ConfirmDialog.show(title: "Log Out?", message: "You'll return to the sign in screen. Your account stays intact.",
                           confirmTitle: "Log Out", cancelTitle: "Cancel", isDestructive: true) {
            AccountManager.shared.logout()
            RootCoordinator.shared.routeToAuth()
        }
    }

    private func confirmDeleteAccount() {
        ConfirmDialog.show(title: "Delete Account", message: "This action cannot be undone. You won't be able to sign in with this account again.",
                           confirmTitle: "Delete", cancelTitle: "Cancel", isDestructive: true) {
            AccountManager.shared.deleteAccount()
            RootCoordinator.shared.routeToAuth()
        }
    }
}
