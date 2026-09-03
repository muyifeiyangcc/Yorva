//
//  YorvaAIViewController.swift
//  Yorva
//
//  Yorva AI 提问：剩余免费次数 + 金币消耗（铁律 6）
//  免费次数用尽自动转入金币消耗流程（5 Coins / 次）
//

import UIKit
import SnapKit

final class YorvaAIViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgAI }
    override var isSecondaryLevel: Bool { true }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let textField = UITextField()
    private let askButton = UIButton(type: .system)
    private let quickButtonsStack = UIStackView()
    private var messages: [ChatMessage] = []

    private let quickQuestions = [
        "How do I make room for less today?",
        "What's a habit worth keeping?",
        "What should I let go of tonight?"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ask Yorva"
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
        view.addSubview(tableView)

        inputBar.backgroundColor = AppTheme.bgPrimary
        view.addSubview(inputBar)
        textField.configureYorvaField(placeholder: "Ask anything")
        textField.backgroundColor = AppTheme.bgRoot
        textField.layer.cornerRadius = 22
        textField.layer.borderWidth = 1
        textField.layer.borderColor = AppTheme.divider.cgColor
        askButton.setTitle("Ask", for: .normal)
        askButton.setTitleColor(AppTheme.textBrand, for: .normal)
        askButton.titleLabel?.font = AppFont.buttonTextLink()
        askButton.addAction(UIAction { [weak self] _ in self?.attemptAsk() }, for: .touchUpInside)

        quickButtonsStack.axis = .horizontal
        quickButtonsStack.spacing = 8
        quickButtonsStack.distribution = .equalSpacing
        for q in quickQuestions {
            let btn = UIButton(type: .system)
            btn.setTitle(q, for: .normal)
            btn.setTitleColor(AppTheme.textSecondary, for: .normal)
            btn.titleLabel?.font = AppFont.caption()
            btn.titleLabel?.numberOfLines = 1
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.addAction(UIAction { [weak self] _ in self?.textField.text = q }, for: .touchUpInside)
            quickButtonsStack.addArrangedSubview(btn)
        }
        [quickButtonsStack, textField, askButton].forEach { inputBar.addSubview($0) }
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
            make.height.equalTo(96)
        }
        quickButtonsStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.left.right.equalToSuperview().inset(8)
            make.height.equalTo(28)
        }
        textField.snp.makeConstraints { make in
            make.top.equalTo(quickButtonsStack.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(12)
            make.height.equalTo(40)
        }
        askButton.snp.makeConstraints { make in
            make.left.equalTo(textField.snp.right).offset(8)
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalTo(textField)
            make.width.equalTo(56)
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            if case .chatUpdated(let cid) = event, cid == "conv-yorva-ai" {
                self?.refreshData()
            }
        }
    }

    override func refreshData() {
        messages = ChatManager.shared.messages(conversationId: "conv-yorva-ai")
        tableView.reloadData()
        if !messages.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: false)
        }
    }

    private func attemptAsk() {
        guard let text = textField.text, !text.isBlank else { return }
        let remaining = ChatManager.shared.yorvaRemainingFree
        if remaining > 0 {
            ChatManager.shared.consumeYorvaFree()
            ChatManager.shared.sendYorvaAIQuestion(text)
            textField.text = ""
            return
        }
        // 免费次数用尽：自动转入金币消耗流程（铁律 6 + 铁律 9）
        let cost = ChatManager.shared.yorvaAICostPerQuestion
        guard CurrencyManager.shared.canAfford(amount: cost) else {
            Toast.show("Not enough coins. Please recharge.")
            return
        }
        ConfirmDialog.show(
            title: "Ask Yorva",
            message: "Each question costs \(cost) Coins. Your balance: \(CurrencyManager.shared.coins).",
            confirmTitle: "Ask for \(cost) Coins",
            cancelTitle: "Cancel") { [weak self] in
                guard let self = self else { return }
                if CurrencyManager.shared.spend(amount: cost) {
                    ChatManager.shared.sendYorvaAIQuestion(text)
                    self.textField.text = ""
                }
            }
    }
}

extension YorvaAIViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let m = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: TextMessageCell.reuseIdentifier, for: indexPath) as! TextMessageCell
        cell.configure(text: m.text ?? "", isSelf: m.senderId != "yorva-ai")
        return cell
    }
}
