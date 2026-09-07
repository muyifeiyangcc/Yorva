//
//  BlockListViewController.swift
//  Yorva
//
//  Block List + Unblock（铁律：拉黑逻辑；解除拉黑后内容恢复展示）
//

import UIKit
import SnapKit

final class BlockListViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let navTitleLabel = UILabel()
    private let navDivider = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let listScrollView = UIScrollView()
    private let listContentView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = LoadingView()
    private var users: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupHierarchy() {
        topBar.backgroundColor = UIColor(hex: 0xFAF9F3)
        backButton.setImage(UIImage(systemName: "chevron.backward")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 18
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        backButton.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        navTitleLabel.attributedText = NSAttributedString(string: "BLOCK LIST", attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x7B7E77),
            .kern: 1.8
        ])
        navTitleLabel.textAlignment = .center
        navDivider.backgroundColor = UIColor(hex: 0xE1E0D9)
        titleLabel.text = "Block List."
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = AppTheme.ink
        subtitleLabel.text = "People you’ve blocked can’t view your profile or start a\nconversation with you."
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor(hex: 0x7B7E77)
        subtitleLabel.numberOfLines = 2
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .white
        tableView.layer.cornerRadius = 18
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        tableView.layer.masksToBounds = true
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(hex: 0xE8E6DF)
        tableView.separatorInset = .zero
        tableView.register(BlockRowCell.self, forCellReuseIdentifier: BlockRowCell.reuseIdentifier)
        tableView.rowHeight = 79
        tableView.isScrollEnabled = false
        listScrollView.alwaysBounceVertical = true
        listScrollView.showsVerticalScrollIndicator = false
        listScrollView.contentInsetAdjustmentBehavior = .never
        [backButton, navTitleLabel].forEach { topBar.addSubview($0) }
        loadingView.backgroundColor = pageBackgroundColor
        loadingView.isHidden = true
        [titleLabel, subtitleLabel, tableView].forEach { listContentView.addSubview($0) }
        listScrollView.addSubview(listContentView)
        [topBar, navDivider, listScrollView, loadingView].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        topBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(106)
        }
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(6)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(36)
        }
        navTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }
        navDivider.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(-1)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        listScrollView.snp.makeConstraints { make in
            make.top.equalTo(navDivider.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        listContentView.snp.makeConstraints { make in
            make.edges.equalTo(listScrollView.contentLayoutGuide)
            make.width.equalTo(listScrollView.frameLayoutGuide)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(17)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalTo(titleLabel)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(22)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(0)
            make.bottom.equalToSuperview().inset(24)
        }
        loadingView.snp.makeConstraints { make in
            make.top.equalTo(navDivider.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            if case .blockListChanged = event { self?.refreshData() }
        }
    }

    override func refreshData() {
        users = BlockManager.shared.blockedIds
            .compactMap { DataRepository.shared.user(by: $0) }
        tableView.snp.updateConstraints { make in
            make.height.equalTo(CGFloat(users.count) * 79)
        }
        if users.isEmpty {
            loadingView.state = .empty(title: "No blocked users", subtitle: "Blocked accounts will show up here.", actionTitle: nil)
            tableView.isHidden = true
            loadingView.isHidden = false
        } else {
            tableView.isHidden = false
            loadingView.isHidden = true
        }
        tableView.reloadData()
    }
}

extension BlockListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { users.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BlockRowCell.reuseIdentifier, for: indexPath) as! BlockRowCell
        cell.configure(user: users[indexPath.row], index: indexPath.row)
        cell.onUnblock = { [weak self] in self?.refreshData() }
        return cell
    }
}

final class BlockRowCell: UITableViewCell {
    static let reuseIdentifier = "BlockRowCell"
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let statusLabel = UILabel()
    private let unblockButton = UIButton(type: .system)
    var onUnblock: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        unblockButton.setTitle("Unblock", for: .normal)
        unblockButton.setTitleColor(UIColor(hex: 0x7B7E77), for: .normal)
        unblockButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .regular)
        unblockButton.backgroundColor = UIColor(hex: 0xF0F0E9)
        unblockButton.layer.cornerRadius = 15
        unblockButton.addAction(UIAction { [weak self] _ in
            guard let self = self, let user = self.user else { return }
            ConfirmDialog.show(title: "Unblock \(user.nickname)?",
                              message: "Posts, comments and messages from this user will be visible again.",
                              confirmTitle: "Unblock", cancelTitle: "Cancel", isDestructive: true) {
                BlockManager.shared.unblock(user.id)
                Toast.show("Unblocked")
                self.onUnblock?()
            }
        }, for: .touchUpInside)
        handleLabel.font = .systemFont(ofSize: 10, weight: .regular)
        handleLabel.textColor = UIColor(hex: 0x85857D)
        statusLabel.font = .systemFont(ofSize: 10, weight: .regular)
        statusLabel.textColor = UIColor(hex: 0x5C5C5C)
        [avatar, nameLabel, handleLabel, statusLabel, unblockButton].forEach { contentView.addSubview($0) }
        avatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(46)
        }
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = AppTheme.ink
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(8)
            make.top.equalToSuperview().offset(13)
            make.right.equalTo(unblockButton.snp.left).offset(-8)
        }
        handleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
        statusLabel.snp.makeConstraints { make in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(handleLabel.snp.bottom).offset(2)
        }
        unblockButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
            make.width.equalTo(58)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    private var user: User?
    func configure(user: User, index: Int) {
        self.user = user
        avatar.configure(user: user)
        nameLabel.text = user.nickname
        let handle = user.nickname.lowercased().split(separator: " ").first.map(String.init) ?? "user"
        handleLabel.text = "@\(handle.replacingOccurrences(of: ".", with: ""))"
        let blockedDate = BlockManager.shared.blockedAt(user.id) ?? Date()
        statusLabel.text = "Blocked \(Self.relativeDate(blockedDate))"
    }

    private static func relativeDate(_ date: Date) -> String {
        let days = max(0, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0)
        if days == 0 { return "today" }
        if days == 1 { return "1 day ago" }
        if days < 7 { return "\(days) days ago" }
        let weeks = days / 7
        if weeks == 1 { return "1 week ago" }
        if weeks < 4 { return "\(weeks) weeks ago" }
        let months = max(1, days / 30)
        return months == 1 ? "1 month ago" : "\(months) months ago"
    }
}
