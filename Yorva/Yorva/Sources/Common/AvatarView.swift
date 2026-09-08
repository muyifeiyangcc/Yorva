//
//  AvatarView.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class AvatarView: UIView {

    private let initialsLabel = UILabel()
    private let imageView = UIImageView()

    var color: UIColor = AppTheme.primary { didSet { backgroundColor = color } }
    var initials: String = "" {
        didSet { initialsLabel.text = initials }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.primary
        layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
        guard let u = user else {
            showDefaultAvatar()
            return
        }
        if let assetName = u.avatarAssetName, let assetImage = UIImage(named: assetName) {
            backgroundColor = .clear
            initialsLabel.isHidden = true
            imageView.contentMode = .scaleAspectFill
            imageView.image = assetImage
            imageView.isHidden = false
            return
        }
        if let image = u.avatarImage {
            backgroundColor = u.avatarPlaceholderColor
            initialsLabel.text = u.avatarInitials
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.isHidden = false
            initialsLabel.isHidden = true
            return
        }
        showDefaultAvatar()
    }

    func setImage(_ image: UIImage?) {
        guard let image = image else {
            showDefaultAvatar()
            return
        }
        imageView.contentMode = .scaleAspectFill
        imageView.image = image
        imageView.isHidden = false
        initialsLabel.isHidden = true
    }

    private func showDefaultAvatar() {
        backgroundColor = UIColor(hex: 0xE7E8E4)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "person.crop.circle.fill")?.withTintColor(
            UIColor(hex: 0x9EA19C), renderingMode: .alwaysOriginal
        )
        imageView.isHidden = false
        initialsLabel.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

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
