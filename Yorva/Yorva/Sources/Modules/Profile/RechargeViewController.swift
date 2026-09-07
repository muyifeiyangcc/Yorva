//
//  RechargeViewController.swift
//  Yorva
//
//  Recharge Coins. Products are rendered from the StoreKit product response;
//  the catalog only supplies the fixed USD presentation required by the UI.
//

import UIKit
import SnapKit

final class RechargeViewController: BaseViewController, StoreKitManagerDelegate {

    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let navTitleLabel = UILabel()
    private let navDivider = UIView()
    private let titleLabel = UILabel()

    private let balanceCard = UIView()
    private let balanceGradient = CAGradientLayer()
    private let balanceCaption = UILabel()
    private let balanceValue = UILabel()
    private let refreshButton = UIButton(type: .system)
    private let coinImage = UIImageView(image: UIImage(named: "coin"))

    private let usageTitle = UILabel()
    private let usageCard = UIView()
    private let packageTitle = UILabel()
    private let contentScrollView = UIScrollView()
    private let scrollContentView = UIView()
    private let productsCollectionView: UICollectionView
    private var productsCollectionHeightConstraint: Constraint?

    private let purchaseBar = UIView()
    private let purchaseButton = UIButton(type: .system)
    private let loadingView = LoadingView()
    private let purchaseLoading = UIView()
    private let purchaseIndicator = UIActivityIndicatorView(style: .large)

    private var products: [WalletProduct] = []
    private var selectedProductId: String?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = .zero
        productsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = .zero
        productsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        StoreKitManager.shared.delegate = self
        loadProducts()
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            if case .walletUpdated = event { self?.updateBalanceLabel() }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        balanceGradient.frame = balanceCard.bounds
    }

    override func setupHierarchy() {
        topBar.backgroundColor = pageBackgroundColor
        backButton.setImage(UIImage(systemName: "chevron.backward")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 18
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        backButton.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)

        navTitleLabel.attributedText = NSAttributedString(string: "RECHARGE COINS", attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x7B7E77),
            .kern: 1.8
        ])
        navTitleLabel.textAlignment = .center
        navDivider.backgroundColor = UIColor(hex: 0xE1E0D9)
        [backButton, navTitleLabel].forEach { topBar.addSubview($0) }

        titleLabel.text = "Get more Coins"
        titleLabel.font = .systemFont(ofSize: 29, weight: .bold)
        titleLabel.textColor = AppTheme.ink

        balanceCard.layer.cornerRadius = 21
        balanceCard.layer.masksToBounds = true
        balanceGradient.colors = [UIColor(hex: 0xD9FF3F).cgColor, UIColor(hex: 0xEFFFB1).cgColor]
        balanceGradient.startPoint = CGPoint(x: 0, y: 0.5)
        balanceGradient.endPoint = CGPoint(x: 1, y: 0.5)
        balanceCard.layer.insertSublayer(balanceGradient, at: 0)
        balanceCaption.attributedText = NSAttributedString(string: "CURRENT BALANCE", attributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor(hex: 0x56602D),
            .kern: 1.4
        ])
        balanceValue.font = .systemFont(ofSize: 36, weight: .bold)
        balanceValue.textColor = AppTheme.ink
        balanceValue.text = "\(CurrencyManager.shared.coins) Coins"
        refreshButton.setTitle("Refresh balance", for: .normal)
        refreshButton.setTitleColor(UIColor(hex: 0x56602D), for: .normal)
        refreshButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
        refreshButton.backgroundColor = UIColor.white.withAlphaComponent(0.82)
        refreshButton.layer.cornerRadius = 15
        refreshButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        refreshButton.addAction(UIAction { [weak self] _ in self?.refreshBalance() }, for: .touchUpInside)
        coinImage.contentMode = .scaleAspectFit
        coinImage.clipsToBounds = true
        balanceCard.addSubview(balanceCaption)
        balanceCard.addSubview(balanceValue)
        balanceCard.addSubview(refreshButton)
        balanceCard.addSubview(coinImage)

        usageTitle.text = "Coins can be used for"
        usageTitle.font = AppFont.section()
        usageTitle.textColor = AppTheme.ink
        configureUsageCard()

        packageTitle.text = "Choose a package"
        packageTitle.font = AppFont.section()
        packageTitle.textColor = AppTheme.ink

        productsCollectionView.backgroundColor = .clear
        productsCollectionView.isScrollEnabled = false
        productsCollectionView.showsVerticalScrollIndicator = false
        productsCollectionView.contentInset = .zero
        productsCollectionView.dataSource = self
        productsCollectionView.delegate = self
        productsCollectionView.register(CoinPackCell.self, forCellWithReuseIdentifier: CoinPackCell.reuseIdentifier)
        contentScrollView.alwaysBounceVertical = true
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.backgroundColor = .clear
        contentScrollView.contentInsetAdjustmentBehavior = .never
        contentScrollView.addSubview(scrollContentView)
        [titleLabel, balanceCard, usageTitle, usageCard, packageTitle, productsCollectionView].forEach { scrollContentView.addSubview($0) }
        view.addSubview(topBar)
        view.addSubview(navDivider)
        view.addSubview(contentScrollView)

        purchaseBar.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        purchaseBar.layer.cornerRadius = 22
        purchaseBar.layer.shadowColor = UIColor.black.cgColor
        purchaseBar.layer.shadowOpacity = 0.10
        purchaseBar.layer.shadowRadius = 16
        purchaseBar.layer.shadowOffset = CGSize(width: 0, height: 5)
        purchaseButton.backgroundColor = AppTheme.ink
        purchaseButton.setTitleColor(.white, for: .normal)
        purchaseButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        purchaseButton.layer.cornerRadius = 17
        purchaseButton.addAction(UIAction { [weak self] _ in self?.purchaseSelectedProduct() }, for: .touchUpInside)
        purchaseBar.addSubview(purchaseButton)
        view.addSubview(purchaseBar)

        purchaseLoading.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        purchaseIndicator.color = .white
        purchaseLoading.addSubview(purchaseIndicator)
        purchaseLoading.isHidden = true
        view.addSubview(purchaseLoading)
    }

    private func configureUsageCard() {
        usageCard.backgroundColor = .white
        usageCard.layer.cornerRadius = 18
        usageCard.layer.borderWidth = 1
        usageCard.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        usageCard.layer.masksToBounds = true
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        usageCard.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        let paidCount = ContentManager.shared.paidPrompts().count
        let promptCost = ContentManager.shared.paidPrompts().map(\.costAmount).min() ?? 0
        let rows = [
            "Choose one from the \(paidCount) prompts: \(promptCost) Coins",
            "Yorva AI additional question: \(ChatManager.shared.yorvaAICostPerQuestion) coins per question"
        ]
        for (index, text) in rows.enumerated() {
            let row = UIView()
            let dot = UIView()
            dot.backgroundColor = UIColor(hex: 0xCFFF26)
            dot.layer.cornerRadius = 7
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 12, weight: .regular)
            label.textColor = AppTheme.ink
            row.addSubview(dot)
            row.addSubview(label)
            dot.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
                make.size.equalTo(14)
            }
            label.snp.makeConstraints { make in
                make.left.equalTo(dot.snp.right).offset(10)
                make.right.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
            }
            stack.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(46) }
            if index == 0 {
                let divider = UIView()
                divider.backgroundColor = UIColor(hex: 0xE8E6DF)
                row.addSubview(divider)
                divider.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.height.equalTo(1)
                }
            }
        }
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
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(17)
        }
        balanceCard.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(152)
        }
        balanceCaption.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(22)
        }
        balanceValue.snp.makeConstraints { make in
            make.left.equalTo(balanceCaption)
            make.top.equalTo(balanceCaption.snp.bottom).offset(10)
            make.right.lessThanOrEqualTo(coinImage.snp.left).offset(-4)
        }
        refreshButton.snp.makeConstraints { make in
            make.left.equalTo(balanceCaption)
            make.top.equalTo(balanceValue.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        coinImage.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(125)
        }
        usageTitle.snp.makeConstraints { make in
            make.top.equalTo(balanceCard.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(17)
        }
        usageCard.snp.makeConstraints { make in
            make.top.equalTo(usageTitle.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(92)
        }
        packageTitle.snp.makeConstraints { make in
            make.top.equalTo(usageCard.snp.bottom).offset(18)
            make.left.right.equalTo(usageCard)
        }
        productsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(packageTitle.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(17)
            productsCollectionHeightConstraint = make.height.equalTo(101).constraint
            make.bottom.equalToSuperview().offset(-16)
        }
        contentScrollView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(purchaseBar.snp.top).offset(-4)
        }
        scrollContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(contentScrollView.snp.width)
        }
        purchaseBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.height.equalTo(66)
        }
        purchaseButton.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        }
        purchaseLoading.snp.makeConstraints { $0.edges.equalToSuperview() }
        purchaseIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    private func loadProducts() {
        loadingView.state = .loading
        loadingView.show(in: view)
        StoreKitManager.shared.requestProducts()
    }

    private func refreshBalance() {
        updateBalanceLabel()
        Toast.show("Balance refreshed")
    }

    private func updateBalanceLabel() {
        balanceValue.text = "\(CurrencyManager.shared.coins) Coins"
    }

    private func purchaseSelectedProduct() {
        guard let productId = selectedProductId else {
            Toast.show("Choose a package first")
            return
        }
        StoreKitManager.shared.purchase(productId: productId)
    }

    private func updatePurchaseButton() {
        guard let selected = products.first(where: { $0.productId == selectedProductId }) else {
            purchaseButton.setTitle("Choose a package", for: .normal)
            return
        }
        purchaseButton.setTitle("Buy \(selected.title) · \(Self.usdPrice(selected.priceUSD))", for: .normal)
    }

    private static func usdPrice(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    // MARK: - StoreKitManagerDelegate

    func storeKitDidUpdateProducts(_ products: [WalletProduct]) {
        self.products = products
        if selectedProductId == nil || !products.contains(where: { $0.productId == selectedProductId }) {
            selectedProductId = products.dropFirst().first?.productId ?? products.first?.productId
        }
        loadingView.hide()
        let rowCount = max(1, Int(ceil(Double(products.count) / 2.0)))
        productsCollectionHeightConstraint?.update(offset: CGFloat(rowCount * 101 + max(0, rowCount - 1) * 8))
        productsCollectionView.reloadData()
        updatePurchaseButton()
    }

    func storeKitPurchaseDidSucceed(_ product: WalletProduct, coinsGained: Int) {
        CurrencyManager.shared.topUp(coins: coinsGained)
        balanceValue.text = "\(CurrencyManager.shared.coins) Coins"
        hidePurchaseLoading()
        Toast.show("Added \(coinsGained) Coins")
    }

    func storeKitPurchaseDidFail(_ error: String) {
        hidePurchaseLoading()
        Toast.show("Purchase failed. Please try again.")
    }

    func storeKitPurchaseDidCancel() {
        hidePurchaseLoading()
        Toast.show("Purchase cancelled")
    }

    func storeKitPurchaseStateChanged(_ isPurchasing: Bool) {
        if isPurchasing { showPurchaseLoading() } else { hidePurchaseLoading() }
    }

    private func showPurchaseLoading() {
        purchaseLoading.isHidden = false
        purchaseIndicator.startAnimating()
        view.bringSubviewToFront(purchaseLoading)
    }

    private func hidePurchaseLoading() {
        purchaseIndicator.stopAnimating()
        purchaseLoading.isHidden = true
    }
}

extension RechargeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { products.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CoinPackCell.reuseIdentifier, for: indexPath) as! CoinPackCell
        let product = products[indexPath.item]
        cell.configure(product: product, selected: product.productId == selectedProductId)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedProductId = products[indexPath.item].productId
        collectionView.reloadData()
        updatePurchaseButton()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 8) / 2)
        return CGSize(width: width, height: 101)
    }
}

final class CoinPackCell: UICollectionViewCell {
    static let reuseIdentifier = "CoinPackCell"

    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let valueLabel = UILabel()
    private let coinImage = UIImageView(image: UIImage(named: "coin"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        contentView.layer.masksToBounds = true
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppTheme.ink
        priceLabel.font = .systemFont(ofSize: 11, weight: .regular)
        priceLabel.textColor = UIColor(hex: 0x7B7E77)
        valueLabel.font = .systemFont(ofSize: 9, weight: .regular)
        valueLabel.textColor = UIColor(hex: 0x7B7E77)
        coinImage.contentMode = .scaleAspectFit
        [titleLabel, priceLabel, valueLabel, coinImage].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(25)
            make.right.lessThanOrEqualTo(coinImage.snp.left).offset(-3)
        }
        priceLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        valueLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-8)
        }
        coinImage.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-7)
            make.centerY.equalToSuperview()
            make.size.equalTo(68)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(product: WalletProduct, selected: Bool) {
        titleLabel.text = product.title.replacingOccurrences(of: " Coins", with: "")
        priceLabel.text = String(format: "$%.2f", product.priceUSD)
        valueLabel.text = product.priceUSD >= 19.99 ? "Best value" : nil
        contentView.backgroundColor = selected ? UIColor(hex: 0xBDEFF1) : .white
        contentView.layer.borderColor = (selected ? UIColor(hex: 0xBDEFF1) : UIColor(hex: 0xE1E0D9)).cgColor
    }
}
