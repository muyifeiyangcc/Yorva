//
//  FollowersViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class FollowersViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let navTitleLabel = UILabel()
    private let navDivider = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let listScrollView = UIScrollView()
    private let listContentView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = LoadingView()
    private var users: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        navTitleLabel.attributedText = NSAttributedString(string: "FOLLOWERS", attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x7B7E77),
            .kern: 1.8
        ])
        navTitleLabel.textAlignment = .center
        navDivider.backgroundColor = UIColor(hex: 0xE1E0D9)
        titleLabel.text = "Followers."
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = AppTheme.ink
        subtitleLabel.text = "People who choose to keep up with your quieter way of\nliving."
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor(hex: 0x7B7E77)
        subtitleLabel.numberOfLines = 2
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .white
        tableView.layer.cornerRadius = 18
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        tableView.layer.masksToBounds = true
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(hex: 0xE8E6DF)
        tableView.separatorInset = .zero
        tableView.register(FollowRowCell.self, forCellReuseIdentifier: FollowRowCell.reuseIdentifier)
        tableView.rowHeight = 78
        tableView.isScrollEnabled = false
        listScrollView.alwaysBounceVertical = true
        listScrollView.showsVerticalScrollIndicator = false
        listScrollView.contentInsetAdjustmentBehavior = .never
        [backButton, navTitleLabel].forEach { topBar.addSubview($0) }
        loadingView.backgroundColor = pageBackgroundColor
        loadingView.isHidden = true
        [titleLabel, subtitleLabel, tableView].forEach { listContentView.addSubview($0) }
        listScrollView.addSubview(listContentView)
        [topBar, navDivider, listScrollView, loadingView].forEach { view.addSubview($0) }
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
        listScrollView.snp.makeConstraints { make in
            make.top.equalTo(navDivider.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        listContentView.snp.makeConstraints { make in
            make.edges.equalTo(listScrollView.contentLayoutGuide)
            make.width.equalTo(listScrollView.frameLayoutGuide)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(17)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalTo(titleLabel)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(22)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(0)
            make.bottom.equalToSuperview().inset(24)
        }
        loadingView.snp.makeConstraints { make in
            make.top.equalTo(navDivider.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
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
        tableView.snp.updateConstraints { make in
            make.height.equalTo(CGFloat(users.count) * 78)
        }
        if users.isEmpty {
            loadingView.state = .empty(title: "No followers yet", subtitle: "Share a thoughtful post to gather your first followers.", actionTitle: nil)
            tableView.isHidden = true
            loadingView.isHidden = false
        } else {
            tableView.isHidden = false
            loadingView.isHidden = true
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
    private let followButton = UIButton(type: .system)
    var onToggle: (() -> Void)?
    private var isFollowingContext = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        followButton.layer.cornerRadius = 15
        followButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .regular)
        followButton.addAction(UIAction { [weak self] _ in
            guard let self = self, let user = self.user else { return }
            let me = AccountManager.shared.currentUser?.id ?? ""
            if self.isFollowingContext || FollowManager.shared.isFollowing(followerId: me, followeeId: user.id) {
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
            make.height.equalTo(30)
            make.width.equalTo(64)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    private var user: User?
    func configure(user: User, isFollowingContext: Bool) {
        self.user = user
        self.isFollowingContext = isFollowingContext
        avatar.configure(user: user)
        nameLabel.text = user.nickname
        bioLabel.text = user.bio
        let me = AccountManager.shared.currentUser?.id ?? ""
        // A Following list only contains accounts already followed by the user;
        // keep every row in the selected dark state even if the backing store is
        // being refreshed asynchronously.
        let isFollowing = isFollowingContext || FollowManager.shared.isFollowing(followerId: me, followeeId: user.id)
        followButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
        followButton.backgroundColor = isFollowing ? UIColor(hex: 0xF0F0E9) : AppTheme.ink
        followButton.setTitleColor(isFollowing ? UIColor(hex: 0x85857D) : UIColor.white, for: .normal)
    }
}
