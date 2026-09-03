//
//  FollowersViewController.swift
//  Yorva
//
//  Followers 列表 + 关注 / 取消关注（铁律 8 状态联动）
//

import UIKit
import SnapKit

final class FollowersViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = LoadingView()
    private var users: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Followers"
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
        users = FollowManager.shared.followers(userId: me.id)
            .compactMap { DataRepository.shared.user(by: $0) }
        if users.isEmpty {
            loadingView.state = .empty(title: "No followers yet", subtitle: "Share a thoughtful post to gather your first followers.", actionTitle: nil)
            loadingView.show(in: view)
        } else {
            loadingView.hide()
        }
        tableView.reloadData()
    }
}

extension FollowersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { users.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FollowRowCell.reuseIdentifier, for: indexPath) as! FollowRowCell
        cell.configure(user: users[indexPath.row], isFollowingContext: false)
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

final class FollowRowCell: UITableViewCell {
    static let reuseIdentifier = "FollowRowCell"
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let followButton = PrimaryButton(title: "Follow")
    var onToggle: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        followButton.layer.cornerRadius = 18
        followButton.addAction(UIAction { [weak self] _ in
            guard let self = self, let user = self.user else { return }
            let me = AccountManager.shared.currentUser?.id ?? ""
            if FollowManager.shared.isFollowing(followerId: me, followeeId: user.id) {
                FollowManager.shared.unfollow(followerId: me, followeeId: user.id)
            } else {
                FollowManager.shared.follow(followerId: me, followeeId: user.id)
            }
            self.onToggle?()
        }, for: .touchUpInside)
        [avatar, nameLabel, bioLabel, followButton].forEach { contentView.addSubview($0) }
        avatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        nameLabel.font = AppFont.cardTitle()
        nameLabel.textColor = AppTheme.ink
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(8)
            make.top.equalTo(avatar).offset(2)
            make.right.equalTo(followButton.snp.left).offset(-8)
        }
        bioLabel.font = AppFont.caption()
        bioLabel.textColor = AppTheme.stone
        bioLabel.snp.makeConstraints { make in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
        followButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
            make.width.equalTo(100)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    private var user: User?
    func configure(user: User, isFollowingContext: Bool) {
        self.user = user
        avatar.configure(user: user)
        nameLabel.text = user.nickname
        bioLabel.text = user.bio
        let me = AccountManager.shared.currentUser?.id ?? ""
        let isFollowing = FollowManager.shared.isFollowing(followerId: me, followeeId: user.id)
        followButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
        followButton.backgroundColor = isFollowing ? AppTheme.cream : AppTheme.primary
        followButton.setTitleColor(isFollowing ? AppTheme.textSecondary : AppTheme.textOnPrimary, for: .normal)
    }
}
