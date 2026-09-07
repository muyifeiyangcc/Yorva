//
//  ChatListViewController.swift
//  Yorva
//
//  Tab3：聊天入口、Yorva AI Banner 和 Recent 会话列表。
//

import UIKit
import SnapKit

final class ChatListViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }

    private let brandLabel = UILabel()
    private let profileAvatar = AvatarView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerView = ChatListHeaderView()
    private var conversations: [Conversation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupHierarchy() {
        brandLabel.text = "yorva"
        brandLabel.font = .systemFont(ofSize: 23, weight: .bold)
        brandLabel.textColor = AppTheme.ink
        profileAvatar.configure(user: AccountManager.shared.currentUser)
        profileAvatar.isUserInteractionEnabled = true
        profileAvatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openProfile)))
        headerView.onOpenAI = { [weak self] in self?.openYorvaAI() }
        headerView.onClearUnread = { [weak self] in
            self?.conversations.forEach { ChatManager.shared.clearUnread(conversationId: $0.id) }
            self?.refreshData()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 92, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseIdentifier)
        [brandLabel, profileAvatar, headerView, tableView].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        brandLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.left.equalToSuperview().offset(19)
            make.height.equalTo(34)
        }
        profileAvatar.snp.makeConstraints { make in
            make.centerY.equalTo(brandLabel)
            make.right.equalToSuperview().inset(19)
            make.size.equalTo(34)
        }
        headerView.snp.makeConstraints { make in
            make.top.equalTo(brandLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(296)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            if case .chatUpdated = event { self?.refreshData() }
        }
    }

    override func refreshData() {
        profileAvatar.configure(user: AccountManager.shared.currentUser)
        conversations = ChatManager.shared.conversationsForCurrentUser()
        if conversations.isEmpty {
            // 空会话占位：使用 tableView.backgroundView（由 tableView 管理 frame，
            // 固定居中于列表可视区域，不随内容滚动）
            let empty = EmptyStateView()
            empty.configure(title: "No conversations yet",
                            subtitle: "Explore people you'd like to chat with.",
                            actionTitle: nil,
                            iconName: "bubble.left.and.bubble.right")
            tableView.backgroundView = empty
        } else {
            tableView.backgroundView = nil
        }
        tableView.reloadData()
    }

    private func openYorvaAI() {
        if AccountManager.shared.isGuest {
            (tabBarController as? MainTabBarController)?.requiresLoginIfNeeded()
            return
        }
        let controller = YorvaAIViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

    /// 右上角头像：跳转个人页（Me），与首页行为一致
    @objc private func openProfile() {
        if AccountManager.shared.isGuest {
            (tabBarController as? MainTabBarController)?.requiresLoginIfNeeded()
            return
        }
        (tabBarController as? MainTabBarController)?.switchToTab(3)
    }
}

private final class ChatListHeaderView: UIView {
    var onOpenAI: (() -> Void)?
    var onClearUnread: (() -> Void)?
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let aiImageView = UIImageView()
    private let recentLabel = UILabel()
    private let clearButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = -5
        titleLabel.attributedText = NSAttributedString(string: "Keep in\ntouch.", attributes: [
            .font: UIFont.systemFont(ofSize: 38, weight: .bold),
            .foregroundColor: AppTheme.ink,
            .paragraphStyle: paragraph
        ])
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.text = "Small conversations for the things that matter."
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = UIColor(hex: 0x7B7E77)
        aiImageView.image = UIImage(named: "ai_bg")
        aiImageView.contentMode = .scaleAspectFill

        aiImageView.isUserInteractionEnabled = true
        aiImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openAI)))
        recentLabel.text = "Recent"
        recentLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        recentLabel.textColor = AppTheme.ink
        clearButton.setTitle("Clear unread", for: .normal)
        clearButton.setTitleColor(UIColor(hex: 0x7B7E77), for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .regular)
        [titleLabel, subtitleLabel, aiImageView, recentLabel, clearButton].forEach { addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview().inset(17)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalTo(titleLabel)
        }
        aiImageView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(129)
        }
        recentLabel.snp.makeConstraints { make in
            make.top.equalTo(aiImageView.snp.bottom).offset(10)
            make.left.equalTo(titleLabel)
            make.height.equalTo(30)
            make.bottom.equalToSuperview().inset(8)
        }
        clearButton.snp.makeConstraints { make in
            make.right.equalTo(titleLabel)
            make.centerY.equalTo(recentLabel)
            make.height.equalTo(28)
        }
        clearButton.addAction(UIAction { [weak self] _ in self?.onClearUnread?() }, for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let textWidth = max(0, bounds.width - 34)
        if titleLabel.preferredMaxLayoutWidth != textWidth {
            titleLabel.preferredMaxLayoutWidth = textWidth
            subtitleLabel.preferredMaxLayoutWidth = textWidth
        }
    }

    required init?(coder: NSCoder) { fatalError() }
    @objc private func openAI() { onOpenAI?() }
}

extension ChatListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { conversations.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath) as! ConversationCell
        cell.configure(conversation: conversations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        if conversation.isYorvaAI { openYorvaAI(); return }
        let controller = ChatDetailViewController()
        controller.conversation = conversation
        navigationController?.pushViewController(controller, animated: true)
    }
}

final class ConversationCell: UITableViewCell {
    static let reuseIdentifier = "ConversationCell"
    private let card = UIView()
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadDot = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        [card, avatar, nameLabel, messageLabel, timeLabel, unreadDot].forEach { contentView.addSubview($0) }
        card.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(17)
            make.top.bottom.equalToSuperview().inset(4)
            make.height.equalTo(66)
        }
        avatar.snp.makeConstraints { make in
            make.left.equalTo(card).offset(12)
            make.centerY.equalTo(card)
            make.size.equalTo(42)
        }
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = AppTheme.ink
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(10)
            make.top.equalTo(card).offset(14)
            make.right.lessThanOrEqualTo(timeLabel.snp.left).offset(-8)
        }
        messageLabel.font = .systemFont(ofSize: 11, weight: .regular)
        messageLabel.textColor = UIColor(hex: 0x7B7E77)
        messageLabel.numberOfLines = 1
        messageLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(card).inset(12)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
        timeLabel.font = .systemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = UIColor(hex: 0x7B7E77)
        timeLabel.snp.makeConstraints { make in
            make.right.equalTo(card).inset(12)
            make.top.equalTo(card).offset(14)
        }
        unreadDot.layer.cornerRadius = 5
        unreadDot.snp.makeConstraints { make in
            make.right.equalTo(card).inset(12)
            make.bottom.equalTo(card).inset(13)
            make.size.equalTo(10)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(conversation: Conversation) {
        if conversation.isYorvaAI {
            avatar.color = AppTheme.primary
            avatar.initials = "AI"
            nameLabel.text = "Yorva AI"
        } else if let id = conversation.participantIds.first, let user = DataRepository.shared.user(by: id) {
            avatar.configure(user: user)
            nameLabel.text = user.nickname
        } else {
            avatar.initials = "?"
            nameLabel.text = "Unknown"
        }
        if let message = conversation.lastMessage {
            messageLabel.text = message.text ?? (message.type == .image ? "Photo" : "Voice message")
            timeLabel.text = message.createdAt.shortHMString()
        } else {
            messageLabel.text = ""
            timeLabel.text = ""
        }
        let unread = conversation.unreadCount > 0
        card.backgroundColor = unread ? UIColor(hex: 0xFFFFE8) : .white
        card.layer.borderColor = (unread ? UIColor(hex: 0xD9E85A) : UIColor(hex: 0xE1E0D9)).cgColor
        nameLabel.font = .systemFont(ofSize: 14, weight: unread ? .bold : .semibold)
        messageLabel.font = .systemFont(ofSize: 11, weight: unread ? .semibold : .regular)
        unreadDot.isHidden = !unread
        unreadDot.backgroundColor = UIColor(hex: 0xD9FF3F)
    }
}
