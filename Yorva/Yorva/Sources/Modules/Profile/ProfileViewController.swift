//
//  ProfileViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class ProfileViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgRoot }

    private let brandLabel = UILabel()
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let postsCountLabel = UILabel()
    private let followersCountLabel = UILabel()
    private let followingCountLabel = UILabel()
    private let postsTitleLabel = UILabel()
    private let followersTitleLabel = UILabel()
    private let followingTitleLabel = UILabel()
    private let postsStatCard = UIView()
    private let followersStatCard = UIView()
    private let followingStatCard = UIView()
    private let coinsBanner = UIView()
    private let coinsBackgroundImageView = UIImageView()
    private let coinsLabel = UILabel()
    private let rechargeButton = UIButton(type: .system)
    private let editProfileButton = TextLinkButton(title: "Edit Profile")
    private let settingsButton = UIButton(type: .system)
    private let segment = UISegmentedControl(items: ["My posts", "Saved"])
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var posts: [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func setupHierarchy() {
        brandLabel.text = "yorva"
        brandLabel.font = .systemFont(ofSize: 23, weight: .bold)
        brandLabel.textColor = AppTheme.ink
        avatar.configure(user: AccountManager.shared.currentUser)
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openEditProfile)))
        nameLabel.font = AppFont.cardTitleSemibold()
        nameLabel.textColor = AppTheme.ink
        bioLabel.font = AppFont.bodySecondary()
        bioLabel.textColor = AppTheme.textSecondary
        bioLabel.numberOfLines = 0

        for label in [postsCountLabel, followersCountLabel, followingCountLabel] {
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
        [postsStatCard, followersStatCard, followingStatCard].forEach {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 16
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        }
        followersStatCard.isUserInteractionEnabled = true
        followersStatCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openFollowers)))
        followingStatCard.isUserInteractionEnabled = true
        followingStatCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openFollowing)))
        for (card, count, title) in [(postsStatCard, postsCountLabel, postsTitleLabel),
                                     (followersStatCard, followersCountLabel, followersTitleLabel),
                                     (followingStatCard, followingCountLabel, followingTitleLabel)] {
            card.addSubview(count)
            card.addSubview(title)
            count.snp.makeConstraints { make in
                make.left.top.equalToSuperview().offset(12)
            }
            title.snp.makeConstraints { make in
                make.left.equalTo(count)
                make.top.equalTo(count.snp.bottom).offset(3)
            }
        }

        coinsBanner.backgroundColor = .clear
        coinsBanner.layer.cornerRadius = 16
        coinsBanner.layer.masksToBounds = true
        coinsBackgroundImageView.image = UIImage(named: "me_coin_bg")
        coinsBackgroundImageView.contentMode = .scaleAspectFill
        coinsBackgroundImageView.clipsToBounds = true
        let coinsTitle = UILabel()
        coinsTitle.font = .systemFont(ofSize: 9, weight: .regular)
        coinsTitle.textColor = AppTheme.ink
        coinsTitle.text = "COIN BALANCE"
        coinsLabel.font = .monospacedDigitSystemFont(ofSize: 30, weight: .bold)
        coinsLabel.textColor = AppTheme.ink
        rechargeButton.setTitle(nil, for: .normal)
        rechargeButton.backgroundColor = .clear
        rechargeButton.isUserInteractionEnabled = false
        coinsBanner.isUserInteractionEnabled = true
        coinsBanner.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openRecharge)))
        [coinsBackgroundImageView, coinsTitle, coinsLabel, rechargeButton].forEach { coinsBanner.addSubview($0) }
        coinsBackgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        coinsTitle.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(79)
            make.top.equalToSuperview().offset(25)
        }
        coinsLabel.snp.makeConstraints { make in
            make.left.equalTo(coinsTitle)
            make.top.equalTo(coinsTitle.snp.bottom).offset(3)
        }
        rechargeButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(58)
        }

        editProfileButton.addAction(UIAction { [weak self] _ in
            let vc = EditProfileViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        settingsButton.setImage(UIImage(systemName: "gearshape")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        settingsButton.accessibilityLabel = "Settings"
        settingsButton.addAction(UIAction { [weak self] _ in
            let vc = SettingsViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)

        segment.selectedSegmentIndex = 0
        segment.backgroundColor = UIColor(hex: 0xE9E7D9)
        segment.selectedSegmentTintColor = AppTheme.ink
        segment.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .regular), .foregroundColor: UIColor(hex: 0x85857D)], for: .normal)
        segment.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.white], for: .selected)
        segment.addAction(UIAction { [weak self] _ in self?.refreshData() }, for: .valueChanged)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier)
        tableView.estimatedRowHeight = 320
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 92, right: 0)

        [brandLabel, settingsButton, avatar, nameLabel, bioLabel,
         postsStatCard, followersStatCard, followingStatCard,
         coinsBanner, segment, tableView].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        brandLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.left.equalToSuperview().offset(19)
            make.height.equalTo(34)
        }
        settingsButton.snp.makeConstraints { make in
            make.centerY.equalTo(brandLabel)
            make.right.equalToSuperview().inset(17)
            make.size.equalTo(32)
        }
        avatar.snp.makeConstraints { make in
            make.top.equalTo(brandLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(72)
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalTo(avatar)
            make.right.equalToSuperview().inset(17)
        }
        bioLabel.snp.makeConstraints { make in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
        let statCards = [postsStatCard, followersStatCard, followingStatCard]
        for (index, card) in statCards.enumerated() {
            card.snp.makeConstraints { make in
                make.top.equalTo(avatar.snp.bottom).offset(16)
                make.bottom.equalTo(coinsBanner.snp.top).offset(-12)
                make.height.equalTo(66)
                make.width.equalTo(108)
                if index == 0 {
                    make.left.equalToSuperview().offset(17)
                } else {
                    make.left.equalTo(statCards[index - 1].snp.right).offset(8)
                }
            }
        }
        coinsBanner.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(114)
        }
        segment.snp.makeConstraints { make in
            make.top.equalTo(coinsBanner.snp.bottom).offset(18)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(36)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segment.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] _ in self?.refreshData() }
    }

    override func refreshData() {
        if AccountManager.shared.isGuest {
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

    @objc private func openEditProfile() {
        let vc = EditProfileViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func openRecharge() {
        let vc = RechargeViewController()
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
