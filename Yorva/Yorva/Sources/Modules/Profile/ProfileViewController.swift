//
//  ProfileViewController.swift
//  Yorva
//
//  Tab4 Profile（铁律 5 / 铁律 8 / 铁律 9）
//  - 头像、昵称、签名；Posts / Followers / Following 数字
//  - Coins 横幅显示余额 + Recharge
//  - My posts / Saved 切换列表
//

import UIKit
import SnapKit

final class ProfileViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgRoot }

    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let postsCountLabel = UILabel()
    private let followersCountLabel = UILabel()
    private let followingCountLabel = UILabel()
    private let postsTitleLabel = UILabel()
    private let followersTitleLabel = UILabel()
    private let followingTitleLabel = UILabel()
    private let coinsBanner = UIView()
    private let coinsLabel = UILabel()
    private let rechargeButton = UIButton(type: .system)
    private let editProfileButton = TextLinkButton(title: "Edit Profile")
    private let settingsButton = UIButton(type: .system)
    private let segment = UISegmentedControl(items: ["My posts", "Saved"])
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var posts: [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
        refreshData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    override func setupHierarchy() {
        avatar.configure(user: AccountManager.shared.currentUser)
        nameLabel.font = AppFont.cardTitleSemibold()
        nameLabel.textColor = AppTheme.ink
        bioLabel.font = AppFont.bodySecondary()
        bioLabel.textColor = AppTheme.textSecondary
        bioLabel.numberOfLines = 0

        for (label, title) in [(postsCountLabel, "Posts"), (followersCountLabel, "Followers"), (followingCountLabel, "Following")] {
            label.font = AppFont.statNumber()
            label.textColor = AppTheme.ink
            label.textAlignment = .center
        }
        for (label, title) in [(postsTitleLabel, "Posts"), (followersTitleLabel, "Followers"), (followingTitleLabel, "Following")] {
            label.font = AppFont.caption()
            label.textColor = AppTheme.stone
            label.textAlignment = .center
            label.text = title
        }
        for label in [followersCountLabel, followersTitleLabel] {
            let tap = UITapGestureRecognizer(target: self, action: #selector(openFollowers))
            label.addGestureRecognizer(tap); label.isUserInteractionEnabled = true
        }
        for label in [followingCountLabel, followingTitleLabel] {
            let tap = UITapGestureRecognizer(target: self, action: #selector(openFollowing))
            label.addGestureRecognizer(tap); label.isUserInteractionEnabled = true
        }

        coinsBanner.backgroundColor = AppTheme.coinsBg
        coinsBanner.layer.cornerRadius = 12
        coinsBanner.layer.masksToBounds = true
        let coinsTitle = UILabel()
        coinsTitle.font = AppFont.captionStrong()
        coinsTitle.textColor = AppTheme.textSecondary
        coinsTitle.text = "Coins balance"
        coinsLabel.font = AppFont.coinNumber()
        coinsLabel.textColor = AppTheme.textCoins
        rechargeButton.setTitle("Recharge", for: .normal)
        rechargeButton.setTitleColor(AppTheme.textOnPrimary, for: .normal)
        rechargeButton.titleLabel?.font = AppFont.buttonSecondary()
        rechargeButton.backgroundColor = AppTheme.primary
        rechargeButton.layer.cornerRadius = 18
        rechargeButton.addAction(UIAction { [weak self] _ in
            let vc = RechargeViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        [coinsTitle, coinsLabel, rechargeButton].forEach { coinsBanner.addSubview($0) }
        coinsTitle.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(12)
        }
        coinsLabel.snp.makeConstraints { make in
            make.left.equalTo(coinsTitle)
            make.top.equalTo(coinsTitle.snp.bottom).offset(2)
        }
        rechargeButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(110)
            make.height.equalTo(36)
        }

        editProfileButton.addAction(UIAction { [weak self] _ in
            let vc = EditProfileViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        settingsButton.setImage(UIImage(systemName: "gearshape")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        settingsButton.addAction(UIAction { [weak self] _ in
            let vc = SettingsViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)

        segment.selectedSegmentIndex = 0
        segment.backgroundColor = AppTheme.bgPrimary
        segment.selectedSegmentTintColor = AppTheme.cream
        segment.setTitleTextAttributes([.font: AppFont.buttonSecondary(), .foregroundColor: AppTheme.stone], for: .normal)
        segment.setTitleTextAttributes([.font: AppFont.buttonPrimary(), .foregroundColor: AppTheme.primary], for: .selected)
        segment.addAction(UIAction { [weak self] _ in self?.refreshData() }, for: .valueChanged)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier)
        tableView.estimatedRowHeight = 320
        tableView.rowHeight = UITableView.automaticDimension

        [avatar, nameLabel, bioLabel, postsCountLabel, postsTitleLabel,
         followersCountLabel, followersTitleLabel, followingCountLabel, followingTitleLabel,
         coinsBanner, editProfileButton, settingsButton, segment, tableView].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        avatar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(72)
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalTo(avatar)
        }
        bioLabel.snp.makeConstraints { make in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
        settingsButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(nameLabel)
            make.size.equalTo(28)
        }
        // 三段统计
        func statConstraints(_ count: UILabel, _ title: UILabel, prev: UIView?) {
            count.snp.makeConstraints { make in
                make.top.equalTo(bioLabel.snp.bottom).offset(16)
                if let prev = prev { make.left.equalTo(prev.snp.right).offset(20) }
                else { make.left.equalTo(avatar) }
            }
            title.snp.makeConstraints { make in
                make.top.equalTo(count.snp.bottom).offset(2)
                make.centerX.equalTo(count)
            }
        }
        statConstraints(postsCountLabel, postsTitleLabel, prev: nil)
        statConstraints(followersCountLabel, followersTitleLabel, prev: postsTitleLabel)
        statConstraints(followingCountLabel, followingTitleLabel, prev: followersTitleLabel)
        coinsBanner.snp.makeConstraints { make in
            make.top.equalTo(postsTitleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(80)
        }
        editProfileButton.snp.makeConstraints { make in
            make.top.equalTo(coinsBanner.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        segment.snp.makeConstraints { make in
            make.top.equalTo(editProfileButton.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segment.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] _ in self?.refreshData() }
    }

    override func refreshData() {
        if AccountManager.shared.isGuest {
            // 游客态（铁律 2）：不展示任何内容，拦截已在根页面统一处理
            return
        }
        let user = AccountManager.shared.currentUser
        avatar.configure(user: user)
        nameLabel.text = user?.nickname
        bioLabel.text = user?.bio
        let me = user?.id ?? ""
        postsCountLabel.text = "\(ContentManager.shared.postsBy(authorId: me).count)"
        followersCountLabel.text = "\(FollowManager.shared.followers(userId: me).count)"
        followingCountLabel.text = "\(FollowManager.shared.following(userId: me).count)"
        coinsLabel.text = "\(CurrencyManager.shared.coins)"
        posts = segment.selectedSegmentIndex == 0
            ? ContentManager.shared.postsBy(authorId: me)
            : ContentManager.shared.savedPosts()
        tableView.reloadData()
    }

    @objc private func openFollowers() {
        let vc = FollowersViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func openFollowing() {
        let vc = FollowingViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate, PostCardCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { posts.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier, for: indexPath) as! PostCardCell
        let post = posts[indexPath.row]
        cell.configure(post: post, author: DataRepository.shared.user(by: post.authorId))
        cell.delegate = self
        return cell
    }
    func postCardDidTapAuthor(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        let post = posts[idx]
        if let author = DataRepository.shared.user(by: post.authorId) {
            let vc = AuthorProfileViewController()
            vc.author = author
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    func postCardDidTapMore(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        MoreMenu.showPostMoreMenu(post: posts[idx], from: self)
    }
    func postCardDidTapLike(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        ContentManager.shared.toggleLike(postId: posts[idx].id)
    }
    func postCardDidTapComment(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        let vc = PostDetailViewController()
        vc.postId = posts[idx].id
        navigationController?.pushViewController(vc, animated: true)
    }
    func postCardDidTapSave(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        ContentManager.shared.toggleSave(postId: posts[idx].id)
    }
    func postCardDidTapPost(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        let vc = PostDetailViewController()
        vc.postId = posts[idx].id
        navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = PostDetailViewController()
        vc.postId = posts[indexPath.row].id
        navigationController?.pushViewController(vc, animated: true)
    }
}
