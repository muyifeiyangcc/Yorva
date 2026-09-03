//
//  AuthorProfileViewController.swift
//  Yorva
//
//  作者资料页（铁律 5）
//  - 头像、昵称、bio；Posts / Saved 切换
//  - 关注、消息按钮；未互相关注时弹「Connect to Chat」
//  - 二级页隐藏 TabBar + 返回
//

import UIKit
import SnapKit

final class AuthorProfileViewController: BaseViewController {

    var author: User?
    override var pageBackgroundColor: UIColor { AppTheme.bgRoot }
    override var isSecondaryLevel: Bool { true }

    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let followButton = PrimaryButton(title: "Follow")
    private let messageButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private let segment = UISegmentedControl(items: ["Posts", "Saved"])
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var posts: [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = author?.nickname ?? "Profile"
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
        refreshData()
    }

    override func setupHierarchy() {
        avatar.configure(user: author)
        nameLabel.font = AppFont.cardTitleSemibold()
        nameLabel.textColor = AppTheme.ink
        nameLabel.text = author?.nickname
        bioLabel.font = AppFont.bodySecondary()
        bioLabel.textColor = AppTheme.textSecondary
        bioLabel.numberOfLines = 0
        bioLabel.text = author?.bio
        followButton.layer.cornerRadius = 18
        followButton.addAction(UIAction { [weak self] _ in self?.toggleFollow() }, for: .touchUpInside)
        messageButton.setTitle("Message", for: .normal)
        messageButton.setTitleColor(AppTheme.textOnPrimary, for: .normal)
        messageButton.titleLabel?.font = AppFont.buttonSecondary()
        messageButton.backgroundColor = AppTheme.olive
        messageButton.layer.cornerRadius = 18
        messageButton.addAction(UIAction { [weak self] _ in self?.handleMessage() }, for: .touchUpInside)
        moreButton.setImage(UIImage(systemName: "ellipsis")?.withTintColor(AppTheme.stone, renderingMode: .alwaysOriginal), for: .normal)
        moreButton.addAction(UIAction { [weak self] _ in
            guard let self = self, let a = self.author else { return }
            MoreMenu.showAuthorMoreMenu(user: a, from: self)
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

        [avatar, nameLabel, bioLabel, followButton, messageButton, moreButton, segment, tableView].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        avatar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(64)
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalTo(avatar).offset(4)
            make.right.equalTo(moreButton.snp.left).offset(-8)
        }
        bioLabel.snp.makeConstraints { make in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
        followButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(avatar.snp.bottom).offset(12)
            make.right.equalTo(view.snp.centerX).offset(-6)
            make.height.equalTo(36)
        }
        messageButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.left.equalTo(view.snp.centerX).offset(6)
            make.centerY.height.equalTo(followButton)
        }
        moreButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(avatar)
            make.size.equalTo(28)
        }
        segment.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(followButton.snp.bottom).offset(12)
            make.height.equalTo(32)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segment.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            switch event {
            case .followChanged, .postsUpdated, .postInteracted, .blockListChanged:
                self?.refreshData()
            default: break
            }
        }
    }

    override func refreshData() {
        guard let a = author else { return }
        let me = AccountManager.shared.currentUser?.id ?? ""
        let isFollowing = FollowManager.shared.isFollowing(followerId: me, followeeId: a.id)
        followButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
        followButton.backgroundColor = isFollowing ? AppTheme.cream : AppTheme.primary
        followButton.setTitleColor(isFollowing ? AppTheme.textSecondary : AppTheme.textOnPrimary, for: .normal)
        posts = segment.selectedSegmentIndex == 0
            ? ContentManager.shared.postsBy(authorId: a.id)
            : (a.id == me ? ContentManager.shared.savedPosts() : [])
        tableView.reloadData()
    }

    private func toggleFollow() {
        guard let a = author, let me = AccountManager.shared.currentUser else { return }
        if FollowManager.shared.isFollowing(followerId: me, followeeId: a.id) {
            FollowManager.shared.unfollow(followerId: me, followeeId: a.id)
        } else {
            FollowManager.shared.follow(followerId: me, followeeId: a.id)
        }
    }

    private func handleMessage() {
        guard let a = author, let me = AccountManager.shared.currentUser else { return }
        // 互相关注才能直接进私聊
        let mutual = FollowManager.shared.isFollowing(followerId: me, followeeId: a.id)
            && FollowManager.shared.isFollowing(followerId: a.id, followeeId: me)
        guard mutual else {
            Toast.show("Connect to Chat: follow each other to start a conversation.")
            return
        }
        let vc = ChatDetailViewController()
        // 查找或建立会话
        if let conv = ChatManager.shared.conversationsForCurrentUser().first(where: { c in
            c.participantIds.contains(a.id)
        }) {
            vc.conversation = conv
        } else {
            // 简化：直接展示会话列表（占位）— 此处直接 push 私聊页占位即可
            vc.conversation = Conversation(id: "conv-\(a.id)", participantIds: [a.id],
                                           lastMessage: nil, unreadCount: 0, isYorvaAI: false)
        }
        navigationController?.pushViewController(vc, animated: true)
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
    func postCardDidTapAuthor(_ cell: PostCardCell) {}
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
