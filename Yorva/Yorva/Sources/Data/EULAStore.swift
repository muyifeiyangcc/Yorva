//
//  EULAStore.swift
//  Yorva
//
//

import Foundation

enum EULAStore {
    private static let key = "yorva.eula.agreed.v1"

    static var hasAgreed: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func agree() {
        UserDefaults.standard.set(true, forKey: key)
        UserDefaults.standard.synchronize()
    }

    static func _debugReset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
