//
//  HomeViewController.swift
//  Yorva
//
//  Tab1 Home：For You / Following
//  For You 顺序：首帖 → 今日/付费 Prompt → 其余帖子 → People to notice
//

import UIKit
import SnapKit

final class HomeViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }

    private let brandLabel = UILabel()
    private let profileAvatar = AvatarView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let introHeader = HomeIntroHeaderView()
    private let introHeaderContainer = UIView()
    private let loadingView = LoadingView()

    private enum FeedItem {
        case post(Post)
        case promptShowcase
        case people([User])
    }

    private var posts: [Post] = []
    private var feedItems: [FeedItem] = []
    private var selectedFeedIndex = 0
    private var featuredFreePrompt: PromptItem?
    private var featuredPaidPrompt: PromptItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
        chooseFeaturedPromptsIfNeeded()
        refreshData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        profileAvatar.configure(user: AccountManager.shared.currentUser)
        refreshData()
    }

    override func setupHierarchy() {
        brandLabel.text = "yorva"
        brandLabel.font = .systemFont(ofSize: 23, weight: .bold)
        brandLabel.textColor = AppTheme.ink

        profileAvatar.configure(user: AccountManager.shared.currentUser)
        profileAvatar.isUserInteractionEnabled = true
        profileAvatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openProfile)))

        introHeader.onSelectFeed = { [weak self] index in
            self?.selectFeed(index)
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedRowHeight = 440
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 92, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier)
        tableView.register(HomePromptShowcaseCell.self, forCellReuseIdentifier: HomePromptShowcaseCell.reuseIdentifier)
        tableView.register(HomePeopleCell.self, forCellReuseIdentifier: HomePeopleCell.reuseIdentifier)
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
            case .postsUpdated, .postInteracted, .followChanged, .blockListChanged, .profileUpdated, .walletUpdated:
                self?.refreshData()
            default:
                break
            }
        }
    }

    override func refreshData() {
        profileAvatar.configure(user: AccountManager.shared.currentUser)
        // 游客可正常浏览首页数据（铁律 2：仅拦截交互，点击任意位置弹必须登录弹窗）
        loadingView.hide()
        chooseFeaturedPromptsIfNeeded()
        let currentUserID = AccountManager.shared.currentUser?.id ?? ""
        posts = selectedFeedIndex == 0
            ? ContentManager.shared.forYouPosts()
            : ContentManager.shared.followingPosts(userId: currentUserID)
        rebuildFeedItems()

        if selectedFeedIndex == 1, posts.isEmpty, !AccountManager.shared.isGuest {
            loadingView.state = .empty(
                title: "Following feed is empty",
                subtitle: "Follow a few people to fill this feed.",
                actionTitle: nil
            )
            loadingView.show(in: tableView)
        }
        tableView.reloadData()
    }

    /// 游客交互拦截：游客点击任意可交互元素均弹必须登录弹窗（铁律 2）
    /// 返回 true 表示已拦截，调用方应终止后续操作
    @discardableResult
    private func interceptGuestAction() -> Bool {
        guard AccountManager.shared.isGuest else { return false }
        (tabBarController as? MainTabBarController)?.requiresLoginIfNeeded()
        return true
    }

    private func chooseFeaturedPromptsIfNeeded() {
        if featuredFreePrompt == nil {
            featuredFreePrompt = ContentManager.shared.freePrompts().randomElement()
        }
        if featuredPaidPrompt == nil {
            featuredPaidPrompt = ContentManager.shared.paidPrompts().randomElement()
        }
    }

    private func rebuildFeedItems() {
        feedItems.removeAll()
        guard selectedFeedIndex == 0 else {
            feedItems = posts.map { FeedItem.post($0) }
            return
        }

        if let firstPost = posts.first {
            feedItems.append(.post(firstPost))
        }
        feedItems.append(.promptShowcase)
        if posts.count > 1 {
            feedItems.append(contentsOf: posts.dropFirst().map { FeedItem.post($0) })
        }

        let people = suggestedPeople()
        if !people.isEmpty {
            feedItems.append(.people(people))
        }
    }

    private func suggestedPeople() -> [User] {
        let currentUserID = AccountManager.shared.currentUser?.id ?? ""
        return DataRepository.shared.users
            .filter { user in
                user.id != currentUserID &&
                !FollowManager.shared.isFollowing(followerId: currentUserID, followeeId: user.id)
            }
            .prefix(3)
            .map { $0 }
    }

    private func selectFeed(_ index: Int) {
        guard index != selectedFeedIndex else { return }
        if interceptGuestAction() { return }
        selectedFeedIndex = index
        introHeader.setSelectedIndex(index)
        tableView.setContentOffset(.zero, animated: false)
        refreshData()
    }

    private func useFreePrompt() {
        if interceptGuestAction() { return }
        guard let prompt = featuredFreePrompt else { return }
        openPublisher(with: prompt)
    }

    private func usePaidPrompt() {
        if interceptGuestAction() { return }
        guard let prompt = featuredPaidPrompt else { return }
        ConfirmDialog.show(
            title: "Use this prompt?",
            message: "This prompt costs \(prompt.costAmount) Coins. Your balance: \(CurrencyManager.shared.coins) Coins.",
            confirmTitle: "Spend \(prompt.costAmount) Coins",
            cancelTitle: "Cancel"
        ) { [weak self] in
            guard CurrencyManager.shared.canAfford(amount: prompt.costAmount) else {
                Toast.show("Not enough coins. Please recharge.")
                return
            }
            guard CurrencyManager.shared.spend(amount: prompt.costAmount) else { return }
            Toast.show("Prompt unlocked")
            self?.openPublisher(with: prompt)
        }
    }

    private func openPublisher(with prompt: PromptItem) {
        let controller = CreatePostContentViewController()
        controller.selectedPrompt = prompt
        navigationController?.pushViewController(controller, animated: true)
    }

    private func post(for cell: PostCardCell) -> Post? {
        guard let indexPath = tableView.indexPath(for: cell),
              case .post(let post) = feedItems[indexPath.row] else { return nil }
        return post
    }

    @objc private func openProfile() {
        if AccountManager.shared.isGuest {
            (tabBarController as? MainTabBarController)?.requiresLoginIfNeeded()
            return
        }
        (tabBarController as? MainTabBarController)?.switchToTab(3)
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate, PostCardCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        feedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch feedItems[indexPath.row] {
        case .post(let post):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier, for: indexPath) as! PostCardCell
            cell.configure(post: post, author: DataRepository.shared.user(by: post.authorId))
            cell.delegate = self
            return cell

        case .promptShowcase:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomePromptShowcaseCell.reuseIdentifier, for: indexPath) as! HomePromptShowcaseCell
            cell.configure(freePrompt: featuredFreePrompt, paidPrompt: featuredPaidPrompt)
            cell.onUseFreePrompt = { [weak self] in self?.useFreePrompt() }
            cell.onUsePaidPrompt = { [weak self] in self?.usePaidPrompt() }
            return cell

        case .people(let people):
            let cell = tableView.dequeueReusableCell(withIdentifier: HomePeopleCell.reuseIdentifier, for: indexPath) as! HomePeopleCell
            cell.configure(users: people)
            cell.onFollow = { [weak self] user in
                guard let self else { return }
                if self.interceptGuestAction() { return }
                guard let currentUserID = AccountManager.shared.currentUser?.id else { return }
                FollowManager.shared.follow(followerId: currentUserID, followeeId: user.id)
                self.refreshData()
            }
            cell.onOpenProfile = { [weak self] user in
                guard let self else { return }
                if self.interceptGuestAction() { return }
                let controller = AuthorProfileViewController()
                controller.author = user
                self.navigationController?.pushViewController(controller, animated: true)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if interceptGuestAction() { return }
        guard case .post(let post) = feedItems[indexPath.row] else { return }
        let controller = PostDetailViewController()
        controller.postId = post.id
        navigationController?.pushViewController(controller, animated: true)
    }

    func postCardDidTapAuthor(_ cell: PostCardCell) {
        if interceptGuestAction() { return }
        guard let post = post(for: cell), let author = DataRepository.shared.user(by: post.authorId) else { return }
        let controller = AuthorProfileViewController()
        controller.author = author
        navigationController?.pushViewController(controller, animated: true)
    }

    func postCardDidTapMore(_ cell: PostCardCell) {
        if interceptGuestAction() { return }
        guard let post = post(for: cell) else { return }
        MoreMenu.showPostMoreMenu(post: post, from: self)
    }

    func postCardDidTapLike(_ cell: PostCardCell) {
        if interceptGuestAction() { return }
        guard let post = post(for: cell) else { return }
        ContentManager.shared.toggleLike(postId: post.id)
    }

    func postCardDidTapComment(_ cell: PostCardCell) {
        if interceptGuestAction() { return }
        guard let post = post(for: cell) else { return }
        let controller = PostDetailViewController()
        controller.postId = post.id
        navigationController?.pushViewController(controller, animated: true)
    }

    func postCardDidTapSave(_ cell: PostCardCell) {
        if interceptGuestAction() { return }
        guard let post = post(for: cell) else { return }
        ContentManager.shared.toggleSave(postId: post.id)
        Toast.show(post.isSaved ? "Removed from saved" : "Saved")
    }

    func postCardDidTapPost(_ cell: PostCardCell) {
        postCardDidTapComment(cell)
    }
}

private final class HomeIntroHeaderView: UIView {
    var onSelectFeed: ((Int) -> Void)?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let forYouButton = UIButton(type: .system)
    private let followingButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = -6
        titleLabel.attributedText = NSAttributedString(string: "Makeroom\nfor less.", attributes: [
            .font: UIFont.systemFont(ofSize: 38, weight: .bold),
            .foregroundColor: AppTheme.ink,
            .paragraphStyle: paragraph
        ])
        // Let Auto Layout use the label's measured multiline intrinsic height.
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.text = "Small reflections from the Yorva community."
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor(hex: 0x7C7E77)

        configureFeedButton(forYouButton, title: "For You", index: 0)
        configureFeedButton(followingButton, title: "Following", index: 1)
        [titleLabel, subtitleLabel, forYouButton, followingButton].forEach { addSubview($0) }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(17)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(7)
            make.left.right.equalTo(titleLabel)
        }
        forYouButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            make.left.equalTo(titleLabel)
            make.width.equalTo(72)
            make.height.equalTo(36)
        }
        followingButton.snp.makeConstraints { make in
            make.centerY.equalTo(forYouButton)
            make.left.equalTo(forYouButton.snp.right).offset(11)
            make.width.equalTo(82)
            make.height.equalTo(36)
        }
        setSelectedIndex(0)
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
        return ceil(20 + titleHeight + 7 + subtitleHeight + 20 + 36 + 12)
    }

    private func configureFeedButton(_ button: UIButton, title: String, index: Int) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        button.layer.cornerRadius = 18
        button.tag = index
        button.addAction(UIAction { [weak self] action in
            guard let button = action.sender as? UIButton else { return }
            self?.onSelectFeed?(button.tag)
        }, for: .touchUpInside)
    }

    func setSelectedIndex(_ index: Int) {
        for (button, buttonIndex) in [(forYouButton, 0), (followingButton, 1)] {
            let selected = index == buttonIndex
            button.backgroundColor = selected ? UIColor(hex: 0x0D110F) : .clear
            button.setTitleColor(selected ? .white : UIColor(hex: 0x73766E), for: .normal)
        }
    }
}

final class HomePromptShowcaseCell: UITableViewCell {
    static let reuseIdentifier = "HomePromptShowcaseCell"
    var onUseFreePrompt: (() -> Void)?
    var onUsePaidPrompt: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let freeCard = HomePromptCardView(style: .free)
    private let paidCard = HomePromptCardView(style: .paid)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        contentStack.axis = .horizontal
        contentStack.spacing = 10
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)
        contentStack.addArrangedSubview(freeCard)
        contentStack.addArrangedSubview(paidCard)
        contentView.addSubview(scrollView)

        freeCard.onTap = { [weak self] in self?.onUseFreePrompt?() }
        paidCard.onTap = { [weak self] in self?.onUsePaidPrompt?() }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(162)
        }
        contentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(9)
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().inset(18)
            make.height.equalTo(144)
        }
        [freeCard, paidCard].forEach { card in
            card.snp.makeConstraints { $0.width.equalTo(235) }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onUseFreePrompt = nil
        onUsePaidPrompt = nil
    }

    func configure(freePrompt: PromptItem?, paidPrompt: PromptItem?) {
        freeCard.configure(prompt: freePrompt)
        paidCard.configure(prompt: paidPrompt)
    }
}

final class HomePromptCardView: UIView {
    enum Style: Equatable { case free, paid }
    var onTap: (() -> Void)?

    private let style: Style
    private let gradientLayer = CAGradientLayer()
    private let eyebrowLabel = UILabel()
    private let bodyLabel = UILabel()
    private let promptLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        layer.cornerRadius = 22
        layer.masksToBounds = true

        if style == .free {
            gradientLayer.colors = [UIColor(hex: 0xD9FF3F).cgColor, UIColor(hex: 0xEFFFB1).cgColor]
        } else {
            gradientLayer.colors = [UIColor(hex: 0xC6F3F2).cgColor, UIColor(hex: 0xDDF9F7).cgColor]
        }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)

        eyebrowLabel.font = .systemFont(ofSize: 10, weight: .medium)
        eyebrowLabel.textColor = UIColor(hex: 0x33362F)
        eyebrowLabel.attributedText = NSAttributedString(
            string: style == .free ? "TODAY’S PROMPT" : "CREATE A LITTLE LIGHTER",
            attributes: [.kern: 0.8]
        )

        bodyLabel.font = .systemFont(ofSize: style == .free ? 18 : 16, weight: .regular)
        bodyLabel.textColor = AppTheme.ink
        bodyLabel.numberOfLines = 2
        if style == .paid {
            bodyLabel.text = "Choose a question.\nAdd one honest answer."
        }

        promptLabel.font = .systemFont(ofSize: 10, weight: .regular)
        promptLabel.textColor = UIColor(hex: 0x5D625B)
        promptLabel.numberOfLines = 1
        promptLabel.isHidden = style == .free

        actionButton.setTitle(style == .free ? "Use this prompt" : "300 Coins Post", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        actionButton.backgroundColor = UIColor(hex: 0x0D110F)
        actionButton.layer.cornerRadius = 16
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        actionButton.addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)

        [eyebrowLabel, bodyLabel, promptLabel, actionButton].forEach { addSubview($0) }
        eyebrowLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(17)
            make.left.right.equalToSuperview().inset(17)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(eyebrowLabel.snp.bottom).offset(10)
            make.left.right.equalTo(eyebrowLabel)
        }
        promptLabel.snp.makeConstraints { make in
            make.left.right.equalTo(eyebrowLabel)
            make.top.equalTo(bodyLabel.snp.bottom).offset(3)
        }
        actionButton.snp.makeConstraints { make in
            make.left.equalTo(eyebrowLabel)
            make.bottom.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 22
    }

    func configure(prompt: PromptItem?) {
        if style == .free {
            bodyLabel.text = prompt?.title ?? "Choose one small thing to keep."
        } else {
            promptLabel.text = prompt?.title
        }
    }
}

private final class HomePeopleCell: UITableViewCell {
    static let reuseIdentifier = "HomePeopleCell"
    var onFollow: ((User) -> Void)?
    var onOpenProfile: ((User) -> Void)?

    private let titleLabel = UILabel()
    private let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        titleLabel.text = "People to notice"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = AppTheme.ink
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually

        contentView.addSubview(titleLabel)
        contentView.addSubview(stackView)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(17)
        }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(135)
            make.bottom.equalToSuperview().inset(20)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onFollow = nil
        onOpenProfile = nil
    }

    func configure(users: [User]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        users.prefix(3).forEach { user in
            let card = HomePersonCardView()
            card.configure(user: user)
            card.onFollow = { [weak self] in self?.onFollow?(user) }
            card.onOpenProfile = { [weak self] in self?.onOpenProfile?(user) }
            stackView.addArrangedSubview(card)
        }
    }
}

private final class HomePersonCardView: UIView, UIGestureRecognizerDelegate {
    var onFollow: (() -> Void)?
    var onOpenProfile: (() -> Void)?

    private let imageView = UIImageView()
    private let initialsLabel = UILabel()
    private let nameLabel = UILabel()
    private let followButton = UIButton(type: .system)
    private let shadeLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 17
        layer.masksToBounds = true
        backgroundColor = UIColor(hex: 0xC9D8D4)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        shadeLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]
        shadeLayer.locations = [0.35, 1]
        layer.addSublayer(shadeLayer)

        initialsLabel.font = .systemFont(ofSize: 32, weight: .semibold)
        initialsLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        initialsLabel.textAlignment = .center
        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center

        followButton.setTitle("Follow", for: .normal)
        followButton.setTitleColor(AppTheme.ink, for: .normal)
        followButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .regular)
        followButton.backgroundColor = UIColor.white.withAlphaComponent(0.94)
        followButton.layer.cornerRadius = 13
        followButton.addAction(UIAction { [weak self] _ in self?.onFollow?() }, for: .touchUpInside)

        [initialsLabel, nameLabel, followButton].forEach { addSubview($0) }
        initialsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-18)
        }
        nameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.bottom.equalTo(followButton.snp.top).offset(-7)
        }
        followButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(11)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(26)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(openProfile))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadeLayer.frame = bounds
    }

    func configure(user: User) {
        if let assetName = user.avatarAssetName, let assetImage = UIImage(named: assetName) {
            backgroundColor = .clear
            imageView.contentMode = .scaleAspectFill
            imageView.image = assetImage
            imageView.isHidden = false
            initialsLabel.isHidden = true
        } else if let image = user.avatarImage {
            backgroundColor = user.avatarPlaceholderColor
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.isHidden = false
            initialsLabel.isHidden = true
        } else {
            backgroundColor = UIColor(hex: 0xE7E8E4)
            imageView.contentMode = .scaleAspectFit
            imageView.image = UIImage(systemName: "person.crop.circle.fill")?.withTintColor(
                UIColor(hex: 0x9EA19C), renderingMode: .alwaysOriginal
            )
            imageView.isHidden = false
            initialsLabel.isHidden = true
        }
        nameLabel.text = user.nickname.components(separatedBy: " ").first ?? user.nickname
    }

    @objc private func openProfile() { onOpenProfile?() }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UIButton)
    }
}
