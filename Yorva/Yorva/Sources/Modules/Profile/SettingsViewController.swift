//
//  SettingsViewController.swift
//  Yorva
//
//  Settings（铁律 3 / 铁律 5 / 铁律 10）
//  - Block List、Privacy Policy、Terms of Service、Log Out、Delete Account
//

import UIKit
import SnapKit

final class SettingsViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgSettings }
    override var isSecondaryLevel: Bool { true }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Row: Int, CaseIterable {
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
        var isDestructive: Bool { self == .logOut || self == .deleteAccount }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        setupHierarchy()
        applyAutoLayoutConstraints()
    }

    override func setupHierarchy() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        view.addSubview(tableView)
    }

    override func applyAutoLayoutConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Row.allCases.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        let row = Row.allCases[indexPath.row]
        cell.textLabel?.text = row.title
        cell.textLabel?.font = AppFont.body()
        cell.textLabel?.textColor = row.isDestructive ? AppTheme.error : AppTheme.ink
        cell.accessoryType = row == .blockList ? .disclosureIndicator : .none
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = Row.allCases[indexPath.row]
        switch row {
        case .blockList:
            navigationController?.pushViewController(BlockListViewController(), animated: true)
        case .privacy:
            let vc = WebContainerViewController()
            vc.title = "Privacy Policy"
            vc.targetURL = URL(string: "https://www.baidu.com")
            navigationController?.pushViewController(vc, animated: true)
        case .terms:
            let vc = WebContainerViewController()
            vc.title = "Terms of Service"
            vc.targetURL = URL(string: "https://www.baidu.com")
            navigationController?.pushViewController(vc, animated: true)
        case .logOut:
            ConfirmDialog.show(title: "Log Out?",
                              message: "You'll return to the sign in screen. Your account stays intact.",
                              confirmTitle: "Log Out", cancelTitle: "Cancel", isDestructive: true) {
                AccountManager.shared.logout()
                RootCoordinator.shared.routeToAuth()
            }
        case .deleteAccount:
            ConfirmDialog.show(title: "Delete Account",
                              message: "This action cannot be undone. You won't be able to sign in with this account again.",
                              confirmTitle: "Delete", cancelTitle: "Cancel", isDestructive: true) {
                AccountManager.shared.deleteAccount()
                RootCoordinator.shared.routeToAuth()
            }
        }
    }
}
