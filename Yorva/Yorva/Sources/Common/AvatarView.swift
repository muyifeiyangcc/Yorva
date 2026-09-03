//
//  AvatarView.swift
//  Yorva
//
//  占位头像视图（暂无切图资源）
//  圆形 + 首字母占位，便于后续直接替换图片资源
//  尺寸由调用方通过 AutoLayout 设定，匹配设计稿图标尺寸
//

import UIKit
import SnapKit

final class AvatarView: UIView {

    private let initialsLabel = UILabel()

    var color: UIColor = AppTheme.primary { didSet { backgroundColor = color } }
    var initials: String = "" {
        didSet { initialsLabel.text = initials }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.primary
        layer.masksToBounds = true
        addSubview(initialsLabel)
        initialsLabel.textColor = .white
        initialsLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        initialsLabel.textAlignment = .center
        initialsLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(user: User?) {
        if let u = user {
            backgroundColor = u.avatarPlaceholderColor
            initialsLabel.text = u.avatarInitials
        } else {
            backgroundColor = AppTheme.primaryDisabled
            initialsLabel.text = "?"
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

/// 占位图标视图（暂无切图）：纯色圆角矩形，便于后续替换图片资源
/// 调用方传入 design 尺寸，便于后续直接替换图片资源
final class PlaceholderIconView: UIView {

    private let symbolLabel = UILabel()
    var symbolName: String? {
        didSet {
            if let name = symbolName {
                let image = UIImage(systemName: name)
                symbolLabel.text = image == nil ? name.prefix(1).description : nil
                if let image = image {
                    let iv = UIImageView(image: image.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal))
                    iv.contentMode = .scaleAspectFit
                    addSubview(iv)
                    iv.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(symbolLabel)
        symbolLabel.textColor = AppTheme.ink
        symbolLabel.font = .systemFont(ofSize: 12, weight: .medium)
        symbolLabel.textAlignment = .center
        symbolLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// 通用主按钮（已激活态：主色背景 + 白文字）
final class PrimaryButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(AppTheme.textOnPrimary, for: .normal)
        titleLabel?.font = AppFont.buttonPrimary()
        backgroundColor = AppTheme.primary
        layer.cornerRadius = 24
        layer.masksToBounds = true
        snp.makeConstraints { make in make.height.equalTo(48) }
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// 文字按钮（品牌色文字按钮，如 I'm new / Use this prompt）
final class TextLinkButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(AppTheme.textBrand, for: .normal)
        setTitleColor(AppTheme.primaryPressed, for: .highlighted)
        titleLabel?.font = AppFont.buttonTextLink()
    }
    required init?(coder: NSCoder) { fatalError() }
}
