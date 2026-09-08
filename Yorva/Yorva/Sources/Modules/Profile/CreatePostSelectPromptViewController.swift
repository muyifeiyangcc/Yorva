//
//  CreatePostSelectPromptViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class CreatePostSelectPromptViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }
    override func shouldUseScrollContainer() -> Bool { true }

    private let brandLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressDone = UIView()
    private let progressRemaining = UIView()
    private let sectionLabel = UILabel()
    private let balancePill = UILabel()
    private let helperLabel = UILabel()
    private let promptStack = UIStackView()
    private let chooseFromFiveButton = UIButton(type: .system)
    private let askAIButton = UIButton(type: .system)
    private let bottomBar = UIView()
    private let bottomHintLabel = UILabel()
    private let publishButton = UIButton(type: .system)

    private var prompts: [PromptItem] = []
    private var promptCards: [PromptSelectionCardView] = []
    private var selectedPrompt: PromptItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let hostWidth = (contentView ?? view).bounds.width
        let textWidth = max(0, hostWidth - 34)
        if textWidth > 0, titleLabel.preferredMaxLayoutWidth != textWidth {
            titleLabel.preferredMaxLayoutWidth = textWidth
        }
    }

    override func setupHierarchy() {
        brandLabel.text = "yorva"
        brandLabel.font = .systemFont(ofSize: 21, weight: .bold)
        brandLabel.textColor = AppTheme.ink

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor(hex: 0x777A72), for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 17
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        cancelButton.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = -5
        titleLabel.attributedText = NSAttributedString(string: "Make something\nworth keeping.", attributes: [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: AppTheme.ink,
            .paragraphStyle: paragraph
        ])
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.text = "One prompt, one visual, one honest answer."
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor(hex: 0x7B7E77)

        progressDone.backgroundColor = UIColor(hex: 0x0D110F)
        progressRemaining.backgroundColor = UIColor(hex: 0xE3E4E1)
        [progressDone, progressRemaining].forEach { $0.layer.cornerRadius = 2 }

        sectionLabel.text = "Choose a Prompt"
        sectionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        sectionLabel.textColor = AppTheme.ink
        balancePill.text = "\(CurrencyManager.shared.coins) Coins"
        balancePill.font = .systemFont(ofSize: 12, weight: .semibold)
        balancePill.textColor = AppTheme.ink
        balancePill.textAlignment = .center
        balancePill.backgroundColor = UIColor(hex: 0xD9FF3F)
        balancePill.layer.cornerRadius = 14
        balancePill.clipsToBounds = true

        helperLabel.text = "Choose one of three free prompts to begin."
        helperLabel.font = .systemFont(ofSize: 11, weight: .regular)
        helperLabel.textColor = UIColor(hex: 0x7B7E77)

        promptStack.axis = .vertical
        promptStack.spacing = 10
        promptStack.alignment = .fill

        chooseFromFiveButton.setTitle("Choose from 5 · 300 Coins", for: .normal)
        chooseFromFiveButton.setTitleColor(.white, for: .normal)
        chooseFromFiveButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .regular)
        chooseFromFiveButton.backgroundColor = UIColor(hex: 0x0D110F)
        chooseFromFiveButton.layer.cornerRadius = 16
        chooseFromFiveButton.addAction(UIAction { [weak self] _ in self?.openChooseFrom5() }, for: .touchUpInside)

        askAIButton.setTitle("Ask Yorva AI 〉", for: .normal)
        askAIButton.setTitleColor(UIColor(hex: 0x777A72), for: .normal)
        askAIButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .regular)
        askAIButton.addAction(UIAction { [weak self] _ in
            let ai = YorvaAIViewController()
            self?.navigationController?.pushViewController(ai, animated: true)
        }, for: .touchUpInside)

        bottomBar.backgroundColor = .white
        bottomBar.layer.cornerRadius = 20
        bottomBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        bottomBar.layer.shadowOpacity = 1
        bottomBar.layer.shadowRadius = 14
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: 4)
        bottomHintLabel.text = "Your post will appear in the Yorva feed."
        bottomHintLabel.font = .systemFont(ofSize: 10, weight: .regular)
        bottomHintLabel.textColor = UIColor(hex: 0x7B7E77)
        publishButton.setTitle("Publish", for: .normal)
        publishButton.setTitleColor(AppTheme.ink, for: .normal)
        publishButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        publishButton.backgroundColor = UIColor(hex: 0xD9FF3F)
        publishButton.layer.cornerRadius = 20
        publishButton.addAction(UIAction { [weak self] _ in self?.publishSelection() }, for: .touchUpInside)

        let host = contentView ?? view!
        [brandLabel, cancelButton, titleLabel, subtitleLabel, progressDone, progressRemaining,
         sectionLabel, balancePill, helperLabel, promptStack, chooseFromFiveButton, askAIButton].forEach { host.addSubview($0) }
        [bottomHintLabel, publishButton].forEach { bottomBar.addSubview($0) }
        view.addSubview(bottomBar)
    }

    override func applyAutoLayoutConstraints() {
        let host = contentView ?? view!
        brandLabel.snp.makeConstraints { make in
            make.top.equalTo(host).offset(20)
            make.left.equalToSuperview().offset(19)
            make.height.equalTo(28)
        }
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(host).offset(12)
            make.right.equalToSuperview().inset(19)
            make.width.equalTo(61)
            make.height.equalTo(34)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(brandLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(17)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.left.right.equalTo(titleLabel)
        }
        progressDone.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(17)
            make.left.equalTo(titleLabel)
            make.width.equalTo(168)
            make.height.equalTo(4)
        }
        progressRemaining.snp.makeConstraints { make in
            make.centerY.equalTo(progressDone)
            make.left.equalTo(progressDone.snp.right).offset(7)
            make.right.equalTo(titleLabel)
            make.height.equalTo(4)
        }
        sectionLabel.snp.makeConstraints { make in
            make.top.equalTo(progressDone.snp.bottom).offset(18)
            make.left.equalTo(titleLabel)
        }
        balancePill.snp.makeConstraints { make in
            make.centerY.equalTo(sectionLabel)
            make.right.equalTo(titleLabel)
            make.width.equalTo(69)
            make.height.equalTo(28)
        }
        helperLabel.snp.makeConstraints { make in
            make.top.equalTo(sectionLabel.snp.bottom).offset(14)
            make.left.right.equalTo(titleLabel)
        }
        promptStack.snp.makeConstraints { make in
            make.top.equalTo(helperLabel.snp.bottom).offset(10)
            make.left.right.equalTo(titleLabel)
        }
        chooseFromFiveButton.snp.makeConstraints { make in
            make.top.equalTo(promptStack.snp.bottom).offset(12)
            make.left.equalTo(titleLabel)
            make.width.equalTo(155)
            make.height.equalTo(32)
            make.bottom.equalTo(host).offset(-24)
        }
        askAIButton.snp.makeConstraints { make in
            make.centerY.equalTo(chooseFromFiveButton)
            make.right.equalTo(titleLabel)
            make.height.equalTo(32)
        }

        bottomBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(61)
        }
        bottomHintLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(publishButton.snp.left).offset(-8)
        }
        publishButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(78)
            make.height.equalTo(40)
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            if case .walletUpdated = event { self?.refreshData() }
        }
    }

    override func refreshData() {
        prompts = ContentManager.shared.freePrompts()
        let paidPrompts = ContentManager.shared.paidPrompts()
        let paidCount = paidPrompts.count
        let paidCost = paidPrompts.map(\.costAmount).min() ?? 0
        helperLabel.text = "Choose one of \(prompts.count) free prompts to begin."
        chooseFromFiveButton.setTitle("Choose from \(paidCount) · \(paidCost) Coins", for: .normal)
        balancePill.text = "\(CurrencyManager.shared.coins) Coins"
        promptCards.forEach { $0.removeFromSuperview() }
        promptCards.removeAll()
        promptStack.arrangedSubviews.forEach { promptStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        for prompt in prompts.prefix(3) {
            let card = PromptSelectionCardView()
            card.configure(prompt: prompt)
            card.onTap = { [weak self] prompt in self?.select(prompt: prompt) }
            promptCards.append(card)
            promptStack.addArrangedSubview(card)
            card.snp.makeConstraints { $0.height.equalTo(68) }
        }
        if selectedPrompt == nil || !prompts.contains(where: { $0.id == selectedPrompt?.id }) {
            selectedPrompt = prompts.dropFirst().first ?? prompts.first
        }
        updateSelection()
    }

    private func select(prompt: PromptItem) {
        selectedPrompt = prompt
        updateSelection()
    }

    private func updateSelection() {
        promptCards.forEach { $0.setSelected($0.prompt?.id == selectedPrompt?.id) }
    }

    private func publishSelection() {
        guard let prompt = selectedPrompt else {
            Toast.show("Choose a prompt first")
            return
        }
        pushContent(prompt: prompt)
    }

    private func openChooseFrom5() {
        let paidPrompts = Array(ContentManager.shared.paidPrompts().prefix(5))
        PaidPromptSheetView.show(prompts: paidPrompts) { [weak self] prompt in
            self?.handleUsePaidPrompt(prompt)
        }
    }

    private func handleUsePaidPrompt(_ prompt: PromptItem) {
        guard CurrencyManager.shared.canAfford(amount: prompt.costAmount) else {
            ConfirmDialog.showInsufficientCoins(needed: prompt.costAmount) { [weak self] in
                guard let self else { return }
                let vc = RechargeViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
            return
        }
        ConfirmDialog.show(
            title: "Unlock Prompt",
            message: "Are you sure you want to spend \(prompt.costAmount) Coins to unlock an extra prompt for your post?",
            confirmTitle: "Spend \(prompt.costAmount) Coins",
            cancelTitle: "Cancel"
        ) { [weak self] in
            guard CurrencyManager.shared.spend(amount: prompt.costAmount) else { return }
            self?.pushContent(prompt: prompt)
        }
    }

    private func pushContent(prompt: PromptItem) {
        let controller = CreatePostContentViewController()
        controller.selectedPrompt = prompt
        navigationController?.pushViewController(controller, animated: true)
    }
}

private final class PromptSelectionCardView: UIView {
    private let titleLabel = UILabel()
    private let metadataLabel = UILabel()
    private let tapButton = UIButton(type: .custom)
    private(set) var prompt: PromptItem?
    var onTap: ((PromptItem) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 17
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        backgroundColor = .white
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = AppTheme.ink
        metadataLabel.font = .systemFont(ofSize: 10, weight: .regular)
        metadataLabel.textColor = UIColor(hex: 0x7B7E77)
        [titleLabel, metadataLabel, tapButton].forEach { addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.top.equalToSuperview().offset(13)
        }
        metadataLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
        }
        tapButton.snp.makeConstraints { make in make.edges.equalToSuperview() }
        tapButton.addAction(UIAction { [weak self] _ in
            guard let prompt = self?.prompt else { return }
            self?.onTap?(prompt)
        }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(prompt: PromptItem) {
        self.prompt = prompt
        titleLabel.text = prompt.title
        metadataLabel.text = Self.metadata(for: prompt)
    }

    func setSelected(_ selected: Bool) {
        backgroundColor = selected ? UIColor(hex: 0xD9FF3F) : .white
        layer.borderColor = selected ? UIColor(hex: 0xD9FF3F).cgColor : UIColor(hex: 0xE1E0D9).cgColor
    }

    fileprivate static func metadata(for prompt: PromptItem) -> String {
        if !prompt.metadata.isBlank { return prompt.metadata }
        if let themeId = prompt.themeId, let theme = ContentManager.shared.theme(by: themeId) {
            return prompt.costType == .coins ? "\(theme.title) · \(prompt.costAmount) Coins" : theme.title
        }
        return prompt.costType == .coins ? "\(prompt.costAmount) Coins" : "Free"
    }
}

private final class PaidPromptSheetView: UIView {
    private let backdrop = UIView()
    private let card = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let balanceView = UIView()
    private let balanceCaption = UILabel()
    private let balanceValue = UILabel()
    private let rowsStack = UIStackView()
    private let footerLabel = UILabel()
    private let useButton = UIButton(type: .system)
    private var prompts: [PromptItem] = []
    private var selectedIndex = 0
    private var onUse: ((PromptItem) -> Void)?

    static func show(prompts: [PromptItem], onUse: @escaping (PromptItem) -> Void) {
        guard let host = UIApplication.shared.activeKeyWindow else { return }
        let sheet = PaidPromptSheetView()
        sheet.prompts = prompts
        sheet.onUse = onUse
        host.addSubview(sheet)
        sheet.snp.makeConstraints { $0.edges.equalToSuperview() }
        sheet.configure()
        host.layoutIfNeeded()
        sheet.card.transform = CGAffineTransform(translationX: 0, y: sheet.card.bounds.height + 30)
        sheet.alpha = 0
        UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.3) {
            sheet.alpha = 1
            sheet.card.transform = .identity
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.35)
        addSubview(backdrop)
        backdrop.snp.makeConstraints { $0.edges.equalToSuperview() }
        backdrop.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBackdropTap)))
        addSubview(card)
        card.backgroundColor = UIColor(hex: 0xFAF9F3)
        card.layer.cornerRadius = 25
        card.layer.masksToBounds = true
        card.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-3)
            make.height.equalTo(618).priority(.high)
            make.top.greaterThanOrEqualTo(safeAreaLayoutGuide.snp.top).offset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configure() {
        titleLabel.text = "Choose from \(prompts.count)"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = AppTheme.ink
        subtitleLabel.text = "Unlock one extra prompt for your next post."
        subtitleLabel.font = .systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = UIColor(hex: 0x7B7E77)
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(AppTheme.ink, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .regular)
        closeButton.layer.cornerRadius = 18
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        closeButton.backgroundColor = .white
        closeButton.addAction(UIAction { [weak self] _ in
            self?.dismissSheet(completion: nil)
        }, for: .touchUpInside)

        balanceView.backgroundColor = UIColor(hex: 0xC6F3F2)
        balanceView.layer.cornerRadius = 16
        balanceCaption.text = "Your balance"
        balanceCaption.font = .systemFont(ofSize: 10, weight: .regular)
        balanceCaption.textColor = UIColor(hex: 0x52706D)
        balanceValue.text = "\(CurrencyManager.shared.coins) Coins"
        balanceValue.font = .systemFont(ofSize: 16, weight: .bold)
        balanceValue.textColor = AppTheme.ink
        rowsStack.axis = .vertical
        rowsStack.spacing = 10
        rowsStack.alignment = .fill
        for (index, prompt) in prompts.enumerated() {
            let row = PaidPromptRowView()
            row.configure(prompt: prompt, selected: index == selectedIndex)
            row.onTap = { [weak self] in self?.select(index: index) }
            rowsStack.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(69) }
        }
        let cost = prompts.map(\.costAmount).min() ?? 0
        footerLabel.text = "One prompt · \(cost) Coins"
        footerLabel.font = .systemFont(ofSize: 10, weight: .regular)
        footerLabel.textColor = UIColor(hex: 0x7B7E77)
        useButton.setTitle("Use selected", for: .normal)
        useButton.setTitleColor(AppTheme.ink, for: .normal)
        useButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        useButton.backgroundColor = UIColor(hex: 0xD9FF3F)
        useButton.layer.cornerRadius = 19
        useButton.addAction(UIAction { [weak self] _ in self?.useSelected() }, for: .touchUpInside)

        [titleLabel, subtitleLabel, closeButton, balanceView, rowsStack, footerLabel, useButton].forEach { card.addSubview($0) }
        [balanceCaption, balanceValue].forEach { balanceView.addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(22)
            make.left.equalToSuperview().offset(17)
            make.right.equalTo(closeButton.snp.left).offset(-8)
        }
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(19)
            make.right.equalToSuperview().inset(17)
            make.size.equalTo(36)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalTo(titleLabel)
        }
        balanceView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(49)
        }
        balanceCaption.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }
        balanceValue.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
        }
        rowsStack.snp.makeConstraints { make in
            make.top.equalTo(balanceView.snp.bottom).offset(17)
            make.left.right.equalToSuperview().inset(17)
        }
        footerLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(17)
            make.bottom.equalToSuperview().inset(18)
        }
        useButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(17)
            make.bottom.equalToSuperview().inset(13)
            make.width.equalTo(88)
            make.height.equalTo(39)
        }
        let divider = UIView()
        divider.backgroundColor = UIColor(hex: 0xE1E0D9)
        card.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(17)
            make.bottom.equalTo(useButton.snp.top).offset(-14)
            make.height.equalTo(1)
        }
    }

    private func select(index: Int) {
        selectedIndex = index
        for (index, view) in rowsStack.arrangedSubviews.enumerated() {
            (view as? PaidPromptRowView)?.setSelected(index == selectedIndex)
        }
    }

    private func useSelected() {
        guard prompts.indices.contains(selectedIndex) else { return }
        let prompt = prompts[selectedIndex]
        dismissSheet { [weak self] in self?.onUse?(prompt) }
    }

    @objc private func handleBackdropTap() {
        dismissSheet(completion: nil)
    }

    private func dismissSheet(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.card.transform = CGAffineTransform(translationX: 0, y: self.card.bounds.height + 30)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}

private final class PaidPromptRowView: UIView {
    private let titleLabel = UILabel()
    private let metadataLabel = UILabel()
    private let radio = UIView()
    private let tapButton = UIButton(type: .custom)
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 17
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = AppTheme.ink
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        metadataLabel.font = .systemFont(ofSize: 10, weight: .regular)
        metadataLabel.textColor = UIColor(hex: 0x7B7E77)
        radio.layer.cornerRadius = 10
        radio.layer.borderWidth = 1
        radio.layer.borderColor = UIColor(hex: 0xBFC5B8).cgColor
        [titleLabel, metadataLabel, radio, tapButton].forEach { addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.top.equalToSuperview().offset(13)
            make.right.equalTo(radio.snp.left).offset(-10)
        }
        metadataLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
        }
        radio.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        tapButton.snp.makeConstraints { make in make.edges.equalToSuperview() }
        tapButton.addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(prompt: PromptItem, selected: Bool) {
        titleLabel.text = prompt.title
        metadataLabel.text = PromptSelectionCardView.metadata(for: prompt)
        setSelected(selected)
    }

    func setSelected(_ selected: Bool) {
        radio.backgroundColor = selected ? UIColor(hex: 0xD9FF3F) : .white
        radio.layer.borderColor = selected ? UIColor(hex: 0xD9FF3F).cgColor : UIColor(hex: 0xBFC5B8).cgColor
    }
}
