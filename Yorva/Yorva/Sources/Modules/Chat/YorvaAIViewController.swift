//
//  YorvaAIViewController.swift
//  Yorva
//
//  Yorva AI chat: three free questions, then ten coins per question.
//

import UIKit
import SnapKit

final class YorvaAIViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgAI }
    override var isSecondaryLevel: Bool { true }

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private let navTitleLabel = UILabel()
    private let topDivider = UIView()

    /// 是否已确认过金币扣费（确认后本次会话内不再重复弹窗，直接发送）
    private var hasConfirmedCoinSpend = false

    private let bannerView = UIView()
    private let bannerImageView = UIImageView(image: UIImage(named: "ai_bg"))
    private let bannerMask = UIView()
    private let bannerEyebrow = UILabel()
    private let bannerTitle = UILabel()
    private let bannerDescription = UILabel()

    private let quotaView = UIView()
    private let quotaCaption = UILabel()
    private let quotaLabel = UILabel()
    private let coinPill = UILabel()
    private let todayContainer = UIView()
    private let todayLabel = UILabel()
    private let todayLeftLine = UIView()
    private let todayRightLine = UIView()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let plusButton = UIButton(type: .system)
    private let textField = UITextField()
    private let askButton = UIButton(type: .system)
    private var messages: [ChatMessage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Yorva AI"
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.topViewController !== self {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }

    override func setupHierarchy() {
        configureTopBar()
        configureBanner()
        configureQuota()
        configureMessages()
        configureInputBar()
        [topBar, bannerView, quotaView, todayContainer, tableView, inputBar].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        topBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(59)
        }
        topDivider.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        bannerView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(18)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(142)
        }
        bannerImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        bannerMask.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(204)
        }
        bannerEyebrow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-4)
        }
        bannerTitle.snp.makeConstraints { make in
            make.top.equalTo(bannerEyebrow.snp.bottom).offset(5)
            make.left.equalTo(bannerEyebrow)
            make.right.equalToSuperview().offset(-8)
        }
        bannerDescription.snp.makeConstraints { make in
            make.top.equalTo(bannerTitle.snp.bottom).offset(4)
            make.left.equalTo(bannerEyebrow)
            make.right.equalToSuperview().offset(-8)
        }

        quotaView.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom).offset(13)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(49)
        }
        quotaCaption.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }
        quotaLabel.snp.makeConstraints { make in make.center.equalToSuperview() }
        coinPill.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(60)
        }

        todayContainer.snp.makeConstraints { make in
            make.top.equalTo(quotaView.snp.bottom).offset(17)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(18)
        }
        todayLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(46)
        }
        todayLeftLine.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.right.equalTo(todayLabel.snp.left).offset(-8)
            make.height.equalTo(1)
        }
        todayRightLine.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.left.equalTo(todayLabel.snp.right).offset(8)
            make.height.equalTo(1)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(todayContainer.snp.bottom).offset(3)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top)
        }
        inputBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(54)
        }
        plusButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(9)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(34)
        }
        plusButton.alpha = 0;
        askButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.width.equalTo(52)
            make.height.equalTo(36)
        }
        textField.snp.makeConstraints { make in
            make.left.equalTo(plusButton.snp.right).offset(8)
            make.right.equalTo(askButton.snp.left).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            switch event {
            case .chatUpdated(let conversationId) where conversationId == "conv-yorva-ai":
                self?.refreshData()
            case .walletUpdated:
                self?.updateQuotaLabel()
            default:
                break
            }
        }
    }

    override func refreshData() {
        messages = ChatManager.shared.messages(conversationId: "conv-yorva-ai")
        updateQuotaLabel()
        tableView.reloadData()
        guard !messages.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.tableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: false)
        }
    }

    private func configureTopBar() {
        topBar.backgroundColor = .clear
        topDivider.backgroundColor = AppTheme.divider
        topBar.addSubview(backButton)
        topBar.addSubview(moreButton)
        topBar.addSubview(navTitleLabel)
        topBar.addSubview(topDivider)
        [backButton, moreButton].forEach {
            $0.backgroundColor = AppTheme.bgPrimary
            $0.layer.cornerRadius = 18
            $0.layer.borderWidth = 1
            $0.layer.borderColor = AppTheme.divider.cgColor
            $0.tintColor = AppTheme.ink
        }
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        backButton.addAction(UIAction { [weak self] _ in self?.handleBackTapped() }, for: .touchUpInside)
        navTitleLabel.attributedText = trackedTitle("YORVA AI", tracking: 2.0, font: AppFont.navTitle())
        navTitleLabel.textColor = AppTheme.textSecondary
        navTitleLabel.font = AppFont.navTitle()
        navTitleLabel.textAlignment = .center
        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(6)
            make.width.height.equalTo(36)
        }
        moreButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(backButton)
            make.width.height.equalTo(36)
        }
        moreButton.alpha = 0;
        navTitleLabel.snp.makeConstraints { make in make.center.equalToSuperview() }
    }

    private func configureBanner() {
        bannerView.backgroundColor = .white
        bannerView.layer.cornerRadius = 22
        bannerView.layer.masksToBounds = true
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        bannerMask.backgroundColor = .white
        bannerView.addSubview(bannerImageView)
        bannerView.addSubview(bannerMask)
        bannerView.addSubview(bannerEyebrow)
        bannerView.addSubview(bannerTitle)
        bannerView.addSubview(bannerDescription)
        bannerEyebrow.attributedText = trackedTitle("A LITTLE CLARITY, ON DEMAND", tracking: 0.7)
        bannerEyebrow.textColor = AppTheme.olive
        bannerEyebrow.font = AppFont.micro()
        bannerTitle.text = "Ask Yorva."
        bannerTitle.textColor = AppTheme.ink
        bannerTitle.font = .systemFont(ofSize: 27, weight: .semibold)
        bannerDescription.text = "Find a gentler question, shape a prompt, or make space for what matters."
        bannerDescription.textColor = AppTheme.textSecondary
        bannerDescription.font = .systemFont(ofSize: 11, weight: .regular)
        bannerDescription.numberOfLines = 3
    }

    private func configureQuota() {
        quotaView.backgroundColor = AppTheme.bgPrimary
        quotaView.layer.cornerRadius = 16
        quotaView.layer.borderWidth = 1
        quotaView.layer.borderColor = AppTheme.divider.cgColor
        quotaView.addSubview(quotaCaption)
        quotaView.addSubview(quotaLabel)
        quotaView.addSubview(coinPill)
        quotaCaption.text = "Free questions left"
        quotaCaption.textColor = AppTheme.textTertiary
        quotaCaption.font = AppFont.caption()
        quotaLabel.textColor = AppTheme.ink
        quotaLabel.font = AppFont.captionStrong()
        quotaLabel.textAlignment = .center
        coinPill.backgroundColor = AppTheme.bgAI
        coinPill.layer.cornerRadius = 14
        coinPill.text = "10 Coins"
        coinPill.textColor = AppTheme.textSecondary
        coinPill.font = .systemFont(ofSize: 10, weight: .medium)
        coinPill.textAlignment = .center
    }

    private func configureMessages() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        tableView.register(YorvaAIMessageCell.self, forCellReuseIdentifier: YorvaAIMessageCell.reuseIdentifier)
        todayContainer.addSubview(todayLeftLine)
        todayContainer.addSubview(todayLabel)
        todayContainer.addSubview(todayRightLine)
        todayLeftLine.backgroundColor = AppTheme.divider
        todayRightLine.backgroundColor = AppTheme.divider
        todayLabel.text = "TODAY"
        todayLabel.textColor = AppTheme.textTertiary
        todayLabel.font = AppFont.micro()
        todayLabel.textAlignment = .center
    }

    private func configureInputBar() {
        inputBar.backgroundColor = AppTheme.bgPrimary
        inputBar.layer.cornerRadius = 27
        inputBar.applyShadow(opacity: 0.08, radius: 12, offset: CGSize(width: 0, height: 3))
        plusButton.backgroundColor = AppTheme.bgPrimary
        plusButton.layer.cornerRadius = 17
        plusButton.layer.borderWidth = 1
        plusButton.layer.borderColor = AppTheme.divider.cgColor
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.tintColor = AppTheme.textSecondary
        textField.configureYorvaField(placeholder: "Write a message...")
        textField.backgroundColor = AppTheme.bgPrimary
        textField.layer.cornerRadius = 18
        textField.layer.borderWidth = 1
        textField.layer.borderColor = AppTheme.divider.cgColor
        textField.font = .systemFont(ofSize: 12, weight: .regular)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        askButton.setTitle("Send", for: .normal)
        askButton.setTitleColor(.white, for: .normal)
        askButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        askButton.backgroundColor = AppTheme.ink
        askButton.layer.cornerRadius = 17
        askButton.addAction(UIAction { [weak self] _ in self?.attemptAsk() }, for: .touchUpInside)
        [plusButton, textField, askButton].forEach { inputBar.addSubview($0) }
    }

    private func updateQuotaLabel() {
        quotaLabel.text = "\(ChatManager.shared.yorvaRemainingFree) / \(ChatManager.shared.yorvaAIFreeQuota)"
    }

    private func attemptAsk() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        let remaining = ChatManager.shared.yorvaRemainingFree
        if remaining > 0 {
            ChatManager.shared.consumeYorvaFree()
            ChatManager.shared.sendYorvaAIQuestion(text)
            textField.text = ""
            return
        }
        let cost = ChatManager.shared.yorvaAICostPerQuestion
        guard CurrencyManager.shared.canAfford(amount: cost) else {
            ConfirmDialog.showInsufficientCoins(needed: cost) { [weak self] in
                guard let self else { return }
                let vc = RechargeViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
            return
        }
        // 已确认过金币扣费 → 直接发送，不再弹窗
        if hasConfirmedCoinSpend {
            if CurrencyManager.shared.spend(amount: cost) {
                ChatManager.shared.sendYorvaAIQuestion(text)
                textField.text = ""
            }
            return
        }
        ConfirmDialog.show(
            title: "Ask Yorva",
            message: "Each question costs \(cost) Coins. Your balance: \(CurrencyManager.shared.coins).",
            confirmTitle: "Ask for \(cost) Coins",
            cancelTitle: "Cancel") { [weak self] in
                guard let self else { return }
                if CurrencyManager.shared.spend(amount: cost) {
                    self.hasConfirmedCoinSpend = true
                    ChatManager.shared.sendYorvaAIQuestion(text)
                    self.textField.text = ""
                }
            }
    }

    private func trackedTitle(_ text: String, tracking: CGFloat, font: UIFont = AppFont.micro()) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.kern: tracking, .font: font])
    }
}

extension YorvaAIViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: YorvaAIMessageCell.reuseIdentifier, for: indexPath) as! YorvaAIMessageCell
        cell.configure(text: message.text ?? "", isSelf: message.senderId != "yorva-ai", createdAt: message.createdAt)
        return cell
    }
}

private final class YorvaAIMessageCell: UITableViewCell {
    static let reuseIdentifier = "YorvaAIMessageCell"
    private let bubble = UIView()
    private let stack = UIStackView()
    private let eyebrowLabel = UILabel()
    private let bodyLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(bubble)
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        bubble.addSubview(stack)
        [eyebrowLabel, bodyLabel, timeLabel].forEach { stack.addArrangedSubview($0) }
        eyebrowLabel.font = AppFont.micro()
        eyebrowLabel.textColor = AppTheme.textTertiary
        eyebrowLabel.text = "YORVA AI"
        bodyLabel.numberOfLines = 0
        bodyLabel.font = .systemFont(ofSize: 13, weight: .regular)
        bodyLabel.textColor = AppTheme.ink
        timeLabel.font = .systemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = AppTheme.textTertiary
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 13, bottom: 11, right: 13))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String, isSelf: Bool, createdAt: Date) {
        bodyLabel.text = text
        eyebrowLabel.isHidden = isSelf
        timeLabel.isHidden = isSelf
        stack.spacing = isSelf ? 0 : 4
        bubble.backgroundColor = isSelf ? UIColor(hex: 0xBDEFF1) : AppTheme.bgPrimary
        bubble.layer.cornerRadius = 14
        bubble.layer.borderWidth = isSelf ? 0 : 1
        bubble.layer.borderColor = AppTheme.divider.cgColor
        timeLabel.text = createdAt.timeAgoDisplay()
        bubble.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            // The reference layout uses one consistent message-card width;
            // keeping it fixed also prevents short replies from collapsing.
            make.width.equalTo(285)
            if isSelf { make.right.equalToSuperview().offset(-17) }
            else { make.left.equalToSuperview().offset(17) }
        }
    }
}
