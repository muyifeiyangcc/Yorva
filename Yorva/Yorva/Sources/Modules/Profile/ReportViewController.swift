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
    var targetName: String?

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let submitButton = PrimaryButton(title: "Submit")

    private var selectedReason: ReportReason?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Report"
        setupHierarchy()
        applyAutoLayoutConstraints()
    }

    override func setupHierarchy() {
        titleLabel.font = AppFont.section()
        titleLabel.textColor = AppTheme.olive
        titleLabel.text = "Report \(targetName.map { "@\($0)" } ?? "user")"
        subtitleLabel.font = AppFont.bodySecondary()
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "Tell us what's wrong with this account. We'll review your report carefully."
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(ReportOptionCell.self, forCellReuseIdentifier: ReportOptionCell.reuseIdentifier)
        submitButton.backgroundColor = AppTheme.primaryDisabled
        submitButton.isEnabled = false
        submitButton.setTitleColor(AppTheme.textOnPrimary.withAlphaComponent(0.6), for: .disabled)
        submitButton.addAction(UIAction { [weak self] _ in self?.attemptSubmit() }, for: .touchUpInside)
        [titleLabel, subtitleLabel, tableView, submitButton].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(16)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(CGFloat(ReportReason.allCases.count) * 50)
            make.bottom.lessThanOrEqualTo(submitButton.snp.top).offset(-12)
        }
        submitButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
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
        submitButton.backgroundColor = AppTheme.primary
    }
}

final class ReportOptionCell: UITableViewCell {
    static let reuseIdentifier = "ReportOptionCell"
    private let titleLabel = UILabel()
    private let radioButton = UIImageView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        [titleLabel, radioButton].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(radioButton.snp.left).offset(-8)
            make.top.bottom.equalToSuperview().inset(12)
        }
        radioButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(reason: ReportReason, isSelected: Bool) {
        titleLabel.text = reason.displayName
        titleLabel.font = isSelected ? AppFont.reportOptionSelected() : AppFont.reportOption()
        titleLabel.textColor = isSelected ? AppTheme.textBrand : AppTheme.ink
        contentView.backgroundColor = isSelected ? AppTheme.selectionBg : .clear
        radioButton.image = UIImage(systemName: isSelected ? "largecircle.fill.circle" : "circle")?
            .withTintColor(isSelected ? AppTheme.primary : AppTheme.stone, renderingMode: .alwaysOriginal)
    }
}
