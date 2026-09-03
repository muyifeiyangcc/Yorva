//
//  ExploreViewController.swift
//  Yorva
//
//  Tab2 Explore：四张主题卡 + Prompt library + People to notice
//

import UIKit
import SnapKit

final class ExploreViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgRoot }
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore"
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
    }

    override func setupHierarchy() {
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 220
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ThemeCardCell.self, forCellReuseIdentifier: ThemeCardCell.reuseIdentifier)
        tableView.register(PromptLibraryCell.self, forCellReuseIdentifier: PromptLibraryCell.reuseIdentifier)
        tableView.register(PeopleToNoticeCell.self, forCellReuseIdentifier: PeopleToNoticeCell.reuseIdentifier)
        tableView.register(SectionHeaderCell.self, forCellReuseIdentifier: SectionHeaderCell.reuseIdentifier)
        view.addSubview(tableView)
    }

    override func applyAutoLayoutConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            switch event {
            case .followChanged, .blockListChanged, .postsUpdated:
                self?.tableView.reloadData()
            default: break
            }
        }
    }
}

extension ExploreViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 3 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return ContentManager.shared.themes.count
        case 1: return 1   // Prompt library 横向滚动卡
        case 2: return DataRepository.shared.users.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: SectionHeaderCell.reuseIdentifier) as! SectionHeaderCell
        let titles = ["Browse by theme", "Prompt library", "People to notice"]
        cell.configure(title: titles[section])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 44 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: ThemeCardCell.reuseIdentifier, for: indexPath) as! ThemeCardCell
            cell.configure(theme: ContentManager.shared.themes[indexPath.row])
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: PromptLibraryCell.reuseIdentifier, for: indexPath) as! PromptLibraryCell
            cell.configure(prompts: ContentManager.shared.prompts)
            cell.onUsePrompt = { [weak self] prompt in
                self?.handleUsePrompt(prompt)
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: PeopleToNoticeCell.reuseIdentifier, for: indexPath) as! PeopleToNoticeCell
            let user = DataRepository.shared.users[indexPath.row]
            cell.configure(user: user)
            cell.onFollow = { [weak self] in
                guard let me = AccountManager.shared.currentUser?.id else { return }
                if FollowManager.shared.isFollowing(followerId: me, followeeId: user.id) {
                    FollowManager.shared.unfollow(followerId: me, followeeId: user.id)
                } else {
                    FollowManager.shared.follow(followerId: me, followeeId: user.id)
                }
            }
            return cell
        default: return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 else { return }
        let vc = ThemeDetailViewController()
        vc.themeId = ContentManager.shared.themes[indexPath.row].id
        navigationController?.pushViewController(vc, animated: true)
    }

    // 铁律 6：付费 Prompt 校验余额 + 扣费确认弹窗；免费直接进入填写页
    private func handleUsePrompt(_ prompt: PromptItem) {
        guard let me = AccountManager.shared.currentUser, !AccountManager.shared.isGuest else {
            // 游客态拦截（铁律 2）
            (tabBarController as? MainTabBarController)?.requiresLoginIfNeeded()
            return
        }
        switch prompt.costType {
        case .free:
            let vc = CreatePostContentViewController()
            vc.selectedPrompt = prompt
            navigationController?.pushViewController(vc, animated: true)
        case .coins:
            guard CurrencyManager.shared.canAfford(amount: prompt.costAmount) else {
                Toast.show("Not enough coins. Please recharge.")
                return
            }
            ConfirmDialog.show(
                title: "Use \(prompt.title)?",
                message: "This prompt costs \(prompt.costAmount) Coins. Your balance: \(CurrencyManager.shared.coins).",
                confirmTitle: "Use \(prompt.costAmount) Coins",
                cancelTitle: "Cancel") {
                if CurrencyManager.shared.spend(amount: prompt.costAmount) {
                    Toast.show("Prompt unlocked")
                    let vc = CreatePostContentViewController()
                    vc.selectedPrompt = prompt
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

// MARK: - Cells

final class SectionHeaderCell: UITableViewCell {
    static let reuseIdentifier = "SectionHeaderCell"
    private let label = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        label.font = AppFont.section()
        label.textColor = AppTheme.olive
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(title: String) { label.text = title }
}

final class ThemeCardCell: UITableViewCell {
    static let reuseIdentifier = "ThemeCardCell"
    private let card = UIView()
    private let cover = UIView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        contentView.addSubview(card)
        card.backgroundColor = AppTheme.cream
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.addSubview(cover)
        cover.layer.cornerRadius = 8
        cover.layer.masksToBounds = true
        titleLabel.font = AppFont.cardTitleSemibold()
        titleLabel.textColor = AppTheme.ink
        descLabel.font = AppFont.bodySecondary()
        descLabel.textColor = AppTheme.textSecondary
        descLabel.numberOfLines = 0
        [cover, titleLabel, descLabel].forEach { card.addSubview($0) }
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
            make.height.greaterThanOrEqualTo(120)
        }
        cover.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(12)
            make.width.equalTo(100)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(cover.snp.right).offset(12)
            make.top.equalTo(cover).offset(8)
            make.right.equalToSuperview().inset(12)
        }
        descLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(theme: ThemeItem) {
        cover.backgroundColor = theme.coverColor
        titleLabel.text = theme.title
        descLabel.text = theme.desc
    }
}

final class PromptLibraryCell: UITableViewCell {
    static let reuseIdentifier = "PromptLibraryCell"
    var onUsePrompt: ((PromptItem) -> Void)?
    private var prompts: [PromptItem] = []
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 220, height: 140)
        layout.minimumLineSpacing = 12
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(collectionView)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PromptMiniCell.self, forCellWithReuseIdentifier: PromptMiniCell.reuseIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
            make.height.equalTo(140)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(prompts: [PromptItem]) {
        self.prompts = prompts
        collectionView.reloadData()
    }
}

extension PromptLibraryCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { prompts.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PromptMiniCell.reuseIdentifier, for: indexPath) as! PromptMiniCell
        cell.configure(prompt: prompts[indexPath.item])
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onUsePrompt?(prompts[indexPath.item])
    }
}

final class PromptMiniCell: UICollectionViewCell {
    static let reuseIdentifier = "PromptMiniCell"
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let useButton = UIButton(type: .system)
    private var prompt: PromptItem?
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = AppTheme.cream
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        titleLabel.font = AppFont.cardTitleSemibold()
        titleLabel.textColor = AppTheme.ink
        titleLabel.numberOfLines = 0
        priceLabel.font = AppFont.coinNumberSmall()
        priceLabel.textColor = AppTheme.textCoins
        useButton.setTitle("Use this prompt", for: .normal)
        useButton.setTitleColor(AppTheme.textBrand, for: .normal)
        useButton.titleLabel?.font = AppFont.buttonTextLink()
        [titleLabel, priceLabel, useButton].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview().inset(12)
        }
        priceLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        useButton.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview().inset(12)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(prompt: PromptItem) {
        self.prompt = prompt
        titleLabel.text = prompt.title
        priceLabel.text = prompt.costType == .free ? "Free" : "\(prompt.costAmount) Coins"
    }
}

final class PeopleToNoticeCell: UITableViewCell {
    static let reuseIdentifier = "PeopleToNoticeCell"
    var onFollow: (() -> Void)?
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let followButton = PrimaryButton(title: "Follow")
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(avatar)
        nameLabel.font = AppFont.cardTitle()
        nameLabel.textColor = AppTheme.ink
        bioLabel.font = AppFont.caption()
        bioLabel.textColor = AppTheme.stone
        bioLabel.numberOfLines = 1
        followButton.setTitle("Follow", for: .normal)
        followButton.addAction(UIAction { [weak self] _ in self?.onFollow?() }, for: .touchUpInside)
        followButton.layer.cornerRadius = 18
        [nameLabel, bioLabel, followButton].forEach { contentView.addSubview($0) }
        avatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(8)
            make.top.equalTo(avatar).offset(2)
            make.right.equalTo(followButton.snp.left).offset(-8)
        }
        bioLabel.snp.makeConstraints { make in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
        followButton.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
            make.width.equalTo(90)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(user: User) {
        avatar.configure(user: user)
        nameLabel.text = user.nickname
        bioLabel.text = user.bio
        let me = AccountManager.shared.currentUser?.id ?? ""
        let isFollowing = FollowManager.shared.isFollowing(followerId: me, followeeId: user.id)
        followButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
        followButton.backgroundColor = isFollowing ? AppTheme.cream : AppTheme.primary
        followButton.setTitleColor(isFollowing ? AppTheme.textSecondary : AppTheme.textOnPrimary, for: .normal)
    }
}
