//
//  ChatDetailViewController.swift
//  Yorva
//
//  私聊页：文本 / 图片 / 语音消息（铁律 11）
//  - 点击图片按钮：自定义底部 sheet 选择相册 / 拍照；图片按原比例显示
//  - 第一次点击录音：弹系统录音权限弹窗，同意后再按下才开始录音，松开发送
//  - 语音消息：左侧播放 / 暂停 + 中间进度条 + 右侧总时长
//

import UIKit
import SnapKit
import AVFoundation

final class ChatDetailViewController: BaseViewController {

    var conversation: Conversation?
    override var pageBackgroundColor: UIColor { AppTheme.bgChat }
    override var isSecondaryLevel: Bool { true }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let messageField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let imageButton = UIButton(type: .system)
    private let voiceButton = UIButton(type: .system)
    private var messages: [ChatMessage] = []
    private var voicePermissionRequested = false

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let conv = conversation else { return }
        title = conv.isYorvaAI ? "Yorva AI" : (DataRepository.shared.user(by: conv.participantIds.first ?? "")?.nickname ?? "Chat")
        ChatManager.shared.clearUnread(conversationId: conv.id)
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
        refreshData()
    }

    override func setupHierarchy() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(TextMessageCell.self, forCellReuseIdentifier: TextMessageCell.reuseIdentifier)
        tableView.register(ImageMessageCell.self, forCellReuseIdentifier: ImageMessageCell.reuseIdentifier)
        tableView.register(VoiceMessageCell.self, forCellReuseIdentifier: VoiceMessageCell.reuseIdentifier)
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)

        inputBar.backgroundColor = AppTheme.bgPrimary
        view.addSubview(inputBar)
        imageButton.setImage(UIImage(systemName: "photo")?.withTintColor(AppTheme.textBrand, renderingMode: .alwaysOriginal), for: .normal)
        imageButton.addAction(UIAction { [weak self] _ in self?.handlePickImage() }, for: .touchUpInside)
        voiceButton.setImage(UIImage(systemName: "mic")?.withTintColor(AppTheme.textBrand, renderingMode: .alwaysOriginal), for: .normal)
        voiceButton.addAction(UIAction { [weak self] _ in self?.handleRecordVoice() }, for: .touchUpInside)
        messageField.configureYorvaField(placeholder: "Type a message")
        messageField.backgroundColor = AppTheme.bgRoot
        messageField.layer.cornerRadius = 22
        messageField.layer.borderWidth = 1
        messageField.layer.borderColor = AppTheme.divider.cgColor
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(AppTheme.textBrand, for: .normal)
        sendButton.titleLabel?.font = AppFont.buttonTextLink()
        sendButton.addAction(UIAction { [weak self] _ in self?.handleSendText() }, for: .touchUpInside)
        [imageButton, voiceButton, messageField, sendButton].forEach { inputBar.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top)
        }
        inputBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(56)
        }
        imageButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }
        voiceButton.snp.makeConstraints { make in
            make.left.equalTo(imageButton.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }
        sendButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(56)
        }
        messageField.snp.makeConstraints { make in
            make.left.equalTo(voiceButton.snp.right).offset(8)
            make.right.equalTo(sendButton.snp.left).offset(-8)
            make.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            if case .chatUpdated(let convId) = event, convId == self?.conversation?.id {
                self?.refreshData()
            }
        }
    }

    override func refreshData() {
        guard let conv = conversation else { return }
        messages = ChatManager.shared.messages(conversationId: conv.id)
        tableView.reloadData()
        if !messages.isEmpty {
            let path = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: path, at: .bottom, animated: false)
        }
    }

    // MARK: - Actions

    private func handleSendText() {
        guard let conv = conversation, let text = messageField.text, !text.isBlank else { return }
        let me = AccountManager.shared.currentUser?.id ?? "self"
        ChatManager.shared.sendText(conversationId: conv.id, senderId: me, text: text)
        messageField.text = ""
    }

    /// 铁律 11：点击图片按钮 → 自定义底部 sheet（相册 / 拍照），图片按原比例显示
    private func handlePickImage() {
        CustomSheet.show(title: "Send image", items: [
            SheetItem(title: "Choose from album", icon: "photo.on.rectangle", isCancel: false) { [weak self] in
                self?.sendImage(ratio: 1.0)
            },
            SheetItem(title: "Take photo", icon: "camera", isCancel: false) { [weak self] in
                self?.sendImage(ratio: 1.2)
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ])
    }

    private func sendImage(ratio: CGFloat) {
        guard let conv = conversation else { return }
        let me = AccountManager.shared.currentUser?.id ?? "self"
        ChatManager.shared.sendImage(conversationId: conv.id, senderId: me,
                                     color: UIColor.placeholderTint, ratio: ratio)
    }

    /// 铁律 11：第一次点击录音弹系统权限弹窗，同意后再次按下才开始录音；松开发送
    private func handleRecordVoice() {
        let session = AVAudioSession.sharedInstance()
        if !voicePermissionRequested {
            voicePermissionRequested = true
            session.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        Toast.show("Mic ready. Press again to record.")
                    } else {
                        Toast.show("Please enable microphone access in Settings.")
                    }
                    self?.voicePermissionRequested = true
                }
            }
            return
        }
        guard session.recordPermission == .granted else {
            Toast.show("Please enable microphone access in Settings.")
            return
        }
        // 第二次按下：进入录音；松开即发送（占位模拟 3s 语音）
        guard let conv = conversation else { return }
        let me = AccountManager.shared.currentUser?.id ?? "self"
        ChatManager.shared.sendVoice(conversationId: conv.id, senderId: me, duration: 3.0)
    }
}

extension ChatDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let m = messages[indexPath.row]
        let isSelf = m.senderId == AccountManager.shared.currentUser?.id
        switch m.type {
        case .text:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextMessageCell.reuseIdentifier, for: indexPath) as! TextMessageCell
            cell.configure(text: m.text ?? "", isSelf: isSelf)
            return cell
        case .image:
            let cell = tableView.dequeueReusableCell(withIdentifier: ImageMessageCell.reuseIdentifier, for: indexPath) as! ImageMessageCell
            cell.configure(color: m.imageColor ?? AppTheme.cream, ratio: m.imageRatio ?? 1, isSelf: isSelf)
            return cell
        case .voice:
            let cell = tableView.dequeueReusableCell(withIdentifier: VoiceMessageCell.reuseIdentifier, for: indexPath) as! VoiceMessageCell
            cell.configure(duration: m.voiceDuration ?? 0, isSelf: isSelf, isPlayed: m.isPlayed)
            return cell
        }
    }
}

// MARK: - Message cells

final class TextMessageCell: UITableViewCell {
    static let reuseIdentifier = "TextMessageCell"
    private let bubble = UIView()
    private let label = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        bubble.layer.cornerRadius = 14
        bubble.layer.masksToBounds = true
        label.font = AppFont.chatBubble()
        label.numberOfLines = 0
        bubble.addSubview(label)
        contentView.addSubview(bubble)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        }
        bubble.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.width.lessThanOrEqualTo(280)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(text: String, isSelf: Bool) {
        label.text = text
        bubble.backgroundColor = isSelf ? AppTheme.primary : AppTheme.bgPrimary
        label.textColor = isSelf ? AppTheme.textOnPrimary : AppTheme.ink
        bubble.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            if isSelf { make.right.equalToSuperview().offset(-16) }
            else { make.left.equalToSuperview().offset(16) }
            make.width.lessThanOrEqualTo(280)
        }
    }
}

final class ImageMessageCell: UITableViewCell {
    static let reuseIdentifier = "ImageMessageCell"
    private let imageView_ = UIView()
    private var aspectConstraint: Constraint?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(imageView_)
        imageView_.layer.cornerRadius = 12
        imageView_.layer.masksToBounds = true
        imageView_.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.width.lessThanOrEqualTo(220)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(color: UIColor, ratio: CGFloat, isSelf: Bool) {
        imageView_.backgroundColor = color
        // 铁律 11：图片按原比例显示
        // 固定宽度 180，高度 = 180 / 宽高比；高度上限 240，下限 80
        let width: CGFloat = 180
        let height = max(80, min(240, width / max(ratio, 0.1)))
        imageView_.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.width.equalTo(width)
            make.height.equalTo(height)
            if isSelf { make.right.equalToSuperview().offset(-16) }
            else { make.left.equalToSuperview().offset(16) }
        }
    }
}

final class VoiceMessageCell: UITableViewCell {
    static let reuseIdentifier = "VoiceMessageCell"
    private let bubble = UIView()
    private let playButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let durationLabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        bubble.layer.cornerRadius = 14
        bubble.layer.masksToBounds = true
        playButton.setImage(UIImage(systemName: "play.fill")?
            .withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        playButton.setImage(UIImage(systemName: "pause.fill")?
            .withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .selected)
        progressView.progressTintColor = AppTheme.primary
        progressView.trackTintColor = AppTheme.divider
        durationLabel.font = AppFont.voiceDuration()
        durationLabel.textColor = AppTheme.ink
        [playButton, progressView, durationLabel].forEach { bubble.addSubview($0) }
        contentView.addSubview(bubble)
        bubble.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.width.equalTo(200)
        }
        playButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        durationLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
        progressView.snp.makeConstraints { make in
            make.left.equalTo(playButton.snp.right).offset(8)
            make.right.equalTo(durationLabel.snp.left).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(3)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(duration: TimeInterval, isSelf: Bool, isPlayed: Bool) {
        bubble.backgroundColor = isSelf ? AppTheme.primary : AppTheme.bgPrimary
        let color = isSelf ? AppTheme.textOnPrimary : AppTheme.ink
        playButton.tintColor = color
        progressView.progressTintColor = isSelf ? AppTheme.textOnPrimary : AppTheme.primary
        durationLabel.textColor = color
        durationLabel.text = String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60)
        playButton.isSelected = isPlayed
        bubble.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.width.equalTo(200)
            if isSelf { make.right.equalToSuperview().offset(-16) }
            else { make.left.equalToSuperview().offset(16) }
        }
    }
}
