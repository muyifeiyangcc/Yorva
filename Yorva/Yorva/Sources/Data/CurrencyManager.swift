//
//  CurrencyManager.swift
//  Yorva
//
//

import Foundation

final class CurrencyManager {

    static let shared = CurrencyManager()

    private init() {}

    var coins: Int { AccountManager.shared.currentUser?.coins ?? 0 }
    var diamonds: Int { AccountManager.shared.currentUser?.diamonds ?? 0 }

    func canAfford(amount: Int, type: CurrencyType = .coins) -> Bool {
        switch type {
        case .coins: return coins >= amount
        case .diamonds: return diamonds >= amount
        }
    }

    func spend(amount: Int, type: CurrencyType = .coins) -> Bool {
        guard canAfford(amount: amount, type: type) else { return false }
        switch type {
        case .coins: AccountManager.shared.applyCurrencyChange(coins: -amount, diamonds: 0)
        case .diamonds: AccountManager.shared.applyCurrencyChange(coins: 0, diamonds: -amount)
        }
        return true
    }

    func topUp(coins: Int = 0, diamonds: Int = 0) {
        AccountManager.shared.applyCurrencyChange(coins: coins, diamonds: diamonds)
    }
}
