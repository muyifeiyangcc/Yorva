//
//  CreatePostSelectPromptViewController.swift
//  Yorva
//
//  发帖-选 Prompt（铁律 6 / 铁律 11 / 铁律 12）
//  - 三个免费 Prompt + Choose from 5 自定义底部 Sheet
//  - 付费 Prompt 显示价格与余额；扣费前弹确认弹窗标明数额
//

import UIKit
import SnapKit

final class CreatePostSelectPromptViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let balanceLabel = UILabel()
    private let sectionLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let chooseFromFiveButton = TextLinkButton(title: "Choose from 5")
    private var prompts: [PromptItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Post"
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
        refreshData()
    }

    override func setupHierarchy() {
        balanceLabel.font = AppFont.coinNumberSmall()
        balanceLabel.textColor = AppTheme.textCoins
        sectionLabel.font = AppFont.section()
        sectionLabel.textColor = AppTheme.olive
        sectionLabel.text = "Today's prompts"
        chooseFromFiveButton.addAction(UIAction { [weak self] _ in self?.openChooseFrom5() }, for: .touchUpInside)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.register(PromptOptionCell.self, forCellReuseIdentifier: PromptOptionCell.reuseIdentifier)
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        [balanceLabel, sectionLabel, tableView, chooseFromFiveButton].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        balanceLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.right.equalToSuperview().offset(-16)
        }
        sectionLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(balanceLabel)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(sectionLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(chooseFromFiveButton.snp.top).offset(-12)
        }
        chooseFromFiveButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            if case .walletUpdated = event { self?.refreshData() }
        }
    }

    override func refreshData() {
        prompts = ContentManager.shared.freePrompts()
        balanceLabel.text = "Balance \(CurrencyManager.shared.coins) Coins"
        tableView.reloadData()
    }

    private func openChooseFrom5() {
        // 自定义底部 Sheet（铁律 12）：显示余额 + 5 个候选 Prompt
        let paid = ContentManager.shared.paidPrompts()
        let items = paid.prefix(5).map { p in
            SheetItem(title: "\(p.title)  ·  \(p.costAmount) Coins", icon: nil, isCancel: false) { [weak self] in
                self?.handleUse(prompt: p)
            }
        }
        CustomSheet.show(title: "Choose from 5  ·  Balance \(CurrencyManager.shared.coins) Coins", items: items + [
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ])
    }

    private func handleUse(prompt: PromptItem) {
        switch prompt.costType {
        case .free:
            pushContent(prompt: prompt)
        case .coins:
            guard CurrencyManager.shared.canAfford(amount: prompt.costAmount) else {
                Toast.show("Not enough coins. Please recharge.")
                return
            }
            ConfirmDialog.show(
                title: "Use \(prompt.title)?",
                message: "This prompt costs \(prompt.costAmount) Coins. Your balance: \(CurrencyManager.shared.coins).",
                confirmTitle: "Use \(prompt.costAmount) Coins",
                cancelTitle: "Cancel") { [weak self] in
                    if CurrencyManager.shared.spend(amount: prompt.costAmount) {
                        Toast.show("Prompt unlocked")
                        self?.pushContent(prompt: prompt)
                    }
                }
        }
    }

    private func pushContent(prompt: PromptItem) {
        let vc = CreatePostContentViewController()
        vc.selectedPrompt = prompt
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension CreatePostSelectPromptViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { prompts.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PromptOptionCell.reuseIdentifier, for: indexPath) as! PromptOptionCell
        cell.configure(prompt: prompts[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleUse(prompt: prompts[indexPath.row])
    }
}

final class PromptOptionCell: UITableViewCell {
    static let reuseIdentifier = "PromptOptionCell"
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        titleLabel.font = AppFont.cardTitle()
        titleLabel.textColor = AppTheme.ink
        titleLabel.numberOfLines = 0
        priceLabel.font = AppFont.coinNumberSmall()
        priceLabel.textColor = AppTheme.textCoins
        [titleLabel, priceLabel].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(priceLabel.snp.left).offset(-8)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        priceLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(prompt: PromptItem) {
        titleLabel.text = prompt.title
        priceLabel.text = prompt.costType == .free ? "Free" : "\(prompt.costAmount)"
    }
}
