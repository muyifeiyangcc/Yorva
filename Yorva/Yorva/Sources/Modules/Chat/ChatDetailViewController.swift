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

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let headerAvatar = AvatarView()
    private let headerNameLabel = UILabel()
    private let headerStatusLabel = UILabel()
    private let moreButton = UIButton(type: .system)
    private let navDivider = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let messageField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let imageButton = UIButton(type: .system)
    private let voiceButton = UIButton(type: .system)
    private var messages: [ChatMessage] = []
    private var mediaPicker: MediaPickerCoordinator?
    private var audioRecorder: AVAudioRecorder?
    private var voiceTouchStartedAt: Date?
    private var finishVoiceOnTouchUp = false
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var playingMessageId: String?

    deinit {
        playbackTimer?.invalidate()
        audioPlayer?.stop()
        audioRecorder?.stop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        guard let conv = conversation else { return }
        ChatManager.shared.clearUnread(conversationId: conv.id)
    }

    override func setupHierarchy() {
        topBar.backgroundColor = AppTheme.bgChat
        backButton.setImage(UIImage(systemName: "chevron.backward")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 18
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        backButton.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        headerNameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        headerNameLabel.textColor = AppTheme.ink
        headerStatusLabel.font = .systemFont(ofSize: 10, weight: .regular)
        headerStatusLabel.textColor = UIColor(hex: 0x7B7E77)
        moreButton.setImage(UIImage(systemName: "ellipsis")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        moreButton.backgroundColor = .white
        moreButton.layer.cornerRadius = 18
        moreButton.layer.borderWidth = 1
        moreButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        moreButton.addAction(UIAction { [weak self] _ in
            guard let self,
                  let conv = self.conversation,
                  !conv.isYorvaAI,
                  let me = AccountManager.shared.currentUser?.id,
                  let participantId = conv.participantIds.first(where: { $0 != me && $0 != "yorva-ai" }),
                  !participantId.isEmpty else { return }
            MoreMenu.showUserMoreMenu(targetUserId: participantId, from: self)
        }, for: .touchUpInside)
        navDivider.backgroundColor = UIColor(hex: 0xE1E0D9)
        [backButton, headerAvatar, headerNameLabel, headerStatusLabel, moreButton].forEach { topBar.addSubview($0) }
        view.addSubview(topBar)
        view.addSubview(navDivider)

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

        inputBar.backgroundColor = .white
        inputBar.layer.cornerRadius = 20
        inputBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        inputBar.layer.shadowOpacity = 1
        inputBar.layer.shadowRadius = 14
        inputBar.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.addSubview(inputBar)
        imageButton.backgroundColor = .white
        imageButton.layer.cornerRadius = 17
        imageButton.layer.borderWidth = 1
        imageButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        imageButton.setImage(UIImage(systemName: "plus")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        imageButton.addAction(UIAction { [weak self] _ in self?.handlePickImage() }, for: .touchUpInside)
        voiceButton.backgroundColor = .white
        voiceButton.layer.cornerRadius = 17
        voiceButton.layer.borderWidth = 1
        voiceButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        voiceButton.setImage(UIImage(systemName: "circle.inset.filled")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        // Support both interactions: a longer press records until release;
        // a quick tap starts recording and the next tap finishes it.
        voiceButton.addTarget(self, action: #selector(handleVoiceTouchDown), for: .touchDown)
        voiceButton.addTarget(self, action: #selector(handleVoiceTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        messageField.placeholder = "Write a message..."
        messageField.font = .systemFont(ofSize: 12, weight: .regular)
        messageField.backgroundColor = .white
        messageField.layer.cornerRadius = 18
        messageField.layer.borderWidth = 1
        messageField.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        messageField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        messageField.leftViewMode = .always
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        sendButton.backgroundColor = AppTheme.ink
        sendButton.layer.cornerRadius = 17
        sendButton.addAction(UIAction { [weak self] _ in self?.handleSendText() }, for: .touchUpInside)
        [imageButton, voiceButton, messageField, sendButton].forEach { inputBar.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        topBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(106)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top)
        }
        inputBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(54)
        }
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(6)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(36)
        }
        headerAvatar.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(17)
            make.centerY.equalTo(backButton)
            make.size.equalTo(36)
        }
        headerNameLabel.snp.makeConstraints { make in
            make.left.equalTo(headerAvatar.snp.right).offset(8)
            make.top.equalTo(headerAvatar).offset(2)
        }
        headerStatusLabel.snp.makeConstraints { make in
            make.left.equalTo(headerNameLabel)
            make.top.equalTo(headerNameLabel.snp.bottom).offset(3)
        }
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(backButton)
            make.right.equalToSuperview().inset(16)
            make.size.equalTo(36)
        }
        navDivider.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(-1)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        imageButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(34)
        }
        voiceButton.snp.makeConstraints { make in
            make.left.equalTo(imageButton.snp.right).offset(7)
            make.centerY.equalToSuperview()
            make.size.equalTo(34)
        }
        sendButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-7)
            make.centerY.equalToSuperview()
            make.width.equalTo(54)
            make.height.equalTo(36)
        }
        messageField.snp.makeConstraints { make in
            make.left.equalTo(voiceButton.snp.right).offset(7)
            make.right.equalTo(sendButton.snp.left).offset(-8)
            make.height.equalTo(36)
            make.centerY.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            switch event {
            case .chatUpdated(let convId) where convId == self?.conversation?.id:
                self?.refreshData()
            case .followChanged, .profileUpdated, .blockListChanged:
                self?.refreshData()
            default:
                break
            }
        }
    }

    override func refreshData() {
        guard let conv = conversation else { return }
        moreButton.isHidden = conv.isYorvaAI
        if conv.isYorvaAI {
            headerAvatar.color = AppTheme.primary
            headerAvatar.initials = "AI"
            headerNameLabel.text = "Yorva AI"
            headerStatusLabel.text = "Online"
        } else if let id = conv.participantIds.first, let user = DataRepository.shared.user(by: id) {
            headerAvatar.configure(user: user)
            headerNameLabel.text = user.nickname
            let me = AccountManager.shared.currentUser?.id ?? ""
            headerStatusLabel.text = FollowManager.shared.isFollowing(followerId: me, followeeId: id) ? "Following" : "Not following"
        }
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
                self?.presentImagePicker(source: .photoLibrary)
            },
            SheetItem(title: "Take photo", icon: "camera", isCancel: false) { [weak self] in
                self?.presentImagePicker(source: .camera)
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ])
    }

    private func presentImagePicker(source: MediaPickerCoordinator.Source) {
        mediaPicker = MediaPickerCoordinator(presenter: self, allowsVideo: false) { [weak self] selection in
            guard let self = self, let selection = selection, let image = selection.image else { return }
            self.sendImage(image: image, ratio: selection.aspectRatio)
        }
        mediaPicker?.present(source: source)
    }

    private func sendImage(image: UIImage, ratio: CGFloat) {
        guard let conv = conversation else { return }
        let me = AccountManager.shared.currentUser?.id ?? "self"
        ChatManager.shared.sendImage(conversationId: conv.id, senderId: me,
                                     color: .clear, ratio: ratio, image: image)
    }

    /// 按住录音并松开发送；快速点击时，第一次点击开始、第二次点击结束。
    @objc private func handleVoiceTouchDown() {
        voiceTouchStartedAt = Date()
        if audioRecorder != nil {
            finishVoiceOnTouchUp = true
            return
        }
        finishVoiceOnTouchUp = false
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            startRecording()
        case .undetermined:
            session.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startRecording()
                    } else {
                        Toast.show("Please enable microphone access in Settings.")
                        self?.resetVoiceButtonAppearance()
                    }
                }
            }
        case .denied:
            Toast.show("Please enable microphone access in Settings.")
        @unknown default:
            Toast.show("Microphone access is unavailable.")
        }
    }

    @objc private func handleVoiceTouchUp() {
        let elapsed = voiceTouchStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        defer {
            voiceTouchStartedAt = nil
            finishVoiceOnTouchUp = false
        }
        guard audioRecorder != nil else { return }
        // A short tap is treated as “start”; the next tap will finish it.
        if finishVoiceOnTouchUp || elapsed >= 0.35 {
            finishRecording()
        } else {
            Toast.show("Recording… tap again to finish.")
        }
    }

    private func startRecording() {
        guard audioRecorder == nil else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("yorva-voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            guard recorder.record() else { throw NSError(domain: "YorvaAudio", code: 1) }
            audioRecorder = recorder
            voiceButton.backgroundColor = UIColor(hex: 0xD9FF3F)
        } catch {
            audioRecorder = nil
            resetVoiceButtonAppearance()
            Toast.show("Unable to start recording.")
        }
    }

    private func finishRecording() {
        guard let recorder = audioRecorder else { return }
        let duration = recorder.currentTime
        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        resetVoiceButtonAppearance()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        guard let conv = conversation else { return }
        let me = AccountManager.shared.currentUser?.id ?? "self"
        // Keep even a very short valid recording and display at least one
        // second, instead of silently deleting it before it reaches the chat.
        ChatManager.shared.sendVoice(conversationId: conv.id, senderId: me,
                                     duration: max(1, duration),
                                     audioURL: FileManager.default.fileExists(atPath: url.path) ? url : nil)
        refreshData()
    }

    private func resetVoiceButtonAppearance() {
        voiceButton.backgroundColor = .white
    }

    private func togglePlayback(messageId: String) {
        guard let message = messages.first(where: { $0.id == messageId }), let url = message.voiceURL else {
            Toast.show("Voice message unavailable.")
            return
        }
        if playingMessageId == messageId, let player = audioPlayer, player.isPlaying {
            player.pause()
            updateVisibleVoiceCell(progress: Float(player.currentTime / max(player.duration, 0.1)), isPlaying: false)
            return
        }
        stopPlayback()
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            guard player.play() else { throw NSError(domain: "YorvaAudio", code: 2) }
            audioPlayer = player
            playingMessageId = messageId
            ChatManager.shared.markPlayed(messageId: messageId, played: true)
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updatePlaybackProgress()
            }
            updateVisibleVoiceCell(progress: 0, isPlaying: true)
        } catch {
            Toast.show("Unable to play voice message.")
        }
    }

    private func updatePlaybackProgress() {
        guard let player = audioPlayer, player.duration > 0 else { return }
        updateVisibleVoiceCell(progress: Float(player.currentTime / player.duration), isPlaying: player.isPlaying)
    }

    private func updateVisibleVoiceCell(progress: Float, isPlaying: Bool) {
        guard let id = playingMessageId,
              let row = messages.firstIndex(where: { $0.id == id }),
              let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? VoiceMessageCell else { return }
        cell.updatePlayback(progress: progress, isPlaying: isPlaying)
    }

    private func stopPlayback() {
        if let id = playingMessageId {
            ChatManager.shared.markPlayed(messageId: id, played: false)
        }
        audioPlayer?.stop()
        audioPlayer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        playingMessageId = nil
    }
}

extension ChatDetailViewController: VoiceMessageCellDelegate {
    func voiceMessageCellDidTapPlay(_ cell: VoiceMessageCell, messageId: String) {
        togglePlayback(messageId: messageId)
    }
}

extension ChatDetailViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let id = playingMessageId {
            ChatManager.shared.markPlayed(messageId: id, played: false)
        }
        playbackTimer?.invalidate()
        playbackTimer = nil
        player.stop()
        audioPlayer = nil
        playingMessageId = nil
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
            cell.configure(image: m.image, color: m.imageColor ?? AppTheme.cream, ratio: m.imageRatio ?? 1, isSelf: isSelf)
            return cell
        case .voice:
            let cell = tableView.dequeueReusableCell(withIdentifier: VoiceMessageCell.reuseIdentifier, for: indexPath) as! VoiceMessageCell
            cell.delegate = self
            cell.configure(messageId: m.id, duration: m.voiceDuration ?? 0, isSelf: isSelf, isPlayed: m.isPlayed)
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
        bubble.backgroundColor = isSelf ? UIColor(hex: 0xBDEFF1) : .white
        label.textColor = AppTheme.ink
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
    private let contentImageView = UIImageView()
    private var aspectConstraint: Constraint?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(imageView_)
        imageView_.layer.cornerRadius = 12
        imageView_.layer.masksToBounds = true
        // 聊天图片保持原始比例完整显示，不能使用 aspectFill 裁切内容。
        contentImageView.contentMode = .scaleAspectFit
        contentImageView.clipsToBounds = true
        imageView_.addSubview(contentImageView)
        contentImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        imageView_.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.width.lessThanOrEqualTo(220)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(image: UIImage?, color: UIColor, ratio: CGFloat, isSelf: Bool) {
        // A real image must not reveal the placeholder tint around its edges.
        imageView_.backgroundColor = image == nil ? color : .clear
        contentImageView.image = image
        contentImageView.isHidden = image == nil
        // 铁律 11：图片按原比例显示
        // Fit the container itself to the source aspect ratio so portrait
        // images do not expose colored side bars.
        let safeRatio = max(ratio, 0.1)
        let maximumWidth: CGFloat = 180
        let maximumHeight: CGFloat = 240
        var width = maximumWidth
        var height = width / safeRatio
        if height > maximumHeight {
            height = maximumHeight
            width = height * safeRatio
        }
        imageView_.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.width.equalTo(width)
            make.height.equalTo(height)
            if isSelf { make.right.equalToSuperview().offset(-16) }
            else { make.left.equalToSuperview().offset(16) }
        }
    }
}

protocol VoiceMessageCellDelegate: AnyObject {
    func voiceMessageCellDidTapPlay(_ cell: VoiceMessageCell, messageId: String)
}

final class VoiceMessageCell: UITableViewCell {
    static let reuseIdentifier = "VoiceMessageCell"
    weak var delegate: VoiceMessageCellDelegate?
    private let bubble = UIView()
    private let playButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let durationLabel = UILabel()
    private var messageId: String?
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
        playButton.addAction(UIAction { [weak self] _ in
            guard let self = self, let messageId = self.messageId else { return }
            self.delegate?.voiceMessageCellDidTapPlay(self, messageId: messageId)
        }, for: .touchUpInside)
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
    func configure(messageId: String, duration: TimeInterval, isSelf: Bool, isPlayed: Bool) {
        self.messageId = messageId
        bubble.backgroundColor = isSelf ? UIColor(hex: 0xBDEFF1) : .white
        let color = AppTheme.ink
        playButton.tintColor = color
        progressView.progressTintColor = AppTheme.ink
        durationLabel.textColor = color
        durationLabel.text = String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60)
        playButton.isSelected = isPlayed
        progressView.progress = 0
        bubble.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.width.equalTo(200)
            if isSelf { make.right.equalToSuperview().offset(-16) }
            else { make.left.equalToSuperview().offset(16) }
        }
    }

    func updatePlayback(progress: Float, isPlaying: Bool) {
        progressView.progress = min(1, max(0, progress))
        playButton.isSelected = isPlaying
    }
}
