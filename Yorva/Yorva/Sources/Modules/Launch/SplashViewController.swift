//
//  SplashViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class SplashViewController: BaseViewController {

    var onFinished: (() -> Void)?

    override var pageBackgroundColor: UIColor { AppTheme.bgSplash }

    override func viewDidLoad() {
        super.viewDidLoad()
        let brand = UILabel()
        brand.font = AppFont.splash(30)
        brand.textColor = AppTheme.olive
        brand.text = "Yorva"
        let tagline = UILabel()
        tagline.font = AppFont.bodySecondary()
        tagline.textColor = AppTheme.textSecondary
        tagline.text = "Makeroom for less."
        [brand, tagline].forEach { view.addSubview($0) }
        brand.snp.makeConstraints { make in make.center.equalToSuperview() }
        tagline.snp.makeConstraints { make in
            make.top.equalTo(brand.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.onFinished?()
        }
    }
}
