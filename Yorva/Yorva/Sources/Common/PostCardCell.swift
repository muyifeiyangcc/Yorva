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
import AVFoundation

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
    private let mediaImageView = UIImageView()
    private let videoBadge = UIImageView()
    private let answerLabel = UILabel()
    private let likeButton = UIButton(type: .custom)
    private let commentButton = UIButton(type: .custom)
    private let saveButton = UIButton(type: .custom)

    private var mediaAspectRatio: CGFloat = 1.0
    private var thumbnailGenerator: AVAssetImageGenerator?
    private var thumbnailToken: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailGenerator?.cancelAllCGImageGeneration()
        thumbnailGenerator = nil
        thumbnailToken = nil
        mediaImageView.image = nil
        mediaImageView.isHidden = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        authorAvatar.color = AppTheme.primary
        authorNameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        authorNameLabel.textColor = AppTheme.ink
        timeLabel.font = .systemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = AppTheme.stone
        moreButton.setImage(UIImage(systemName: "ellipsis")?
            .withTintColor(AppTheme.stone, renderingMode: .alwaysOriginal), for: .normal)
        moreButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.delegate?.postCardDidTapMore(self)
        }, for: .touchUpInside)

        promptTitleLabel.font = .systemFont(ofSize: 22, weight: .regular)
        promptTitleLabel.textColor = AppTheme.ink
        promptTitleLabel.numberOfLines = 0

        mediaView.backgroundColor = .clear
        mediaPlaceholder.backgroundColor = AppTheme.cream
        mediaPlaceholder.layer.cornerRadius = 0
        mediaPlaceholder.layer.masksToBounds = true
        mediaView.addSubview(mediaPlaceholder)
        mediaImageView.contentMode = .scaleAspectFill
        mediaImageView.clipsToBounds = true
        mediaImageView.isHidden = true
        mediaView.addSubview(mediaImageView)
        videoBadge.image = UIImage(systemName: "play.circle.fill")?
            .withTintColor(.white.withAlphaComponent(0.9), renderingMode: .alwaysOriginal)
        videoBadge.contentMode = .scaleAspectFit
        videoBadge.isHidden = true
        mediaView.addSubview(videoBadge)

        answerLabel.font = AppFont.body()
        answerLabel.textColor = AppTheme.ink
        answerLabel.numberOfLines = 0

        configureIcon(button: likeButton, symbol: "heart", selectedColor: UIColor(hex: 0xE4514B))
        likeButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.delegate?.postCardDidTapLike(self)
        }, for: .touchUpInside)
        configureIcon(button: commentButton, symbol: "bubble.left", selectedColor: AppTheme.stone)
        commentButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.delegate?.postCardDidTapComment(self)
        }, for: .touchUpInside)
        configureIcon(button: saveButton, symbol: "bookmark", selectedColor: AppTheme.primary)
        saveButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.delegate?.postCardDidTapSave(self)
        }, for: .touchUpInside)

        let actionStack = UIStackView(arrangedSubviews: [likeButton, commentButton, saveButton])
        actionStack.axis = .horizontal
        actionStack.distribution = .equalSpacing
        actionStack.alignment = .center
        actionStack.isUserInteractionEnabled = true

        let cardWrap = UIView()
        cardWrap.backgroundColor = AppTheme.bgPrimary
        cardWrap.layer.cornerRadius = 20
        cardWrap.layer.borderWidth = 1
        cardWrap.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        cardView = cardWrap
        contentView.addSubview(cardWrap)
        [authorAvatar, authorNameLabel, timeLabel, moreButton, promptTitleLabel, mediaView, answerLabel, actionStack].forEach { cardWrap.addSubview($0) }

        cardWrap.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 17, bottom: 8, right: 17))
        }
        authorAvatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            make.size.equalTo(CGSize(width: 34, height: 34))
        }
        authorNameLabel.snp.makeConstraints { make in
            make.left.equalTo(authorAvatar.snp.right).offset(8)
            make.top.equalTo(authorAvatar).offset(1)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(authorNameLabel)
            make.bottom.equalTo(authorAvatar).offset(-1)
        }
        moreButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-14)
            make.centerY.equalTo(authorAvatar)
            make.size.equalTo(28)
        }
        promptTitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(authorAvatar.snp.bottom).offset(14)
        }
        mediaView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(promptTitleLabel.snp.bottom).offset(14)
            make.height.equalTo(0)  // 默认无媒体高度 0；configure 时按需 remake
        }
        mediaPlaceholder.snp.makeConstraints { make in make.edges.equalToSuperview() }
        mediaImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        videoBadge.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        answerLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(mediaView.snp.bottom).offset(14)
        }
        actionStack.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(answerLabel.snp.bottom).offset(10)
            make.height.equalTo(36)
            make.bottom.equalToSuperview().offset(-14)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    private var cardView: UIView!

    private func configureIcon(button: UIButton, symbol: String, selectedColor: UIColor) {
        let normalColor = AppTheme.stone
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.setImage(UIImage(systemName: symbol, withConfiguration: symbolConfiguration)?
            .withTintColor(normalColor, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "\(symbol).fill", withConfiguration: symbolConfiguration)?
            .withTintColor(selectedColor, renderingMode: .alwaysOriginal), for: .selected)
        button.setTitleColor(normalColor, for: .normal)
        button.setTitleColor(normalColor, for: .selected)
        button.setTitleColor(normalColor, for: .highlighted)
        button.tintColor = normalColor
        button.backgroundColor = .clear
        button.adjustsImageWhenHighlighted = false
    }

    func configure(post: Post, author: User?) {
        authorAvatar.configure(user: author)
        authorNameLabel.text = author?.nickname ?? "Unknown"
        timeLabel.text = post.createdAt.timeAgoDisplay()
        // 自己的帖子：隐藏更多按钮（无举报/拉黑）
        let isOwnPost = post.authorId == AccountManager.shared.currentUser?.id
        moreButton.isHidden = isOwnPost
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
            if let resolved = media.resolvedImage {
                // Asset 图片或用户选择的图片
                thumbnailGenerator?.cancelAllCGImageGeneration()
                thumbnailGenerator = nil
                mediaImageView.image = resolved
                mediaImageView.isHidden = false
            } else {
                mediaImageView.image = nil
                mediaImageView.isHidden = true
                // 视频帖：无静态图时从 Bundle / 运行期视频异步取首帧缩略图
                if media.kind == .video, let videoURL = media.resolvedVideoURL {
                    generateVideoThumbnail(for: videoURL)
                }
            }
            // 固定 0.73 比例裁切展示（竖图 scaleAspectFill 裁剪）
            mediaView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(promptTitleLabel.snp.bottom).offset(14)
                make.height.equalTo(mediaView.snp.width).multipliedBy(0.73)
            }
        } else {
            thumbnailGenerator?.cancelAllCGImageGeneration()
            thumbnailGenerator = nil
            mediaView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(promptTitleLabel.snp.bottom).offset(14)
                make.height.equalTo(0)
            }
            videoBadge.isHidden = true
            mediaImageView.image = nil
            mediaImageView.isHidden = true
        }
        answerLabel.text = post.answer
        likeButton.isSelected = post.isLiked
        saveButton.isSelected = post.isSaved
        let likeTitle = "  Like \(post.likeCount)"
        likeButton.setTitle(likeTitle, for: .normal)
        likeButton.setTitle(likeTitle, for: .selected)
        likeButton.titleLabel?.font = AppFont.caption()
        let commentTitle = "  Comment \(post.commentCount)"
        commentButton.setTitle(commentTitle, for: .normal)
        commentButton.setTitle(commentTitle, for: .selected)
        commentButton.titleLabel?.font = AppFont.caption()
        saveButton.setTitle("  Save", for: .normal)
        saveButton.setTitle("  Save", for: .selected)
        saveButton.titleLabel?.font = AppFont.caption()
    }

    /// 视频帖缩略图：取视频首帧；cell 复用后通过 token 丢弃过期回调
    private func generateVideoThumbnail(for videoURL: URL) {
        let token = videoURL.absoluteString
        thumbnailToken = token
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 600, height: 600)
        thumbnailGenerator = generator
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { [weak self] _, cgImage, _, _, _ in
            guard let self, self.thumbnailToken == token, let cgImage else { return }
            DispatchQueue.main.async {
                guard self.thumbnailToken == token else { return }
                self.mediaImageView.image = UIImage(cgImage: cgImage)
                self.mediaImageView.isHidden = false
            }
        }
    }
}
