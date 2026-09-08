//
//  CustomSheet.swift
//  Yorva
//
//

import UIKit
import SnapKit

struct SheetItem {
    let title: String
    let icon: String?
    let isCancel: Bool
    let handler: (() -> Void)?
}

final class CustomSheet: UIView {

    private let container = UIView()
    private var items: [SheetItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.overlay
        let backdrop = UIView()
        backdrop.backgroundColor = .clear
        addSubview(backdrop)
        backdrop.snp.makeConstraints { $0.edges.equalToSuperview() }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleDismiss))
        tap.cancelsTouchesInView = true
        backdrop.addGestureRecognizer(tap)
        addSubview(container)
        container.backgroundColor = AppTheme.bgSheet
        container.layer.cornerRadius = 20
        container.layer.masksToBounds = true
        container.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    /// - Parameters:
    static func show(title: String? = nil, items: [SheetItem]) {
        guard let host = UIApplication.shared.activeKeyWindow else { return }
        let sheet = CustomSheet()
        host.addSubview(sheet)
        sheet.snp.makeConstraints { $0.edges.equalToSuperview() }
        sheet.configure(title: title, items: items)
        host.layoutIfNeeded()
        sheet.layoutIfNeeded()
        sheet.container.transform = CGAffineTransform(translationX: 0, y: sheet.container.bounds.height)
        sheet.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4) {
            sheet.alpha = 1
            sheet.container.transform = .identity
        }
    }

    private func configure(title: String?, items: [SheetItem]) {
        self.items = items
        container.subviews.forEach { $0.removeFromSuperview() }
        let st = UIStackView()
        st.axis = .vertical
        st.spacing = 0
        st.alignment = .fill
        container.addSubview(st)
        st.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(title == nil ? 8 : 0)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(UIApplication.shared.activeKeyWindow?.safeAreaInsets.bottom ?? 0)
        }
        if let title = title {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = AppFont.bodySecondary()
            titleLabel.textColor = AppTheme.textTertiary
            titleLabel.textAlignment = .center
            let wrap = UIView()
            container.addSubview(wrap)
            wrap.addSubview(titleLabel)
            wrap.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(46)
            }
            titleLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
            }
            let div = UIView(); div.backgroundColor = AppTheme.divider
            container.addSubview(div)
            div.snp.makeConstraints { make in
                make.top.equalTo(wrap.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(1)
            }
            st.snp.remakeConstraints { make in
                make.top.equalTo(div.snp.bottom)
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(UIApplication.shared.activeKeyWindow?.safeAreaInsets.bottom ?? 0)
            }
        }
        for item in items {
            st.addArrangedSubview(makeRow(item))
        }
    }

    private func makeRow(_ item: SheetItem) -> UIView {
        let row = UIView()
        row.backgroundColor = AppTheme.bgSheet
        let label = UILabel()
        label.text = item.title
        label.font = AppFont.sheetItem()
        label.textColor = item.isCancel ? AppTheme.textSecondary : AppTheme.ink
        label.textAlignment = .center
        row.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(item.isCancel ? 56 : 50)
        }
        let btn = UIButton(type: .system)
        btn.addAction(UIAction { [weak self] _ in
            self?.dismiss()
            item.handler?()
        }, for: .touchUpInside)
        row.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if !item.isCancel {
            let divider = UIView(); divider.backgroundColor = AppTheme.divider
            row.addSubview(divider)
            divider.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
        }
        return row
    }

    @objc private func handleDismiss() { dismiss() }
    func dismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.container.transform = CGAffineTransform(translationX: 0, y: self.container.bounds.height)
        }) { _ in self.removeFromSuperview() }
    }
}
