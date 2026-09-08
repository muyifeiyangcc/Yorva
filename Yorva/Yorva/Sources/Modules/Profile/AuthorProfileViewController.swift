//
//  AuthorProfileViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class AuthorProfileViewController: BaseViewController {

    var author: User?
    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private let navDivider = UIView()
    private let profileHeader = UIView()
    private let profileCard = UIView()
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let bioLabel = UILabel()
    private let followButton = UIButton(type: .system)
    private let messageButton = UIButton(type: .system)
    private let statsStack = UIStackView()
    private let postsStat = StatCardView()
    private let followersStat = StatCardView()
    private let followingStat = StatCardView()
    private let postsTabButton = UIButton(type: .system)
    private let savedTabButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var posts: [Post] = []
    private var selectedTab = 0

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
        moreButton.setImage(UIImage(systemName: "ellipsis")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        moreButton.backgroundColor = .white
        moreButton.layer.cornerRadius = 18
        moreButton.layer.borderWidth = 1
        moreButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        moreButton.addAction(UIAction { [weak self] _ in
            guard let self, let author = self.author else { return }
            MoreMenu.showAuthorMoreMenu(user: author, from: self)
        }, for: .touchUpInside)
        navDivider.backgroundColor = UIColor(hex: 0xE1E0D9)

        profileCard.backgroundColor = .white
        profileCard.layer.cornerRadius = 22
        profileCard.layer.borderWidth = 1
        profileCard.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        // The header is a self-contained region; never allow its controls to
        // paint over the first PostCell if UITableView is still sizing it.
        profileHeader.clipsToBounds = true
        avatar.configure(user: author)
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = AppTheme.ink
        handleLabel.font = .systemFont(ofSize: 11, weight: .regular)
        handleLabel.textColor = UIColor(hex: 0x7B7E77)
        bioLabel.font = .systemFont(ofSize: 13, weight: .regular)
        bioLabel.textColor = AppTheme.ink
        bioLabel.numberOfLines = 2
        followButton.setTitle("Follow", for: .normal)
        followButton.setTitleColor(.white, for: .normal)
        followButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        followButton.backgroundColor = AppTheme.ink
        followButton.layer.cornerRadius = 18
        followButton.addAction(UIAction { [weak self] _ in self?.toggleFollow() }, for: .touchUpInside)
        messageButton.setTitle("Message", for: .normal)
        messageButton.setTitleColor(AppTheme.ink, for: .normal)
        messageButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        messageButton.backgroundColor = UIColor(hex: 0xD9FF3F)
        messageButton.layer.cornerRadius = 18
        messageButton.addAction(UIAction { [weak self] _ in self?.handleMessage() }, for: .touchUpInside)
        [avatar, nameLabel, handleLabel, bioLabel, followButton, messageButton].forEach { profileCard.addSubview($0) }

        statsStack.axis = .horizontal
        statsStack.spacing = 8
        statsStack.distribution = .fillEqually
        [postsStat, followersStat, followingStat].forEach { statsStack.addArrangedSubview($0) }

        configureTab(postsTabButton, title: "Posts", index: 0)
        configureTab(savedTabButton, title: "Saved", index: 1)
        [postsTabButton, savedTabButton].forEach { profileHeader.addSubview($0) }
        profileHeader.addSubview(profileCard)
        profileHeader.addSubview(statsStack)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 92, right: 0)
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier)
        tableView.estimatedRowHeight = 340
        tableView.rowHeight = UITableView.automaticDimension
        profileHeader.autoresizingMask = [.flexibleWidth]
        profileHeader.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 352)
        tableView.tableHeaderView = profileHeader

        [topBar, navDivider, tableView].forEach { view.addSubview($0) }
        topBar.addSubview(backButton)
        topBar.addSubview(moreButton)
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
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(backButton)
            make.right.equalToSuperview().inset(16)
            make.size.equalTo(36)
        }
        navDivider.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topBar.snp.bottom).offset(-1)
            make.height.equalTo(1)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        profileCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(26)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(177)
        }
        avatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(17)
            make.top.equalToSuperview().offset(17)
            make.size.equalTo(72)
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(13)
            make.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(15)
        }
        handleLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(3)
        }
        bioLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalToSuperview().inset(15)
            make.top.equalTo(handleLabel.snp.bottom).offset(11)
        }
        followButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(17)
            make.bottom.equalToSuperview().inset(17)
            make.width.equalTo(148)
            make.height.equalTo(36)
        }
        messageButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(17)
            make.bottom.equalTo(followButton)
            make.width.equalTo(148)
            make.height.equalTo(36)
        }
        statsStack.snp.makeConstraints { make in
            make.top.equalTo(profileCard.snp.bottom).offset(13)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(66)
        }
        postsTabButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(17)
            make.top.equalTo(statsStack.snp.bottom).offset(19)
            make.width.equalTo(166)
            make.height.equalTo(36)
        }
        savedTabButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(17)
            make.centerY.equalTo(postsTabButton)
            make.width.equalTo(166)
            make.height.equalTo(36)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = tableView.bounds.width
        guard width > 0 else { return }
        // UITableView resets a tableHeaderView's frame during layout. Keep
        // both dimensions explicit; checking width alone leaves the header at
        // height zero on the next pass and lets the first post draw over it.
        let requiredHeight: CGFloat = 352
        if abs(profileHeader.frame.width - width) > 0.5 || abs(profileHeader.frame.height - requiredHeight) > 0.5 {
            profileHeader.frame = CGRect(x: 0, y: 0, width: width, height: requiredHeight)
            tableView.tableHeaderView = profileHeader
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            switch event {
            case .followChanged, .postsUpdated, .postInteracted, .blockListChanged, .profileUpdated:
                self?.refreshData()
            default: break
            }
        }
    }

    override func refreshData() {
        guard let originalAuthor = author,
              let latestAuthor = DataRepository.shared.user(by: originalAuthor.id) else { return }
        author = latestAuthor
        let author = latestAuthor
        let me = AccountManager.shared.currentUser?.id ?? ""
        let isFollowing = FollowManager.shared.isFollowing(followerId: me, followeeId: author.id)
        followButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
        followButton.backgroundColor = isFollowing ? UIColor(hex: 0xE8E9E2) : AppTheme.ink
        followButton.setTitleColor(isFollowing ? AppTheme.ink : .white, for: .normal)
        nameLabel.text = author.nickname
        handleLabel.text = "@\(author.nickname.lowercased().replacingOccurrences(of: " ", with: ""))"
        bioLabel.text = author.bio
        avatar.configure(user: author)
        postsStat.configure(value: "\(ContentManager.shared.postsBy(authorId: author.id).count)", title: "Posts")
        followersStat.configure(value: "\(FollowManager.shared.followers(userId: author.id).count)", title: "Followers")
        followingStat.configure(value: "\(FollowManager.shared.following(userId: author.id).count)", title: "Following")
        posts = selectedTab == 0
            ? ContentManager.shared.postsBy(authorId: author.id)
            : ContentManager.shared.savedPosts(forUserId: author.id)
        updateTabs()
        tableView.reloadData()
    }

    private func configureTab(_ button: UIButton, title: String, index: Int) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        button.layer.cornerRadius = 18
        button.tag = index
        button.addAction(UIAction { [weak self] action in
            guard let button = action.sender as? UIButton else { return }
            self?.selectedTab = button.tag
            self?.updateTabs()
            self?.refreshData()
        }, for: .touchUpInside)
    }

    private func updateTabs() {
        for (button, index) in [(postsTabButton, 0), (savedTabButton, 1)] {
            let selected = selectedTab == index
            button.backgroundColor = selected ? AppTheme.ink : UIColor(hex: 0xE8E6D8)
            button.setTitleColor(selected ? .white : UIColor(hex: 0x7B7E77), for: .normal)
        }
    }

    private func toggleFollow() {
        guard let author, let me = AccountManager.shared.currentUser?.id else { return }
        if FollowManager.shared.isFollowing(followerId: me, followeeId: author.id) {
            FollowManager.shared.unfollow(followerId: me, followeeId: author.id)
        } else {
            FollowManager.shared.follow(followerId: me, followeeId: author.id)
        }
    }

    private func handleMessage() {
        guard let author, let me = AccountManager.shared.currentUser?.id else { return }
        let mutual = FollowManager.shared.isFollowing(followerId: me, followeeId: author.id)
            && FollowManager.shared.isFollowing(followerId: author.id, followeeId: me)
        guard mutual else {
            Toast.show("Connect to Chat: follow each other to start a conversation.")
            return
        }
        let controller = ChatDetailViewController()
        if let conversation = ChatManager.shared.conversationsForCurrentUser().first(where: { $0.participantIds.contains(author.id) }) {
            controller.conversation = conversation
        } else {
            controller.conversation = Conversation(id: "conv-\(author.id)", participantIds: [author.id], lastMessage: nil, unreadCount: 0, isYorvaAI: false, ownerId: me)
            ChatManager.shared.registerConversation(controller.conversation!)
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}

private final class StatCardView: UIView {
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        valueLabel.textColor = AppTheme.ink
        titleLabel.font = .systemFont(ofSize: 10, weight: .regular)
        titleLabel.textColor = UIColor(hex: 0x7B7E77)
        addSubview(valueLabel)
        addSubview(titleLabel)
        valueLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(13)
            make.top.equalToSuperview().offset(12)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(valueLabel)
            make.top.equalTo(valueLabel.snp.bottom).offset(5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
    func configure(value: String, title: String) {
        valueLabel.text = value
        titleLabel.text = title
    }
}

extension AuthorProfileViewController: UITableViewDataSource, UITableViewDelegate, PostCardCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { posts.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier, for: indexPath) as! PostCardCell
        let post = posts[indexPath.row]
        cell.configure(post: post, author: DataRepository.shared.user(by: post.authorId))
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let controller = PostDetailViewController()
        controller.postId = posts[indexPath.row].id
        navigationController?.pushViewController(controller, animated: true)
    }

    private func post(for cell: PostCardCell) -> Post? {
        guard let row = tableView.indexPath(for: cell)?.row, posts.indices.contains(row) else { return nil }
        return posts[row]
    }

    func postCardDidTapAuthor(_ cell: PostCardCell) {}
    func postCardDidTapMore(_ cell: PostCardCell) { if let post = post(for: cell) { MoreMenu.showPostMoreMenu(post: post, from: self) } }
    func postCardDidTapLike(_ cell: PostCardCell) { if let post = post(for: cell) { ContentManager.shared.toggleLike(postId: post.id) } }
    func postCardDidTapComment(_ cell: PostCardCell) {
        guard let post = post(for: cell) else { return }
        let controller = PostDetailViewController()
        controller.postId = post.id
        navigationController?.pushViewController(controller, animated: true)
    }
    func postCardDidTapSave(_ cell: PostCardCell) { if let post = post(for: cell) { ContentManager.shared.toggleSave(postId: post.id) } }
    func postCardDidTapPost(_ cell: PostCardCell) { postCardDidTapComment(cell) }
}
