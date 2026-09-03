//
//  PostDetailViewController.swift
//  Yorva
//
//  帖子详情（铁律 5 / 6 / 13）
//  - 顶部返回 + 更多菜单；展示作者、Prompt、媒体、正文、互动计数
//  - 评论区滚动列表 + 底部输入框
//  - 点赞 / 收藏 / 关注为幂等操作
//  - 更多菜单：Report 仅本地记录、Block 二次确认后全局过滤
//

import UIKit
import SnapKit

final class PostDetailViewController: BaseViewController {

    var postId: String?
    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let scrollView = UIScrollView()
    private let contentContainer = UIView()
    private let authorAvatar = AvatarView()
    private let authorNameLabel = UILabel()
    private let timeLabel = UILabel()
    private let moreButton = UIButton(type: .system)
    private let promptLabel = UILabel()
    private let mediaView = UIView()
    private let answerLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let commentsSectionLabel = UILabel()
    private let commentsStack = UIStackView()
    private let inputBar = UIView()
    private let commentField = UITextField()
    private let sendButton = UIButton(type: .system)

    private var post: Post?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Post"
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
        refreshData()
    }

    override func setupHierarchy() {
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentContainer)
        moreButton.setImage(UIImage(systemName: "ellipsis")?.withTintColor(AppTheme.stone, renderingMode: .alwaysOriginal), for: .normal)
        moreButton.addAction(UIAction { [weak self] _ in
            guard let post = self?.post else { return }
            MoreMenu.showPostMoreMenu(post: post, from: self!)
        }, for: .touchUpInside)

        authorAvatar.color = AppTheme.primary
        authorNameLabel.font = AppFont.cardTitle()
        authorNameLabel.textColor = AppTheme.ink
        let authorTap = UITapGestureRecognizer(target: self, action: #selector(openAuthor))
        authorAvatar.addGestureRecognizer(authorTap)
        authorAvatar.isUserInteractionEnabled = true
        authorNameLabel.isUserInteractionEnabled = true
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(openAuthor))
        authorNameLabel.addGestureRecognizer(nameTap)
        timeLabel.font = AppFont.caption()
        timeLabel.textColor = AppTheme.stone
        promptLabel.font = AppFont.cardTitleSemibold()
        promptLabel.textColor = AppTheme.olive
        promptLabel.numberOfLines = 0
        mediaView.layer.cornerRadius = 12
        mediaView.layer.masksToBounds = true
        answerLabel.font = AppFont.body()
        answerLabel.textColor = AppTheme.ink
        answerLabel.numberOfLines = 0
        configureIcon(button: likeButton, symbol: "heart")
        likeButton.addAction(UIAction { [weak self] _ in self?.toggleLike() }, for: .touchUpInside)
        configureIcon(button: saveButton, symbol: "bookmark")
        saveButton.addAction(UIAction { [weak self] _ in self?.toggleSave() }, for: .touchUpInside)

        commentsSectionLabel.font = AppFont.section()
        commentsSectionLabel.textColor = AppTheme.olive
        commentsSectionLabel.text = "Comments"
        commentsStack.axis = .vertical
        commentsStack.spacing = 8

        [authorAvatar, authorNameLabel, timeLabel, moreButton, promptLabel, mediaView, answerLabel, likeButton, saveButton, commentsSectionLabel, commentsStack].forEach { contentContainer.addSubview($0) }
        view.addSubview(inputBar)
        commentField.configureYorvaField(placeholder: "Add a comment")
        commentField.backgroundColor = AppTheme.bgRoot
        commentField.layer.cornerRadius = 22
        commentField.layer.borderWidth = 1
        commentField.layer.borderColor = AppTheme.divider.cgColor
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(AppTheme.textBrand, for: .normal)
        sendButton.titleLabel?.font = AppFont.buttonTextLink()
        sendButton.addAction(UIAction { [weak self] _ in self?.sendComment() }, for: .touchUpInside)
        [commentField, sendButton].forEach { inputBar.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top)
        }
        contentContainer.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        authorAvatar.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(16)
            make.size.equalTo(40)
        }
        authorNameLabel.snp.makeConstraints { make in
            make.left.equalTo(authorAvatar.snp.right).offset(8)
            make.top.equalTo(authorAvatar)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(authorNameLabel)
            make.bottom.equalTo(authorAvatar)
        }
        moreButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(authorAvatar)
            make.size.equalTo(28)
        }
        promptLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(authorAvatar.snp.bottom).offset(12)
        }
        mediaView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(promptLabel.snp.bottom).offset(8)
            make.height.equalTo(220)
        }
        answerLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(mediaView.snp.bottom).offset(12)
        }
        likeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(answerLabel.snp.bottom).offset(12)
            make.size.equalTo(CGSize(width: 80, height: 36))
        }
        saveButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(likeButton)
            make.size.equalTo(CGSize(width: 80, height: 36))
        }
        commentsSectionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(likeButton.snp.bottom).offset(16)
        }
        commentsStack.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(commentsSectionLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }
        inputBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(56)
        }
        commentField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.right.equalTo(sendButton.snp.left).offset(-8)
            make.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
        sendButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(56)
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            switch event {
            case .postInteracted(let id), .commentsUpdated(let id), .followChanged, .blockListChanged:
                if id == self?.postId { self?.refreshData() }
            default: break
            }
        }
    }

    override func refreshData() {
        guard let id = postId, let p = ContentManager.shared.post(by: id) else { return }
        post = p
        if p.isVisible == false {
            // 帖子已被作者删除
            answerLabel.text = "This post is no longer available."
            return
        }
        let author = DataRepository.shared.user(by: p.authorId)
        authorAvatar.configure(user: author)
        authorNameLabel.text = author?.nickname ?? "Unknown"
        timeLabel.text = p.createdAt.timeAgoDisplay()
        if let pid = p.promptId, let prompt = ContentManager.shared.prompt(by: pid) {
            promptLabel.text = prompt.title
        } else {
            promptLabel.text = "Untitled prompt"
        }
        if let media = p.media {
            mediaView.backgroundColor = media.placeholderColor
            mediaView.snp.updateConstraints { make in
                make.height.equalTo(mediaView.snp.width).dividedBy(max(media.aspectRatio, 0.1))
            }
        } else {
            mediaView.backgroundColor = AppTheme.cream
            mediaView.snp.updateConstraints { make in make.height.equalTo(120) }
        }
        answerLabel.text = p.answer
        likeButton.isSelected = p.isLiked
        saveButton.isSelected = p.isSaved
        refreshComments()
    }

    private func refreshComments() {
        commentsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let id = postId else { return }
        let comments = ContentManager.shared.comments(postId: id)
        if comments.isEmpty {
            let empty = UILabel()
            empty.font = AppFont.bodySecondary()
            empty.textColor = AppTheme.textTertiary
            empty.text = "No comments yet. Be the first."
            commentsStack.addArrangedSubview(empty)
            return
        }
        for c in comments {
            let row = CommentRowView()
            row.configure(comment: c)
            commentsStack.addArrangedSubview(row)
        }
    }

    private func toggleLike() {
        guard let id = postId else { return }
        ContentManager.shared.toggleLike(postId: id)
    }

    private func toggleSave() {
        guard let id = postId else { return }
        ContentManager.shared.toggleSave(postId: id)
        Toast.show(post?.isSaved == true ? "Saved" : "Removed from saved")
    }

    private func sendComment() {
        guard let id = postId, let text = commentField.text, !text.isBlank else { return }
        guard let me = AccountManager.shared.currentUser else { return }
        ContentManager.shared.addComment(postId: id, authorId: me.id, text: text)
        commentField.text = ""
        commentField.resignFirstResponder()
    }

    @objc private func openAuthor() {
        guard let p = post, let author = DataRepository.shared.user(by: p.authorId) else { return }
        let vc = AuthorProfileViewController()
        vc.author = author
        navigationController?.pushViewController(vc, animated: true)
    }

    private func configureIcon(button: UIButton, symbol: String) {
        button.setImage(UIImage(systemName: symbol)?
            .withTintColor(AppTheme.stone, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "\(symbol).fill")?
            .withTintColor(AppTheme.primary, renderingMode: .alwaysOriginal), for: .selected)
        button.tintColor = AppTheme.stone
    }
}

final class CommentRowView: UIView {
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let bodyLabel = UILabel()
    private let timeLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(avatar)
        addSubview(nameLabel)
        addSubview(timeLabel)
        addSubview(bodyLabel)
        avatar.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.size.equalTo(28)
        }
        nameLabel.font = AppFont.captionStrong()
        nameLabel.textColor = AppTheme.textSecondary
        timeLabel.font = AppFont.caption()
        timeLabel.textColor = AppTheme.stone
        bodyLabel.font = AppFont.body()
        bodyLabel.textColor = AppTheme.ink
        bodyLabel.numberOfLines = 0
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(8)
            make.top.equalToSuperview()
            make.right.lessThanOrEqualTo(timeLabel.snp.left).offset(-8)
        }
        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        bodyLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(comment: Comment) {
        let author = DataRepository.shared.user(by: comment.authorId)
        avatar.configure(user: author)
        avatar.snp.updateConstraints { make in make.size.equalTo(28) }
        nameLabel.text = author?.nickname ?? "Unknown"
        timeLabel.text = comment.createdAt.timeAgoDisplay()
        bodyLabel.text = comment.text
    }
}
