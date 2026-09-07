//
//  PostDetailViewController.swift
//  Yorva
//
//  帖子详情：Prompt、媒体、回答、互动、评论和底部评论输入。
//

import UIKit
import AVFoundation
import AVKit
import SnapKit

final class PostDetailViewController: BaseViewController {

    var postId: String?
    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private let divider = UIView()
    private let detailScrollView = UIScrollView()
    private let contentContainer = UIView()
    private let authorAvatar = AvatarView()
    private let authorNameLabel = UILabel()
    private let timeLabel = UILabel()
    private let followButton = UIButton(type: .system)
    private let promptCard = UIView()
    private let promptGradient = CAGradientLayer()
    private let promptEyebrowLabel = UILabel()
    private let promptLabel = UILabel()
    private let mediaView = UIView()
    private let mediaImageView = UIImageView()
    private let mediaPlaceholder = UIView()
    private let mediaTypeLabel = UILabel()
    private let videoPlayButton = UIImageView()
    private let answerLabel = UILabel()
    private let actionDividerTop = UIView()
    private let actionDividerBottom = UIView()
    private let likeButton = UIButton(type: .custom)
    private let saveButton = UIButton(type: .custom)
    private let commentButton = UIButton(type: .custom)
    private let commentsSectionLabel = UILabel()
    private let commentsStack = UIStackView()
    private let inputBar = UIView()
    private let commentField = UITextField()
    private let sendButton = UIButton(type: .system)

    private var post: Post?
    private var videoThumbnailGenerator: AVAssetImageGenerator?

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
            guard let self, let post = self.post else { return }
            MoreMenu.showPostMoreMenu(post: post, from: self)
        }, for: .touchUpInside)
        divider.backgroundColor = UIColor(hex: 0xE1E0D9)

        detailScrollView.alwaysBounceVertical = true
        detailScrollView.showsVerticalScrollIndicator = false
        detailScrollView.keyboardDismissMode = .interactive
        detailScrollView.addSubview(contentContainer)

        authorNameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        authorNameLabel.textColor = AppTheme.ink
        timeLabel.font = .systemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = UIColor(hex: 0x7B7E77)
        authorAvatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openAuthor)))
        authorAvatar.isUserInteractionEnabled = true
        followButton.setTitle("Follow", for: .normal)
        followButton.setTitleColor(.white, for: .normal)
        followButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        followButton.backgroundColor = AppTheme.ink
        followButton.layer.cornerRadius = 17
        followButton.addAction(UIAction { [weak self] _ in self?.toggleFollow() }, for: .touchUpInside)

        promptCard.layer.cornerRadius = 22
        promptCard.layer.masksToBounds = true
        promptGradient.colors = [UIColor(hex: 0xD9FF3F).cgColor, UIColor(hex: 0xEFFFB1).cgColor]
        promptGradient.startPoint = CGPoint(x: 0, y: 0.5)
        promptGradient.endPoint = CGPoint(x: 1, y: 0.5)
        promptCard.layer.insertSublayer(promptGradient, at: 0)
        promptEyebrowLabel.font = .systemFont(ofSize: 10, weight: .medium)
        promptEyebrowLabel.textColor = UIColor(hex: 0x33362F)
        promptEyebrowLabel.attributedText = NSAttributedString(string: "PROMPT", attributes: [.kern: 1.4])
        promptLabel.font = .systemFont(ofSize: 23, weight: .bold)
        promptLabel.textColor = AppTheme.ink
        promptLabel.numberOfLines = 2
        promptCard.addSubview(promptEyebrowLabel)
        promptCard.addSubview(promptLabel)

        mediaView.layer.cornerRadius = 20
        mediaView.layer.masksToBounds = true
        mediaPlaceholder.backgroundColor = AppTheme.cream
        mediaImageView.contentMode = .scaleAspectFill
        mediaImageView.clipsToBounds = true
        mediaView.isUserInteractionEnabled = true
        mediaView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openMedia)))
        mediaTypeLabel.font = .systemFont(ofSize: 9, weight: .semibold)
        mediaTypeLabel.textColor = UIColor(hex: 0x4B5048)
        mediaTypeLabel.textAlignment = .center
        mediaTypeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.88)
        mediaTypeLabel.layer.cornerRadius = 13
        mediaTypeLabel.layer.masksToBounds = true
        videoPlayButton.image = UIImage(systemName: "play.circle.fill")?
            .withTintColor(.white.withAlphaComponent(0.9), renderingMode: .alwaysOriginal)
        videoPlayButton.contentMode = .scaleAspectFit
        videoPlayButton.isHidden = true
        [mediaPlaceholder, mediaImageView, mediaTypeLabel, videoPlayButton].forEach { mediaView.addSubview($0) }

        answerLabel.font = .systemFont(ofSize: 15, weight: .regular)
        answerLabel.textColor = AppTheme.ink
        answerLabel.numberOfLines = 0
        actionDividerTop.backgroundColor = UIColor(hex: 0xE1E0D9)
        actionDividerBottom.backgroundColor = UIColor(hex: 0xE1E0D9)
        configureAction(button: likeButton, symbol: "heart", selectedColor: UIColor(hex: 0xE4514B))
        configureAction(button: saveButton, symbol: "star", selectedColor: AppTheme.primary)
        configureAction(button: commentButton, symbol: "bubble.left", selectedColor: UIColor(hex: 0x7B7E77))
        likeButton.addAction(UIAction { [weak self] _ in self?.toggleLike() }, for: .touchUpInside)
        saveButton.addAction(UIAction { [weak self] _ in self?.toggleSave() }, for: .touchUpInside)
        // Comment count is informational on the detail action row. The input
        // field below remains the only entry point for adding a comment.
        commentButton.isUserInteractionEnabled = false
        commentsSectionLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        commentsSectionLabel.textColor = AppTheme.ink
        commentsStack.axis = .vertical
        commentsStack.spacing = 0

        [authorAvatar, authorNameLabel, timeLabel, followButton, promptCard, mediaView, answerLabel,
         actionDividerTop, likeButton, saveButton, commentButton, actionDividerBottom,
         commentsSectionLabel, commentsStack].forEach { contentContainer.addSubview($0) }

        inputBar.backgroundColor = .white
        inputBar.layer.cornerRadius = 20
        inputBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        inputBar.layer.shadowOpacity = 1
        inputBar.layer.shadowRadius = 14
        inputBar.layer.shadowOffset = CGSize(width: 0, height: 4)
        commentField.placeholder = "Write a comment..."
        commentField.font = .systemFont(ofSize: 12, weight: .regular)
        commentField.textColor = AppTheme.ink
        commentField.backgroundColor = .white
        commentField.layer.cornerRadius = 17
        commentField.layer.borderWidth = 1
        commentField.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        commentField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        commentField.leftViewMode = .always
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        sendButton.backgroundColor = AppTheme.ink
        sendButton.layer.cornerRadius = 17
        sendButton.addAction(UIAction { [weak self] _ in self?.sendComment() }, for: .touchUpInside)
        [commentField, sendButton].forEach { inputBar.addSubview($0) }
        [topBar, divider, detailScrollView, inputBar].forEach { view.addSubview($0) }
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
        divider.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topBar.snp.bottom).offset(-1)
            make.height.equalTo(1)
        }
        detailScrollView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top)
        }
        contentContainer.snp.makeConstraints { make in
            make.edges.equalTo(detailScrollView.contentLayoutGuide)
            make.width.equalTo(detailScrollView.frameLayoutGuide)
        }
        authorAvatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(17)
            make.top.equalToSuperview().offset(23)
            make.size.equalTo(40)
        }
        authorNameLabel.snp.makeConstraints { make in
            make.left.equalTo(authorAvatar.snp.right).offset(10)
            make.top.equalTo(authorAvatar).offset(2)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(authorNameLabel)
            make.top.equalTo(authorNameLabel.snp.bottom).offset(4)
        }
        followButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(17)
            make.centerY.equalTo(authorAvatar)
            make.width.equalTo(72)
            make.height.equalTo(34)
        }
        promptCard.snp.makeConstraints { make in
            make.top.equalTo(authorAvatar.snp.bottom).offset(14)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(104)
        }
        promptEyebrowLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(17)
        }
        promptLabel.snp.makeConstraints { make in
            make.top.equalTo(promptEyebrowLabel.snp.bottom).offset(10)
            make.left.right.equalTo(promptEyebrowLabel)
        }
        mediaView.snp.makeConstraints { make in
            make.top.equalTo(promptCard.snp.bottom).offset(14)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(mediaView.snp.width).multipliedBy(0.73)
        }
        mediaPlaceholder.snp.makeConstraints { $0.edges.equalToSuperview() }
        mediaImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mediaTypeLabel.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview().inset(12)
            make.width.equalTo(49)
            make.height.equalTo(26)
        }
        videoPlayButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        answerLabel.snp.makeConstraints { make in
            make.top.equalTo(mediaView.snp.bottom).offset(14)
            make.left.right.equalToSuperview().inset(19)
        }
        actionDividerTop.snp.makeConstraints { make in
            make.top.equalTo(answerLabel.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(1)
        }
        let actionStack = UIStackView(arrangedSubviews: [likeButton, saveButton, commentButton])
        actionStack.axis = .horizontal
        actionStack.distribution = .fillEqually
        actionStack.alignment = .center
        contentContainer.addSubview(actionStack)
        actionStack.snp.makeConstraints { make in
            make.top.equalTo(actionDividerTop.snp.bottom)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(50)
        }
        actionDividerBottom.snp.makeConstraints { make in
            make.top.equalTo(actionStack.snp.bottom)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(1)
        }
        commentsSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(actionDividerBottom.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(17)
        }
        commentsStack.snp.makeConstraints { make in
            make.top.equalTo(commentsSectionLabel.snp.bottom).offset(14)
            make.left.right.equalToSuperview().inset(17)
            make.bottom.equalToSuperview().inset(22)
        }
        inputBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(54)
        }
        commentField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
            make.right.equalTo(sendButton.snp.left).offset(-7)
        }
        sendButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(7)
            make.centerY.equalToSuperview()
            make.width.equalTo(54)
            make.height.equalTo(36)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        promptGradient.frame = promptCard.bounds
        promptGradient.cornerRadius = promptCard.layer.cornerRadius
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            switch event {
            case .postInteracted(let id), .commentsUpdated(let id):
                if id == self?.postId { self?.refreshData() }
            case .followChanged, .blockListChanged:
                self?.refreshData()
            default: break
            }
        }
    }

    override func refreshData() {
        guard let id = postId, let value = ContentManager.shared.post(by: id) else {
            // A hidden or blocked post must not remain visible after a cross-page state change.
            if navigationController?.topViewController === self { navigationController?.popViewController(animated: true) }
            return
        }
        post = value
        let author = DataRepository.shared.user(by: value.authorId)
        authorAvatar.configure(user: author)
        authorNameLabel.text = author?.nickname ?? "Unknown"
        timeLabel.text = "@\(author?.nickname.lowercased().replacingOccurrences(of: " ", with: "") ?? "yorva") · \(value.createdAt.timeAgoDisplay())"
        // 自己的帖子：隐藏更多按钮（无举报/拉黑）和关注按钮
        let isOwnPost = value.authorId == AccountManager.shared.currentUser?.id
        moreButton.isHidden = isOwnPost
        followButton.isHidden = isOwnPost
        if !isOwnPost {
            let isFollowing = AccountManager.shared.currentUser.map { FollowManager.shared.isFollowing(followerId: $0.id, followeeId: value.authorId) } ?? false
            followButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
            followButton.backgroundColor = isFollowing ? UIColor(hex: 0xE8E9E2) : AppTheme.ink
            followButton.setTitleColor(isFollowing ? AppTheme.ink : .white, for: .normal)
        }
        if let promptId = value.promptId, let prompt = ContentManager.shared.prompt(by: promptId) {
            promptLabel.text = prompt.title
            promptCard.isHidden = false
            promptCard.snp.updateConstraints { make in make.height.equalTo(104) }
        } else {
            promptLabel.text = ""
            promptCard.isHidden = true
            promptCard.snp.updateConstraints { make in make.height.equalTo(0) }
        }
        configureMedia(value)
        answerLabel.text = value.answer
        likeButton.isSelected = value.isLiked
        saveButton.isSelected = value.isSaved
        let likeTitle = "Like \(value.likeCount)"
        likeButton.setTitle(likeTitle, for: .normal)
        likeButton.setTitle(likeTitle, for: .selected)
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitle("Save", for: .selected)
        let commentTitle = "Comment \(value.commentCount)"
        commentButton.setTitle(commentTitle, for: .normal)
        commentButton.setTitle(commentTitle, for: .selected)
        commentsSectionLabel.text = "Comments (\(value.commentCount))"
        refreshComments()
    }

    private func configureMedia(_ value: Post) {
        videoThumbnailGenerator?.cancelAllCGImageGeneration()
        videoThumbnailGenerator = nil
        mediaImageView.image = nil
        guard let media = value.media else {
            mediaPlaceholder.backgroundColor = AppTheme.cream
            mediaTypeLabel.text = "PHOTO"
            videoPlayButton.isHidden = true
            return
        }
        mediaPlaceholder.backgroundColor = media.placeholderColor
        mediaTypeLabel.text = media.kind == .video ? "VIDEO" : "PHOTO"
        videoPlayButton.isHidden = media.kind != .video
        if let image = media.resolvedImage {
            mediaImageView.image = image
            return
        }
        if let videoURL = media.resolvedVideoURL {
            let asset = AVAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            videoThumbnailGenerator = generator
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { [weak self] _, cgImage, _, _, _ in
                guard let cgImage else { return }
                DispatchQueue.main.async { self?.mediaImageView.image = UIImage(cgImage: cgImage) }
            }
            return
        }
        let assetName: String
        switch value.themeId {
        case "theme-keep": assetName = "Section1"
        case "theme-habits": assetName = "Section"
        case "theme-letgo": assetName = "Section2"
        case "theme-lesstech": assetName = "Section3"
        default: assetName = ""
        }
        mediaImageView.image = assetName.isEmpty ? nil : UIImage(named: assetName)
    }

    @objc private func openMedia() {
        guard let media = post?.media else { return }
        if media.kind == .video, let url = media.resolvedVideoURL {
            let playerController = AVPlayerViewController()
            playerController.player = AVPlayer(url: url)
            playerController.modalPresentationStyle = .fullScreen
            present(playerController, animated: true) {
                playerController.player?.play()
            }
            return
        }
        guard let image = mediaImageView.image else { return }
        let preview = ImagePreviewViewController(image: image)
        preview.modalPresentationStyle = .fullScreen
        present(preview, animated: true)
    }

    private func refreshComments() {
        commentsStack.arrangedSubviews.forEach {
            commentsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard let id = postId else { return }
        let values = ContentManager.shared.comments(postId: id)
        if values.isEmpty {
            let empty = UILabel()
            empty.font = .systemFont(ofSize: 13, weight: .regular)
            empty.textColor = UIColor(hex: 0x7B7E77)
            empty.text = "No comments yet. Be the first."
            empty.numberOfLines = 0
            empty.snp.makeConstraints { $0.height.equalTo(50) }
            commentsStack.addArrangedSubview(empty)
            return
        }
        values.forEach { comment in
            let row = CommentRowView()
            row.configure(comment: comment)
            row.onMore = { [weak self] in
                guard let self else { return }
                MoreMenu.showUserMoreMenu(targetUserId: comment.authorId, from: self)
            }
            commentsStack.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(60) }
        }
    }

    private func toggleLike() {
        guard let id = postId else { return }
        ContentManager.shared.toggleLike(postId: id)
    }

    private func toggleSave() {
        guard let id = postId else { return }
        ContentManager.shared.toggleSave(postId: id)
    }

    private func toggleFollow() {
        guard let authorId = post?.authorId, let me = AccountManager.shared.currentUser?.id else { return }
        if FollowManager.shared.isFollowing(followerId: me, followeeId: authorId) {
            FollowManager.shared.unfollow(followerId: me, followeeId: authorId)
        } else {
            FollowManager.shared.follow(followerId: me, followeeId: authorId)
        }
    }

    private func sendComment() {
        guard let id = postId, let text = commentField.text, !text.isBlank,
              let me = AccountManager.shared.currentUser else { return }
        ContentManager.shared.addComment(postId: id, authorId: me.id, text: text)
        commentField.text = ""
        commentField.resignFirstResponder()
    }

    @objc private func openAuthor() {
        guard let id = post?.authorId, let author = DataRepository.shared.user(by: id) else { return }
        let controller = AuthorProfileViewController()
        controller.author = author
        navigationController?.pushViewController(controller, animated: true)
    }

    private func configureAction(button: UIButton, symbol: String, selectedColor: UIColor) {
        let normalColor = UIColor(hex: 0x7B7E77)
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.setImage(UIImage(systemName: symbol, withConfiguration: symbolConfiguration)?
            .withTintColor(normalColor, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "\(symbol).fill", withConfiguration: symbolConfiguration)?
            .withTintColor(selectedColor, renderingMode: .alwaysOriginal), for: .selected)
        button.setTitleColor(normalColor, for: .normal)
        button.setTitleColor(normalColor, for: .selected)
        button.setTitleColor(normalColor, for: .highlighted)
        button.titleLabel?.font = .systemFont(ofSize: 10, weight: .regular)
        button.tintColor = normalColor
        button.backgroundColor = .clear
        button.adjustsImageWhenHighlighted = false
    }
}

final class CommentRowView: UIView {
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let moreButton = UIButton(type: .system)
    private let bodyLabel = UILabel()
    private let bottomDivider = UIView()

    var onMore: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        nameLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        nameLabel.textColor = AppTheme.ink
        timeLabel.font = .systemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = UIColor(hex: 0x7B7E77)
        moreButton.setTitle("···", for: .normal)
        moreButton.setTitleColor(UIColor(hex: 0x7B7E77), for: .normal)
        moreButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        moreButton.addAction(UIAction { [weak self] _ in self?.onMore?() }, for: .touchUpInside)
        bodyLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bodyLabel.textColor = AppTheme.ink
        bodyLabel.numberOfLines = 0
        bottomDivider.backgroundColor = UIColor(hex: 0xE7E7E0)
        [avatar, nameLabel, timeLabel, moreButton, bodyLabel, bottomDivider].forEach { addSubview($0) }
        avatar.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.size.equalTo(30)
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(8)
            make.top.equalToSuperview().offset(1)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(5)
            make.centerY.equalTo(nameLabel)
        }
        moreButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalTo(nameLabel)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        bodyLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(5)
            make.bottom.equalTo(bottomDivider.snp.top).offset(-13)
        }
        bottomDivider.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(comment: Comment) {
        let author = DataRepository.shared.user(by: comment.authorId)
        avatar.configure(user: author)
        nameLabel.text = author?.nickname ?? "Unknown"
        timeLabel.text = comment.createdAt.timeAgoDisplay()
        bodyLabel.text = comment.text
        // 自己的评论：隐藏右侧更多按钮（无举报/拉黑）
        moreButton.isHidden = comment.authorId == AccountManager.shared.currentUser?.id
    }
}

private final class ImagePreviewViewController: UIViewController {
    private let image: UIImage
    private let imageView = UIImageView()

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        closeButton.layer.cornerRadius = 18
        closeButton.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.right.equalToSuperview().inset(16)
            make.size.equalTo(36)
        }
    }
}
