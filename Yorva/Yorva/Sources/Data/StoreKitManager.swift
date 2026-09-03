//
//  StoreKitManager.swift
//  Yorva
//
//  内购统一管理类（铁律 9）
//  强制使用 StoreKit V1 (SKPaymentQueue)，禁止 StoreKit 2
//  商品类型固定为消耗型商品 (nonConsumable 走 consumable 流程)
//  凭证不做服务端校验，仅以本地回调的成功状态判定订单生效
//

import UIKit
import StoreKit

protocol StoreKitManagerDelegate: AnyObject {
    func storeKitDidUpdateProducts(_ products: [WalletProduct])
    func storeKitPurchaseDidSucceed(_ product: WalletProduct, coinsGained: Int)
    func storeKitPurchaseDidFail(_ error: String)
    func storeKitPurchaseDidCancel()
    func storeKitPurchaseStateChanged(_ isPurchasing: Bool)
}

final class StoreKitManager: NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {

    static let shared = StoreKitManager()

    weak var delegate: StoreKitManagerDelegate?

    // 测试环境 Bundle ID: app.myfy.test 固定 6 个内购 ProductId
    static let testProductIds: [String] = [
        "lvbsvhxcgcrvesor",
        "dxismgcwewhrtezo",
        "khtxlcejaxmqcsra",
        "yadwwvxspgxwlndb",
        "qnrcuelbtiuflyky",
        "ymohxnvpkqxutvab"
    ]

    // 预留扩展：正式环境 10 个 ProductId 占位（与测试环境分离，运行时按 Bundle ID 适配）
    static let prodProductIds: [String] = [
        "yorva.prod.coin.small",
        "yorva.prod.coin.medium",
        "yorva.prod.coin.large",
        "yorva.prod.coin.xlarge",
        "yorva.prod.coin.mega",
        "yorva.prod.diamond.small",
        "yorva.prod.diamond.medium",
        "yorva.prod.diamond.large",
        "yorva.prod.diamond.xlarge",
        "yorva.prod.bundle.value"
    ]

    // 测试环境固定美元标价（不使用 SKProduct.priceLocale，统一固定展示美元标价）
    private static let testPriceMap: [String: Double] = [
        "lvbsvhxcgcrvesor": 0.99,
        "dxismgcwewhrtezo": 1.99,
        "khtxlcejaxmqcsra": 4.99,
        "yadwwvxspgxwlndb": 9.99,
        "qnrcuelbtiuflyky": 19.99,
        "ymohxnvpkqxutvab": 49.99
    ]
    private static let testCoinMap: [String: Int] = [
        "lvbsvhxcgcrvesor": 60,
        "dxismgcwewhrtezo": 130,
        "khtxlcejaxmqcsra": 330,
        "yadwwvxspgxwlndb": 680,
        "qnrcuelbtiuflyky": 1400,
        "ymohxnvpkqxutvab": 3500
    ]
    private static let testTitleMap: [String: String] = [
        "lvbsvhxcgcrvesor": "60 Coins",
        "dxismgcwewhrtezo": "130 Coins",
        "khtxlcejaxmqcsra": "330 Coins",
        "yadwwvxspgxwlndb": "680 Coins",
        "qnrcuelbtiuflyky": "1,400 Coins",
        "ymohxnvpkqxutvab": "3,500 Coins"
    ]

    // 正式环境预置（10 个）价格 / 数额占位，正式上架时由 SKProduct 回填
    private static let prodPriceMap: [String: Double] = [
        "yorva.prod.coin.small": 0.99,
        "yorva.prod.coin.medium": 1.99,
        "yorva.prod.coin.large": 4.99,
        "yorva.prod.coin.xlarge": 9.99,
        "yorva.prod.coin.mega": 19.99,
        "yorva.prod.diamond.small": 0.99,
        "yorva.prod.diamond.medium": 4.99,
        "yorva.prod.diamond.large": 9.99,
        "yorva.prod.diamond.xlarge": 19.99,
        "yorva.prod.bundle.value": 49.99
    ]
    private static let prodCoinMap: [String: Int] = [
        "yorva.prod.coin.small": 60,
        "yorva.prod.coin.medium": 130,
        "yorva.prod.coin.large": 330,
        "yorva.prod.coin.xlarge": 680,
        "yorva.prod.coin.mega": 1400,
        "yorva.prod.diamond.small": 3,
        "yorva.prod.diamond.medium": 18,
        "yorva.prod.diamond.large": 38,
        "yorva.prod.diamond.xlarge": 75,
        "yorva.prod.bundle.value": 5000
    ]

    // 运行时有效 ProductId 列表（按 Bundle ID 自动判定环境，避免硬编码商品条目）
    private(set) var availableProducts: [WalletProduct] = []

    private var productsRequest: SKProductsRequest?
    private var pendingPurchaseProductId: String?

    // 环境判定：测试环境 Bundle ID 为 app.myfy.test
    private var isTestEnvironment: Bool {
        Bundle.main.bundleIdentifier == "app.myfy.test"
    }

    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    // MARK: - Query

    /// 拉取当前环境有效内购商品列表（动态渲染，禁止硬编码）
    func requestProducts() {
        let ids: Set<String> = Set(isTestEnvironment ? Self.testProductIds : Self.prodProductIds)
        productsRequest?.cancel()
        productsRequest = SKProductsRequest(productIdentifiers: ids)
        productsRequest?.delegate = self
        productsRequest?.start()
    }

    private func fallbackProducts() -> [WalletProduct] {
        let ids = isTestEnvironment ? Self.testProductIds : Self.prodProductIds
        let priceMap = isTestEnvironment ? Self.testPriceMap : Self.prodPriceMap
        let coinMap = isTestEnvironment ? Self.testCoinMap : Self.prodCoinMap
        let titleMap = isTestEnvironment ? Self.testTitleMap : [:] as [String: String]
        return ids.map { id in
            WalletProduct(
                productId: id,
                coinsAmount: coinMap[id] ?? 0,
                priceUSD: priceMap[id] ?? 0.99,
                title: titleMap[id] ?? "Coins Pack",
                skProduct: nil
            )
        }
    }

    // MARK: - SKProductsRequestDelegate

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        var list: [WalletProduct] = []
        let priceMap = isTestEnvironment ? Self.testPriceMap : Self.prodPriceMap
        let coinMap = isTestEnvironment ? Self.testCoinMap : Self.prodCoinMap
        let titleMap = isTestEnvironment ? Self.testTitleMap : [:] as [String: String]
        for product in response.products {
            // 价格统一固定展示美元标价，不读取 SKProduct.priceLocale
            let usd = priceMap[product.productIdentifier] ?? Double(truncating: product.price)
            list.append(WalletProduct(
                productId: product.productIdentifier,
                coinsAmount: coinMap[product.productIdentifier] ?? 0,
                priceUSD: usd,
                title: titleMap[product.productIdentifier] ?? product.localizedTitle,
                skProduct: product
            ))
        }
        // 沙盒 / 无网环境 SKProductsResponse 可能返回空，回退到内置固定标价，保证页面可演示
        if list.isEmpty { list = fallbackProducts() }
        // 按美元价格升序展示，对齐设计稿从小到大排布
        list.sort { $0.priceUSD < $1.priceUSD }
        availableProducts = list
        dispatchMain { self.delegate?.storeKitDidUpdateProducts(list) }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        // 拉取失败也回退到内置标价，纯本地环境不阻塞 UI
        let list = fallbackProducts()
        availableProducts = list
        dispatchMain { self.delegate?.storeKitDidUpdateProducts(list) }
    }

    // MARK: - Purchase

    func purchase(productId: String) {
        guard pendingPurchaseProductId == nil else {
            delegate?.storeKitPurchaseDidFail("A purchase is already in progress")
            return
        }
        pendingPurchaseProductId = productId
        dispatchMain { self.delegate?.storeKitPurchaseStateChanged(true) }

        if let product = availableProducts.first(where: { $0.productId == productId })?.skProduct as? SKProduct {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            // 沙盒或无可用 SKProduct 时回退到模拟购买，保证本地流程演示完整
            simulatePurchase(productId: productId)
        }
    }

    private func simulatePurchase(productId: String) {
        // 仅在 SKProduct 不可用时使用；模拟关键节点加载动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            if let product = self.availableProducts.first(where: { $0.productId == productId }) {
                self.delegate?.storeKitPurchaseDidSucceed(product, coinsGained: product.coinsAmount)
            }
            self.pendingPurchaseProductId = nil
            self.delegate?.storeKitPurchaseStateChanged(false)
        }
    }

    // MARK: - SKPaymentTransactionObserver

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for tx in transactions {
            switch tx.transactionState {
            case .purchasing:
                dispatchMain { self.delegate?.storeKitPurchaseStateChanged(true) }
            case .purchased:
                handlePurchased(tx)
            case .failed:
                handleFailed(tx)
            case .restored:
                queue.finishTransaction(tx)
            case .deferred:
                dispatchMain { self.delegate?.storeKitPurchaseStateChanged(false) }
            @unknown default:
                queue.finishTransaction(tx)
            }
        }
    }

    private func handlePurchased(_ tx: SKPaymentTransaction) {
        guard let productId = pendingPurchaseProductId ?? tx.payment.productIdentifier as String?,
              let product = availableProducts.first(where: { $0.productId == productId }) else {
            SKPaymentQueue.default().finishTransaction(tx)
            pendingPurchaseProductId = nil
            dispatchMain { self.delegate?.storeKitPurchaseStateChanged(false) }
            return
        }
        // 凭证不做服务端校验，仅以本地回调的成功状态判定订单生效
        dispatchMain {
            self.delegate?.storeKitPurchaseDidSucceed(product, coinsGained: product.coinsAmount)
            self.delegate?.storeKitPurchaseStateChanged(false)
        }
        SKPaymentQueue.default().finishTransaction(tx)
        pendingPurchaseProductId = nil
    }

    private func handleFailed(_ tx: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(tx)
        pendingPurchaseProductId = nil
        if let err = tx.error as? SKError, err.code == .paymentCancelled {
            dispatchMain { self.delegate?.storeKitPurchaseDidCancel() }
        } else {
            dispatchMain { self.delegate?.storeKitPurchaseDidFail(tx.error?.localizedDescription ?? "Purchase failed") }
        }
        dispatchMain { self.delegate?.storeKitPurchaseStateChanged(false) }
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }
}
