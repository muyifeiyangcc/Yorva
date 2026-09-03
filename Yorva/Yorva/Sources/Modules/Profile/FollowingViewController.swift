//
//  FollowingViewController.swift
//  Yorva
//
//  Following 列表 + 取消关注（铁律 8 状态联动）
//

import UIKit
import SnapKit

final class FollowingViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = LoadingView()
    private var users: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Following"
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
        refreshData()
    }

    override func setupHierarchy() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(FollowRowCell.self, forCellReuseIdentifier: FollowRowCell.reuseIdentifier)
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)
    }

    override func applyAutoLayoutConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            if case .followChanged = event { self?.refreshData() }
        }
    }

    override func refreshData() {
        guard let me = AccountManager.shared.currentUser else { return }
        users = FollowManager.shared.following(userId: me.id)
            .compactMap { DataRepository.shared.user(by: $0) }
        if users.isEmpty {
            loadingView.state = .empty(title: "You're not following anyone yet",
                                       subtitle: "Visit Explore to discover people worth following.",
                                       actionTitle: nil)
            loadingView.show(in: view)
        } else {
            loadingView.hide()
        }
        tableView.reloadData()
    }
}

extension FollowingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { users.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FollowRowCell.reuseIdentifier, for: indexPath) as! FollowRowCell
        cell.configure(user: users[indexPath.row], isFollowingContext: true)
        cell.onToggle = { [weak self] in self?.refreshData() }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = AuthorProfileViewController()
        vc.author = users[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
