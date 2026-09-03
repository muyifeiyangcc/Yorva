//
//  CurrencyManager.swift
//  Yorva
//
//  金币 / 钻石货币管理（铁律 6、铁律 9）
//  全部金币/钻石消耗场景执行扣费前必须先校验余额 + 弹窗确认（确认流程在页面侧）
//

import Foundation

final class CurrencyManager {

    static let shared = CurrencyManager()

    private init() {}

    var coins: Int { AccountManager.shared.currentUser?.coins ?? 0 }
    var diamonds: Int { AccountManager.shared.currentUser?.diamonds ?? 0 }

    /// 余额校验：不足直接返回 false，由页面弹「金币不足，请前往充值」
    func canAfford(amount: Int, type: CurrencyType = .coins) -> Bool {
        switch type {
        case .coins: return coins >= amount
        case .diamonds: return diamonds >= amount
        }
    }

    /// 执行扣费（仅当页面已弹出确认弹窗并用户确认后调用）
    func spend(amount: Int, type: CurrencyType = .coins) -> Bool {
        guard canAfford(amount: amount, type: type) else { return false }
        switch type {
        case .coins: AccountManager.shared.applyCurrencyChange(coins: -amount, diamonds: 0)
        case .diamonds: AccountManager.shared.applyCurrencyChange(coins: 0, diamonds: -amount)
        }
        return true
    }

    /// 内购充值成功后入账
    func topUp(coins: Int = 0, diamonds: Int = 0) {
        AccountManager.shared.applyCurrencyChange(coins: coins, diamonds: diamonds)
    }
}
