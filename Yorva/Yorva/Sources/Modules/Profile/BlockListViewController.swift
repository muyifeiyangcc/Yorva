//
//  BlockListViewController.swift
//  Yorva
//
//  Block List + Unblock（铁律：拉黑逻辑；解除拉黑后内容恢复展示）
//

import UIKit
import SnapKit

final class BlockListViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = LoadingView()
    private var users: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Block List"
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
        tableView.register(BlockRowCell.self, forCellReuseIdentifier: BlockRowCell.reuseIdentifier)
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
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
            if case .blockListChanged = event { self?.refreshData() }
        }
    }

    override func refreshData() {
        users = BlockManager.shared.blockedIds
            .compactMap { DataRepository.shared.user(by: $0) }
        if users.isEmpty {
            loadingView.state = .empty(title: "No blocked users", subtitle: "Blocked accounts will show up here.", actionTitle: nil)
            loadingView.show(in: view)
        } else {
            loadingView.hide()
        }
        tableView.reloadData()
    }
}

extension BlockListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { users.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BlockRowCell.reuseIdentifier, for: indexPath) as! BlockRowCell
        cell.configure(user: users[indexPath.row])
        cell.onUnblock = { [weak self] in self?.refreshData() }
        return cell
    }
}

final class BlockRowCell: UITableViewCell {
    static let reuseIdentifier = "BlockRowCell"
    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let unblockButton = UIButton(type: .system)
    var onUnblock: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        unblockButton.setTitle("Unblock", for: .normal)
        unblockButton.setTitleColor(AppTheme.error, for: .normal)
        unblockButton.titleLabel?.font = AppFont.buttonSecondary()
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
        [avatar, nameLabel, unblockButton].forEach { contentView.addSubview($0) }
        avatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        nameLabel.font = AppFont.cardTitle()
        nameLabel.textColor = AppTheme.ink
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.equalTo(unblockButton.snp.left).offset(-8)
        }
        unblockButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
            make.width.equalTo(80)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    private var user: User?
    func configure(user: User) {
        self.user = user
        avatar.configure(user: user)
        nameLabel.text = user.nickname
    }
}
