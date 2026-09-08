//
//  StoreKitManager.swift
//  Yorva
//
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

final class StoreKitManager: NSObject, @preconcurrency SKPaymentTransactionObserver, SKProductsRequestDelegate {

    static let shared = StoreKitManager()

    weak var delegate: StoreKitManagerDelegate?

    static let testProductIds: [String] = [
        "lvbsvhxcgcrvesor",
        "dxismgcwewhrtezo",
        "khtxlcejaxmqcsra",
        "yadwwvxspgxwlndb",
        "qnrcuelbtiuflyky",
        "ymohxnvpkqxutvab"
    ]

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

    private static let testPriceMap: [String: Double] = [
        "lvbsvhxcgcrvesor": 0.99,
        "dxismgcwewhrtezo": 1.99,
        "khtxlcejaxmqcsra": 4.99,
        "yadwwvxspgxwlndb": 9.99,
        "qnrcuelbtiuflyky": 12.99,
        "ymohxnvpkqxutvab": 19.99
    ]
    private static let testCoinMap: [String: Int] = [
        "lvbsvhxcgcrvesor": 400,
        "dxismgcwewhrtezo": 800,
        "khtxlcejaxmqcsra": 2450,
        "yadwwvxspgxwlndb": 5150,
        "qnrcuelbtiuflyky": 6400,
        "ymohxnvpkqxutvab": 10800
    ]
    private static let testTitleMap: [String: String] = [
        "lvbsvhxcgcrvesor": "400 Coins",
        "dxismgcwewhrtezo": "800 Coins",
        "khtxlcejaxmqcsra": "2,450 Coins",
        "yadwwvxspgxwlndb": "5,150 Coins",
        "qnrcuelbtiuflyky": "6,400 Coins",
        "ymohxnvpkqxutvab": "10,800 Coins"
    ]

    private static let prodPriceMap: [String: Double] = [
        "yorva.prod.coin.small": 0.99,
        "yorva.prod.coin.medium": 1.99,
        "yorva.prod.coin.large": 4.99,
        "yorva.prod.coin.xlarge": 9.99,
        "yorva.prod.coin.mega": 12.99,
        "yorva.prod.diamond.small": 19.99,
        "yorva.prod.diamond.medium": 24.99,
        "yorva.prod.diamond.large": 49.99,
        "yorva.prod.diamond.xlarge": 79.99,
        "yorva.prod.bundle.value": 99.99
    ]
    private static let prodCoinMap: [String: Int] = [
        "yorva.prod.coin.small": 400,
        "yorva.prod.coin.medium": 800,
        "yorva.prod.coin.large": 2450,
        "yorva.prod.coin.xlarge": 5150,
        "yorva.prod.coin.mega": 6400,
        "yorva.prod.diamond.small": 10800,
        "yorva.prod.diamond.medium": 14900,
        "yorva.prod.diamond.large": 29400,
        "yorva.prod.diamond.xlarge": 39500,
        "yorva.prod.bundle.value": 63700
    ]
    private static let prodTitleMap: [String: String] = [
        "yorva.prod.coin.small": "400 Coins",
        "yorva.prod.coin.medium": "800 Coins",
        "yorva.prod.coin.large": "2,450 Coins",
        "yorva.prod.coin.xlarge": "5,150 Coins",
        "yorva.prod.coin.mega": "6,400 Coins",
        "yorva.prod.diamond.small": "10,800 Coins",
        "yorva.prod.diamond.medium": "14,900 Coins",
        "yorva.prod.diamond.large": "29,400 Coins",
        "yorva.prod.diamond.xlarge": "39,500 Coins",
        "yorva.prod.bundle.value": "63,700 Coins"
    ]

    private(set) var availableProducts: [WalletProduct] = []

    private var productsRequest: SKProductsRequest?
    private var pendingPurchaseProductId: String?

    private var isTestEnvironment: Bool {
        Bundle.main.bundleIdentifier == "app.myfy.test"
    }

    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    // MARK: - Query

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
        let titleMap = isTestEnvironment ? Self.testTitleMap : Self.prodTitleMap
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
        let titleMap = isTestEnvironment ? Self.testTitleMap : Self.prodTitleMap
        for product in response.products {
            // Keep presentation in USD even when the App Store account locale differs.
            // Product identity is the source of truth for this fixed catalog.
            let usd = priceMap[product.productIdentifier] ?? 0.99
            list.append(WalletProduct(
                productId: product.productIdentifier,
                coinsAmount: coinMap[product.productIdentifier] ?? 0,
                priceUSD: usd,
                title: titleMap[product.productIdentifier] ?? product.localizedTitle,
                skProduct: product
            ))
        }
        if list.isEmpty { list = fallbackProducts() }
        list.sort { $0.priceUSD < $1.priceUSD }
        availableProducts = list
        dispatchMain { self.delegate?.storeKitDidUpdateProducts(list) }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
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
            simulatePurchase(productId: productId)
        }
    }

    private func simulatePurchase(productId: String) {
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
