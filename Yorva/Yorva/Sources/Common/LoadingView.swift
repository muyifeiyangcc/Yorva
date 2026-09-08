//
//  LoadingView.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class LoadingView: UIView {

    private let indicator = UIActivityIndicatorView(style: .medium)
    private let label = UILabel()
    private var emptyStateView: EmptyStateView?

    enum State { case loading, empty(title: String, subtitle: String, actionTitle: String?), parseError }
    var state: State = .loading { didSet { applyState() } }
    var onAction: (() -> Void)? {
        didSet { emptyStateView?.onAction = onAction }
    }

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
        if superview !== view {
            removeFromSuperview()
            view.addSubview(self)
            snp.makeConstraints { make in make.edges.equalToSuperview() }
        }
    }
    func hide() { removeFromSuperview() }

    private func applyState() {
        emptyStateView?.removeFromSuperview()
        emptyStateView = nil
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
            emptyStateView = empty
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

    private let icon = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    var onAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, subtitleLabel, actionButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
        icon.contentMode = .scaleAspectFit
        icon.tintColor = AppTheme.stone
        icon.snp.makeConstraints { make in make.size.equalTo(CGSize(width: 48, height: 48)) }
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

    func configure(title: String, subtitle: String, actionTitle: String?,
                   iconName: String = "tray") {
        icon.image = UIImage(systemName: iconName,
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 40, weight: .regular))?
            .withTintColor(AppTheme.stone, renderingMode: .alwaysOriginal)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.isHidden = actionTitle == nil
    }
    @objc private func handleAction() { onAction?() }
}
