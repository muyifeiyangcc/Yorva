//
//  EULAStore.swift
//  Yorva
//
//  EULA 同意状态持久化（铁律 1）
//  仅首次生效：写入后终身不再弹出
//

import Foundation

enum EULAStore {
    private static let key = "yorva.eula.agreed.v1"

    /// 是否已同意 EULA（首次启动为 false）
    static var hasAgreed: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    /// 用户点击「同意」时调用：永久写入本地，后续重启 / 切换账号均不再弹出
    static func agree() {
        UserDefaults.standard.set(true, forKey: key)
        UserDefaults.standard.synchronize()
    }

    /// 调试或重置场景；线上禁止调用（铁律：仅首次生效）
    static func _debugReset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
