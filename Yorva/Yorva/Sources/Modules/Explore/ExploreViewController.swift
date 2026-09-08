//
//  ExploreViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class ExploreViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgRoot }
    private let brandLabel = UILabel()
    private let profileAvatar = AvatarView()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let introHeader = ExploreIntroHeaderView()
    private let introHeaderContainer = UIView()
    private var posts: [Post] = []
    private var featuredFreePrompt: PromptItem?
    private var featuredPaidPrompt: PromptItem?

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

        introHeader.onSelectTheme = { [weak self] theme in
            let controller = ThemeDetailViewController()
            controller.themeId = theme.id
            self?.navigationController?.pushViewController(controller, animated: true)
        }

        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderTopPadding = 0
        tableView.estimatedRowHeight = 300
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 92, right: 0)
        tableView.register(ThemeBrowseCell.self, forCellReuseIdentifier: ThemeBrowseCell.reuseIdentifier)
        tableView.register(HomePromptShowcaseCell.self, forCellReuseIdentifier: HomePromptShowcaseCell.reuseIdentifier)
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier)
        tableView.register(SectionHeaderCell.self, forCellReuseIdentifier: SectionHeaderCell.reuseIdentifier)
        introHeaderContainer.backgroundColor = .clear
        introHeaderContainer.addSubview(introHeader)
        introHeader.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.tableHeaderView = introHeaderContainer
        [brandLabel, profileAvatar, tableView].forEach { view.addSubview($0) }
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
        tableView.snp.makeConstraints { make in
            make.top.equalTo(brandLabel.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let targetFrame = CGRect(x: 0, y: 0, width: width, height: introHeader.requiredHeight(for: width))
        if introHeaderContainer.frame != targetFrame {
            introHeaderContainer.frame = targetFrame
            introHeader.frame = introHeaderContainer.bounds
            tableView.tableHeaderView = introHeaderContainer
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            switch event {
            case .followChanged, .blockListChanged, .postsUpdated, .postInteracted, .profileUpdated:
                self?.tableView.reloadData()
            default: break
            }
        }
    }

    override func refreshData() {
        profileAvatar.configure(user: AccountManager.shared.currentUser)
        if featuredFreePrompt == nil {
            featuredFreePrompt = ContentManager.shared.freePrompts().randomElement()
        }
        if featuredPaidPrompt == nil {
            featuredPaidPrompt = ContentManager.shared.paidPrompts().randomElement()
        }
        // Explore owns its full post list; do not discard the newest item created on the Home tab.
        posts = ContentManager.shared.forYouPosts()
        tableView.reloadData()
    }
}

extension ExploreViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 3 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return posts.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: SectionHeaderCell.reuseIdentifier) as! SectionHeaderCell
        let titles = ["Browse by theme", "Prompt library", "Worth a closer look"]
        cell.configure(title: titles[section])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 44 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: ThemeBrowseCell.reuseIdentifier, for: indexPath) as! ThemeBrowseCell
            cell.configure(themes: ContentManager.shared.themes)
            cell.onSelectTheme = { [weak self] theme in
                let controller = ThemeDetailViewController()
                controller.themeId = theme.id
                self?.navigationController?.pushViewController(controller, animated: true)
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomePromptShowcaseCell.reuseIdentifier, for: indexPath) as! HomePromptShowcaseCell
            cell.configure(freePrompt: featuredFreePrompt, paidPrompt: featuredPaidPrompt)
            cell.onUseFreePrompt = { [weak self] in
                guard let prompt = self?.featuredFreePrompt else { return }
                self?.handleUsePrompt(prompt)
            }
            cell.onUsePaidPrompt = { [weak self] in
                guard let prompt = self?.featuredPaidPrompt else { return }
                self?.handleUsePrompt(prompt)
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier, for: indexPath) as! PostCardCell
            let post = posts[indexPath.row]
            cell.configure(post: post, author: DataRepository.shared.user(by: post.authorId))
            cell.delegate = self
            return cell
        default: return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 2, posts.indices.contains(indexPath.row) else { return }
        let controller = PostDetailViewController()
        controller.postId = posts[indexPath.row].id
        navigationController?.pushViewController(controller, animated: true)
    }

    private func handleUsePrompt(_ prompt: PromptItem) {
        guard AccountManager.shared.currentUser != nil, !AccountManager.shared.isGuest else {
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
                title: "Unlock Prompt",
                message: "Are you sure you want to spend \(prompt.costAmount) Coins to unlock an extra prompt for your post?",
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

extension ExploreViewController: PostCardCellDelegate {
    private func post(for cell: PostCardCell) -> Post? {
        guard let indexPath = tableView.indexPath(for: cell), posts.indices.contains(indexPath.row) else { return nil }
        return posts[indexPath.row]
    }

    func postCardDidTapAuthor(_ cell: PostCardCell) {
        guard let post = post(for: cell), let user = DataRepository.shared.user(by: post.authorId) else { return }
        let controller = AuthorProfileViewController()
        controller.author = user
        navigationController?.pushViewController(controller, animated: true)
    }
    func postCardDidTapMore(_ cell: PostCardCell) { if let post = post(for: cell) { MoreMenu.showPostMoreMenu(post: post, from: self) } }
    func postCardDidTapLike(_ cell: PostCardCell) { if let post = post(for: cell) { ContentManager.shared.toggleLike(postId: post.id) } }
    func postCardDidTapComment(_ cell: PostCardCell) {
        guard let post = post(for: cell) else { return }
        let controller = PostDetailViewController()
        controller.postId = post.id
        navigationController?.pushViewController(controller, animated: true)
    }
    func postCardDidTapSave(_ cell: PostCardCell) { if let post = post(for: cell) { ContentManager.shared.toggleSave(postId: post.id) } }

    @objc private func openProfile() {
        if AccountManager.shared.isGuest {
            (tabBarController as? MainTabBarController)?.requiresLoginIfNeeded()
            return
        }
        (tabBarController as? MainTabBarController)?.switchToTab(3)
    }
    func postCardDidTapPost(_ cell: PostCardCell) { postCardDidTapComment(cell) }
}

private final class ExploreIntroHeaderView: UIView {
    var onSelectTheme: ((ThemeItem) -> Void)?
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = -5
        titleLabel.attributedText = NSAttributedString(string: "Look around.\nKeep what fits.", attributes: [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: AppTheme.ink,
            .paragraphStyle: paragraph
        ])
        // Measure both lines from the current width instead of clipping to a
        // fixed frame height.
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.text = "A considered way into people, ideas and everyday rituals."
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = UIColor(hex: 0x7C7E77)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview().inset(17)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(7)
            make.left.right.equalTo(titleLabel)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func requiredHeight(for width: CGFloat) -> CGFloat {
        let textWidth = max(0, width - 34)
        titleLabel.preferredMaxLayoutWidth = textWidth
        subtitleLabel.preferredMaxLayoutWidth = textWidth
        let titleHeight = titleLabel.sizeThatFits(
            CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        ).height
        let subtitleHeight = subtitleLabel.sizeThatFits(
            CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        ).height
        return ceil(8 + titleHeight + 7 + subtitleHeight + 16)
    }
}

private final class ThemeBrowseCell: UITableViewCell {
    static let reuseIdentifier = "ThemeBrowseCell"
    var onSelectTheme: ((ThemeItem) -> Void)?
    private let scrollView = UIScrollView()
    private let themesStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        themesStack.axis = .horizontal
        themesStack.spacing = 12
        themesStack.alignment = .center
        contentView.addSubview(scrollView)
        scrollView.addSubview(themesStack)
        scrollView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(136)
            make.bottom.equalToSuperview().inset(8)
        }
        themesStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(scrollView.contentLayoutGuide)
            make.height.equalTo(scrollView.frameLayoutGuide)
            make.left.equalTo(scrollView.contentLayoutGuide).offset(17)
            make.right.equalTo(scrollView.contentLayoutGuide).inset(17)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(themes: [ThemeItem]) {
        themesStack.arrangedSubviews.forEach {
            themesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for theme in themes.prefix(4) {
            let card = ThemeBrowseCardView()
            card.configure(theme: theme)
            card.onTap = { [weak self] in self?.onSelectTheme?(theme) }
            themesStack.addArrangedSubview(card)
            card.snp.makeConstraints { make in
                make.width.height.equalTo(128)
            }
        }
    }
}

private final class ThemeBrowseCardView: UIView {
    var onTap: (() -> Void)?
    private let imageView = UIImageView()
    private let shadeLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let tapButton = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 64
        layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        shadeLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.62).cgColor]
        shadeLayer.locations = [0.35, 1]
        layer.addSublayer(shadeLayer)
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        descLabel.font = .systemFont(ofSize: 10, weight: .regular)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 2
        descLabel.lineBreakMode = .byWordWrapping
        [titleLabel, descLabel, tapButton].forEach { addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.centerY.equalToSuperview().offset(-9)
        }
        descLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
        }
        tapButton.snp.makeConstraints { $0.edges.equalToSuperview() }
        tapButton.addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        shadeLayer.frame = bounds
        shadeLayer.cornerRadius = layer.cornerRadius
    }

    func configure(theme: ThemeItem) {
        let assetName: String
        switch theme.id {
        case "theme-keep": assetName = "Section1"
        case "theme-habits": assetName = "Section"
        case "theme-letgo": assetName = "Section2"
        case "theme-lesstech": assetName = "Section3"
        default: assetName = "Section"
        }
        imageView.image = UIImage(named: assetName)
        imageView.backgroundColor = theme.coverColor
        titleLabel.text = theme.title
        descLabel.text = browseDescription(for: theme)
    }

    private func browseDescription(for theme: ThemeItem) -> String {
        switch theme.id {
        case "theme-keep": return "What earns its place"
        case "theme-habits": return "Make days lighter"
        case "theme-letgo": return "Release with care"
        case "theme-lesstech": return "Make room offline"
        default: return theme.desc
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
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = AppTheme.ink
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
