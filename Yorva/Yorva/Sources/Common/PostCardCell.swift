//
//  PostCardCell.swift
//  Yorva
//
//  帖子卡片 cell（Home / Following / ThemeDetail / Profile 复用）
//  - 原比例媒体展示（铁律 11：图片按原比例显示）
//  - 头像 / 作者 / 时间 / 更多菜单 / Like / Comment / Save 全部对齐设计稿
//

import UIKit
import SnapKit

protocol PostCardCellDelegate: AnyObject {
    func postCardDidTapAuthor(_ cell: PostCardCell)
    func postCardDidTapMore(_ cell: PostCardCell)
    func postCardDidTapLike(_ cell: PostCardCell)
    func postCardDidTapComment(_ cell: PostCardCell)
    func postCardDidTapSave(_ cell: PostCardCell)
    func postCardDidTapPost(_ cell: PostCardCell)
}

final class PostCardCell: UITableViewCell {

    static let reuseIdentifier = "PostCardCell"
    weak var delegate: PostCardCellDelegate?

    private let authorAvatar = AvatarView()
    private let authorNameLabel = UILabel()
    private let timeLabel = UILabel()
    private let moreButton = UIButton(type: .system)
    private let promptTitleLabel = UILabel()
    private let mediaView = UIView()
    private let mediaPlaceholder = UIView()
    private let videoBadge = UIImageView()
    private let answerLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)

    private var mediaAspectRatio: CGFloat = 1.0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        authorAvatar.color = AppTheme.primary
        authorNameLabel.font = AppFont.cardTitle()
        authorNameLabel.textColor = AppTheme.ink
        timeLabel.font = AppFont.caption()
        timeLabel.textColor = AppTheme.stone
        moreButton.setImage(UIImage(systemName: "ellipsis")?
            .withTintColor(AppTheme.stone, renderingMode: .alwaysOriginal), for: .normal)
        moreButton.addAction(UIAction { [weak self] _ in
            self.delegate?.postCardDidTapMore(self)
        }, for: .touchUpInside)

        promptTitleLabel.font = AppFont.cardTitleSemibold()
        promptTitleLabel.textColor = AppTheme.olive
        promptTitleLabel.numberOfLines = 0

        mediaView.backgroundColor = .clear
        mediaPlaceholder.backgroundColor = AppTheme.cream
        mediaPlaceholder.layer.cornerRadius = 12
        mediaPlaceholder.layer.masksToBounds = true
        mediaView.addSubview(mediaPlaceholder)
        videoBadge.image = UIImage(systemName: "play.circle.fill")?
            .withTintColor(.white.withAlphaComponent(0.9), renderingMode: .alwaysOriginal)
        videoBadge.contentMode = .scaleAspectFit
        videoBadge.isHidden = true
        mediaView.addSubview(videoBadge)

        answerLabel.font = AppFont.body()
        answerLabel.textColor = AppTheme.ink
        answerLabel.numberOfLines = 0

        configureIcon(button: likeButton, symbol: "heart")
        likeButton.addAction(UIAction { [weak self] _ in self?.delegate?.postCardDidTapLike(self!) }, for: .touchUpInside)
        configureIcon(button: commentButton, symbol: "bubble.right")
        commentButton.addAction(UIAction { [weak self] _ in self?.delegate?.postCardDidTapComment(self!) }, for: .touchUpInside)
        configureIcon(button: saveButton, symbol: "bookmark")
        saveButton.addAction(UIAction { [weak self] _ in self?.delegate?.postCardDidTapSave(self!) }, for: .touchUpInside)

        let actionStack = UIStackView(arrangedSubviews: [likeButton, commentButton, saveButton])
        actionStack.axis = .horizontal
        actionStack.distribution = .equalSpacing
        actionStack.alignment = .center
        actionStack.isUserInteractionEnabled = false   // 子按钮各自处理

        let cardWrap = UIView()
        cardWrap.backgroundColor = AppTheme.bgPrimary
        cardWrap.layer.cornerRadius = 12
        cardView = cardWrap
        contentView.addSubview(cardWrap)
        [authorAvatar, authorNameLabel, timeLabel, moreButton, promptTitleLabel, mediaView, answerLabel, actionStack].forEach { cardWrap.addSubview($0) }

        cardWrap.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }
        authorAvatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(12)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        authorNameLabel.snp.makeConstraints { make in
            make.left.equalTo(authorAvatar.snp.right).offset(8)
            make.top.equalTo(authorAvatar).offset(2)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(authorNameLabel)
            make.bottom.equalTo(authorAvatar).offset(-2)
        }
        moreButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalTo(authorAvatar)
            make.size.equalTo(28)
        }
        promptTitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.top.equalTo(authorAvatar.snp.bottom).offset(8)
        }
        mediaView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.top.equalTo(promptTitleLabel.snp.bottom).offset(8)
            make.height.equalTo(0)  // 默认无媒体高度 0；configure 时按需 remake
        }
        mediaPlaceholder.snp.makeConstraints { make in make.edges.equalToSuperview() }
        videoBadge.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        answerLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.top.equalTo(mediaView.snp.bottom).offset(8)
        }
        actionStack.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.top.equalTo(answerLabel.snp.bottom).offset(8)
            make.height.equalTo(36)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    private var cardView: UIView!

    private func configureIcon(button: UIButton, symbol: String) {
        button.setImage(UIImage(systemName: symbol)?
            .withTintColor(AppTheme.stone, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "\(symbol).fill")?
            .withTintColor(AppTheme.primary, renderingMode: .alwaysOriginal), for: .selected)
        button.tintColor = AppTheme.stone
    }

    func configure(post: Post, author: User?) {
        authorAvatar.configure(user: author)
        authorNameLabel.text = author?.nickname ?? "Unknown"
        timeLabel.text = post.createdAt.timeAgoDisplay()
        if let promptId = post.promptId, let prompt = ContentManager.shared.prompt(by: promptId) {
            promptTitleLabel.text = prompt.title
        } else if let themeId = post.themeId, let theme = ContentManager.shared.theme(by: themeId) {
            promptTitleLabel.text = theme.title
        } else {
            promptTitleLabel.text = "Untitled prompt"
        }
        if let media = post.media {
            mediaAspectRatio = max(0.1, media.aspectRatio)
            mediaPlaceholder.backgroundColor = media.placeholderColor
            videoBadge.isHidden = media.kind != .video
            // 按原比例自适应高度（铁律 11：图片按原比例显示）
            mediaView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(12)
                make.top.equalTo(promptTitleLabel.snp.bottom).offset(8)
                make.height.equalTo(mediaView.snp.width).dividedBy(mediaAspectRatio)
            }
        } else {
            mediaView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(12)
                make.top.equalTo(promptTitleLabel.snp.bottom).offset(8)
                make.height.equalTo(0)
            }
            videoBadge.isHidden = true
        }
        answerLabel.text = post.answer
        likeButton.isSelected = post.isLiked
        saveButton.isSelected = post.isSaved
        likeButton.setTitle("  \(post.likeCount)", for: .normal)
        likeButton.setTitleColor(AppTheme.stone, for: .normal)
        likeButton.titleLabel?.font = AppFont.caption()
        commentButton.setTitle("  \(post.commentCount)", for: .normal)
        commentButton.setTitleColor(AppTheme.stone, for: .normal)
        commentButton.titleLabel?.font = AppFont.caption()
    }
}
