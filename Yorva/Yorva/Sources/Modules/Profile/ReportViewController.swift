//
//  ReportViewController.swift
//  Yorva
//
//  Report：单选举报原因 + 提交仅本地记录（铁律：拉黑 ≠ 举报）
//  举报不触发内容屏蔽；目标用户及其内容仍正常展示
//

import UIKit
import SnapKit

final class ReportViewController: BaseViewController {

    var targetUserId: String = ""

    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let navTitleLabel = UILabel()
    private let navDivider = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let submitButton = PrimaryButton(title: "Submit")

    private var selectedReason: ReportReason?

    override func viewDidLoad() {
        super.viewDidLoad()
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
        navTitleLabel.attributedText = NSAttributedString(string: "REPORT", attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x7B7E77),
            .kern: 1.8
        ])
        navTitleLabel.textAlignment = .center
        navDivider.backgroundColor = UIColor(hex: 0xE1E0D9)
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = AppTheme.ink
        titleLabel.text = "What’s the issue?"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "Choose the reason that best describes this content. Your\nreport helps keep Yorva thoughtful and safe."
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
        tableView.isScrollEnabled = false
        tableView.rowHeight = 49
        tableView.register(ReportOptionCell.self, forCellReuseIdentifier: ReportOptionCell.reuseIdentifier)
        submitButton.setTitle("Summit", for: .normal)
        submitButton.backgroundColor = AppTheme.ink
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.isEnabled = true
        submitButton.addAction(UIAction { [weak self] _ in self?.attemptSubmit() }, for: .touchUpInside)
        [backButton, navTitleLabel].forEach { topBar.addSubview($0) }
        [topBar, navDivider, titleLabel, subtitleLabel, tableView, submitButton].forEach { view.addSubview($0) }
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
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(17)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(17)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(CGFloat(ReportReason.allCases.count) * 49)
            make.bottom.lessThanOrEqualTo(submitButton.snp.top).offset(-12)
        }
        submitButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func attemptSubmit() {
        guard let reason = selectedReason else {
            Toast.show("Please choose a reason")
            return
        }
        let me = AccountManager.shared.currentUser?.id ?? ""
        ReportManager.shared.report(reporterId: me, targetUserId: targetUserId, reason: reason)
        // 举报仅本地记录，不调用 BlockManager，不影响内容展示
        Toast.show("Report submitted")
        navigationController?.popViewController(animated: true)
    }
}

extension ReportViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { ReportReason.allCases.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReportOptionCell.reuseIdentifier, for: indexPath) as! ReportOptionCell
        let reason = ReportReason.allCases[indexPath.row]
        cell.configure(reason: reason, isSelected: reason == selectedReason)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedReason = ReportReason.allCases[indexPath.row]
        tableView.reloadData()
        submitButton.isEnabled = true
        submitButton.backgroundColor = AppTheme.ink
    }
}

final class ReportOptionCell: UITableViewCell {
    static let reuseIdentifier = "ReportOptionCell"
    private let titleLabel = UILabel()
    private let radioButton = UIImageView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        [titleLabel, radioButton].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(radioButton.snp.right).offset(12)
            make.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(12)
        }
        radioButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(reason: ReportReason, isSelected: Bool) {
        switch reason {
        case .spam: titleLabel.text = "Spam or scam"
        case .harassment: titleLabel.text = "Harassment or bullying"
        case .hate: titleLabel.text = "Hate speech"
        case .nudity: titleLabel.text = "Nudity or sexual content"
        case .dangerous: titleLabel.text = "Dangerous activity"
        case .falseInfo: titleLabel.text = "False water or safety information"
        case .other: titleLabel.text = "Other"
        }
        titleLabel.font = isSelected ? AppFont.reportOptionSelected() : AppFont.reportOption()
        titleLabel.textColor = AppTheme.ink
        contentView.backgroundColor = .white
        radioButton.image = UIImage(systemName: isSelected ? "largecircle.fill.circle" : "circle")?
            .withTintColor(isSelected ? UIColor(hex: 0xB9DD00) : UIColor(hex: 0xBFC3BA), renderingMode: .alwaysOriginal)
    }
}
