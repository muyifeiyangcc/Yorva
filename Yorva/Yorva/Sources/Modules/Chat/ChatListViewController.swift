//
//  ChatListViewController.swift
//  Yorva
//
//  Tab3 Chat：Yorva AI 入口 + Recent 会话列表
//

import UIKit
import SnapKit

final class ChatListViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgRoot }

    private let yorvaAICard = UIView()
    private let aiAvatar = AvatarView()
    private let aiTitle = UILabel()
    private let aiSubtitle = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = LoadingView()
    private var conversations: [Conversation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat"
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    override func setupHierarchy() {
        yorvaAICard.backgroundColor = AppTheme.bgAI
        yorvaAICard.layer.cornerRadius = 16
        yorvaAICard.layer.masksToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(openYorvaAI))
        yorvaAICard.addGestureRecognizer(tap)
        yorvaAICard.isUserInteractionEnabled = true
        aiAvatar.color = AppTheme.olive
        aiAvatar.initials = "AI"
        aiTitle.font = AppFont.cardTitleSemibold()
        aiTitle.textColor = AppTheme.ink
        aiTitle.text = "Ask Yorva"
        aiSubtitle.font = AppFont.bodySecondary()
        aiSubtitle.textColor = AppTheme.textSecondary
        aiSubtitle.text = "Reflect with a quick prompt each day"
        aiSubtitle.numberOfLines = 0
        [aiAvatar, aiTitle, aiSubtitle].forEach { yorvaAICard.addSubview($0) }
        view.addSubview(yorvaAICard)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseIdentifier)
        tableView.estimatedRowHeight = 72
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)
    }

    override func applyAutoLayoutConstraints() {
        yorvaAICard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(80)
        }
        aiAvatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
        aiTitle.snp.makeConstraints { make in
            make.left.equalTo(aiAvatar.snp.right).offset(12)
            make.top.equalToSuperview().offset(12)
            make.right.equalToSuperview().inset(12)
        }
        aiSubtitle.snp.makeConstraints { make in
            make.left.right.equalTo(aiTitle)
            make.top.equalTo(aiTitle.snp.bottom).offset(4)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(yorvaAICard.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    @objc private func openYorvaAI() {
        if AccountManager.shared.isGuest {
            (tabBarController as? MainTabBarController)?.requiresLoginIfNeeded()
            return
        }
        let vc = YorvaAIViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            guard let self = self else { return }
            if case .chatUpdated = event { self.refreshData() }
        }
    }

    override func refreshData() {
        conversations = ChatManager.shared.conversationsForCurrentUser()
        if conversations.isEmpty {
            loadingView.state = .empty(title: "No conversations yet",
                                       subtitle: "Explore people you'd like to chat with.",
                                       actionTitle: nil)
            loadingView.show(in: view)
        } else {
            loadingView.hide()
        }
        tableView.reloadData()
    }
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
        let conv = conversations[indexPath.row]
        if conv.isYorvaAI { openYorvaAI(); return }
        let vc = ChatDetailViewController()
        vc.conversation = conv
        navigationController?.pushViewController(vc, animated: true)
    }
}

final class ConversationCell: UITableViewCell {
    static let reuseIdentifier = "ConversationCell"
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadBadge = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        [avatar, nameLabel, messageLabel, timeLabel, unreadBadge].forEach { contentView.addSubview($0) }
        avatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
        nameLabel.font = AppFont.cardTitle()
        nameLabel.textColor = AppTheme.ink
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(8)
            make.top.equalToSuperview().offset(12)
            make.right.equalTo(unreadBadge.snp.left).offset(-8)
        }
        messageLabel.font = AppFont.caption()
        messageLabel.textColor = AppTheme.stone
        messageLabel.numberOfLines = 1
        messageLabel.snp.makeConstraints { make in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-12)
        }
        timeLabel.font = AppFont.caption()
        timeLabel.textColor = AppTheme.stone
        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
        }
        unreadBadge.font = AppFont.micro()
        unreadBadge.textColor = .white
        unreadBadge.backgroundColor = AppTheme.primary
        unreadBadge.textAlignment = .center
        unreadBadge.layer.cornerRadius = 8
        unreadBadge.layer.masksToBounds = true
        unreadBadge.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(16)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(conversation: Conversation) {
        if conversation.isYorvaAI {
            avatar.color = AppTheme.olive
            avatar.initials = "AI"
            nameLabel.text = "Yorva AI"
        } else if let pid = conversation.participantIds.first,
                  let u = DataRepository.shared.user(by: pid) {
            avatar.configure(user: u)
            nameLabel.text = u.nickname
        } else {
            avatar.initials = "?"
            nameLabel.text = "Unknown"
        }
        if let m = conversation.lastMessage {
            messageLabel.text = m.text ?? (m.type == .image ? "[Image]" : "[Voice]")
            timeLabel.text = m.createdAt.shortHMString()
        } else {
            messageLabel.text = ""
            timeLabel.text = ""
        }
        unreadBadge.isHidden = conversation.unreadCount == 0
        unreadBadge.text = conversation.unreadCount > 0 ? "\(conversation.unreadCount)" : ""
    }
}
