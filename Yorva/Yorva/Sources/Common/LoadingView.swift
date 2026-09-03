//
//  LoadingView.swift
//  Yorva
//
//  加载中遮罩（半透明黑底菊花，关键节点动画）
//  状态管理：加载中 / 解析异常 / 正常数据（铁律 11）
//

import UIKit
import SnapKit

final class LoadingView: UIView {

    private let indicator = UIActivityIndicatorView(style: .medium)
    private let label = UILabel()

    enum State { case loading, empty(title: String, subtitle: String, actionTitle: String?), parseError }
    var state: State = .loading { didSet { applyState() } }
    var onAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.bgRoot
        let stack = UIStackView(arrangedSubviews: [indicator, label])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
        label.font = AppFont.body()
        label.textColor = AppTheme.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
    }
    required init?(coder: NSCoder) { fatalError() }

    func show(in view: UIView) {
        view.addSubview(self)
        snp.makeConstraints { make in make.edges.equalToSuperview() }
        state = .loading
    }
    func hide() { removeFromSuperview() }

    private func applyState() {
        switch state {
        case .loading:
            indicator.isHidden = false
            indicator.startAnimating()
            label.text = "Loading…"
            label.textColor = AppTheme.textSecondary
        case .empty(let title, let subtitle, let actionTitle):
            indicator.stopAnimating(); indicator.isHidden = true
            let empty = EmptyStateView()
            empty.configure(title: title, subtitle: subtitle, actionTitle: actionTitle)
            empty.onAction = onAction
            addSubview(empty)
            empty.snp.makeConstraints { $0.edges.equalToSuperview() }
            label.text = ""
        case .parseError:
            indicator.stopAnimating(); indicator.isHidden = true
            label.text = "Content is temporarily unavailable. Please pull down to refresh."
            label.textColor = AppTheme.textError
        }
    }
}

final class EmptyStateView: UIView {

    private let icon = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    var onAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, subtitleLabel, actionButton])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
        icon.backgroundColor = AppTheme.cream
        icon.layer.cornerRadius = 40
        icon.snp.makeConstraints { make in make.size.equalTo(80) }
        titleLabel.font = AppFont.emptyTitle()
        titleLabel.textColor = AppTheme.textSecondary
        titleLabel.textAlignment = .center
        subtitleLabel.font = AppFont.emptySubtitle()
        subtitleLabel.textColor = AppTheme.textTertiary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        actionButton.setTitleColor(AppTheme.textBrand, for: .normal)
        actionButton.titleLabel?.font = AppFont.buttonTextLink()
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, subtitle: String, actionTitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.isHidden = actionTitle == nil
    }
    @objc private func handleAction() { onAction?() }
}
