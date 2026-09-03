//
//  RechargeViewController.swift
//  Yorva
//
//  充值 Coins（铁律 9）
//  - 商品类型固定为消耗型商品
//  - 强制使用 StoreKit V1 (SKPaymentQueue)，禁止 StoreKit 2
//  - 商品列表动态渲染（根据当前环境有效内购产品自动生成列表）
//  - 价格统一固定展示美元标价，不使用 SKProduct.priceLocale
//  - 购买流程关键节点添加加载动画
//  - 凭证不做服务端校验，仅以本地回调的成功状态判定订单生效
//

import UIKit
import SnapKit

final class RechargeViewController: BaseViewController, StoreKitManagerDelegate {

    override var pageBackgroundColor: UIColor { AppTheme.bgRecharge }
    override var isSecondaryLevel: Bool { true }

    private let balanceBanner = UIView()
    private let balanceTitleLabel = UILabel()
    private let balanceValueLabel = UILabel()
    private let usageLabel = UILabel()
    private let productsTableView = UITableView(frame: .zero, style: .insetGrouped)
    private let loadingView = LoadingView()
    private let purchaseLoading = UIView()
    private let purchaseIndicator = UIActivityIndicatorView(style: .large)

    private var products: [WalletProduct] = []
    private var didLoadProducts = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Recharge"
        StoreKitManager.shared.delegate = self
        setupHierarchy()
        applyAutoLayoutConstraints()
        loadProducts()
    }

    override func setupHierarchy() {
        balanceBanner.backgroundColor = AppTheme.coinsBg
        balanceBanner.layer.cornerRadius = 12
        balanceBanner.layer.masksToBounds = true
        balanceTitleLabel.font = AppFont.captionStrong()
        balanceTitleLabel.textColor = AppTheme.textSecondary
        balanceTitleLabel.text = "Coins balance"
        balanceValueLabel.font = AppFont.coinNumber()
        balanceValueLabel.textColor = AppTheme.textCoins
        balanceValueLabel.text = "\(CurrencyManager.shared.coins)"
        usageLabel.font = AppFont.bodySecondary()
        usageLabel.textColor = AppTheme.textSecondary
        usageLabel.numberOfLines = 0
        usageLabel.text = "Use Coins to unlock paid prompts and ask Yorva AI questions."
        [balanceTitleLabel, balanceValueLabel, usageLabel].forEach { balanceBanner.addSubview($0) }
        view.addSubview(balanceBanner)

        productsTableView.dataSource = self
        productsTableView.delegate = self
        productsTableView.backgroundColor = .clear
        productsTableView.register(CoinPackCell.self, forCellReuseIdentifier: CoinPackCell.reuseIdentifier)
        productsTableView.estimatedRowHeight = 64
        productsTableView.rowHeight = UITableView.automaticDimension
        view.addSubview(productsTableView)

        purchaseLoading.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        purchaseIndicator.color = .white
        purchaseLoading.addSubview(purchaseIndicator)
        purchaseLoading.isHidden = true
        view.addSubview(purchaseLoading)
    }

    override func applyAutoLayoutConstraints() {
        balanceBanner.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(90)
        }
        balanceTitleLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(12)
        }
        balanceValueLabel.snp.makeConstraints { make in
            make.left.equalTo(balanceTitleLabel)
            make.top.equalTo(balanceTitleLabel.snp.bottom).offset(2)
        }
        usageLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-8)
        }
        productsTableView.snp.makeConstraints { make in
            make.top.equalTo(balanceBanner.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
        purchaseLoading.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        purchaseIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func loadProducts() {
        loadingView.state = .loading
        loadingView.show(in: view)
        StoreKitManager.shared.requestProducts()
    }

    // MARK: - StoreKitManagerDelegate

    func storeKitDidUpdateProducts(_ products: [WalletProduct]) {
        didLoadProducts = true
        self.products = products
        loadingView.hide()
        productsTableView.reloadData()
    }

    func storeKitPurchaseDidSucceed(_ product: WalletProduct, coinsGained: Int) {
        CurrencyManager.shared.topUp(coins: coinsGained)
        balanceValueLabel.text = "\(CurrencyManager.shared.coins)"
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

extension RechargeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { products.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CoinPackCell.reuseIdentifier, for: indexPath) as! CoinPackCell
        let product = products[indexPath.row]
        cell.configure(product: product)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let product = products[indexPath.row]
        // 购买流程关键节点加载动画 + 触发 StoreKit V1 购买流程
        StoreKitManager.shared.purchase(productId: product.productId)
    }
}

final class CoinPackCell: UITableViewCell {
    static let reuseIdentifier = "CoinPackCell"
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let buyButton = PrimaryButton(title: "Buy")
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        contentView.backgroundColor = AppTheme.bgPrimary
        titleLabel.font = AppFont.cardTitle()
        titleLabel.textColor = AppTheme.ink
        priceLabel.font = AppFont.coinNumberSmall()
        priceLabel.textColor = AppTheme.textCoins
        buyButton.layer.cornerRadius = 18
        [titleLabel, priceLabel, buyButton].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(priceLabel.snp.left).offset(-8)
        }
        priceLabel.snp.makeConstraints { make in
            make.right.equalTo(buyButton.snp.left).offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
        }
        buyButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
            make.width.equalTo(80)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(product: WalletProduct) {
        titleLabel.text = product.title
        // 价格展示规则：固定美元标价，不使用 SKProduct.priceLocale
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        priceLabel.text = formatter.string(from: NSNumber(value: product.priceUSD)) ?? "$\(product.priceUSD)"
    }
}
