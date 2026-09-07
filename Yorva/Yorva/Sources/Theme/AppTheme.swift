//
//  AppTheme.swift
//  Yorva
//
//  主题色 / 业务色 / 背景色 / 文字色统一常量
//  来源：docs/ios-design-spec.md 第 5 章
//

import UIKit

enum AppTheme {
    // MARK: - Primary 主色
    static let primary         = UIColor(hex: 0xC25B3F)
    static let primaryPressed  = UIColor(hex: 0xA84A30)
    static let primaryDisabled = UIColor(hex: 0xE0B5A6)

    // MARK: - Secondary 辅助
    static let olive  = UIColor(hex: 0x2F3E2C)
    static let cream  = UIColor(hex: 0xF1E7D4)
    static let ink    = UIColor(hex: 0x1A1A1A)
    static let stone  = UIColor(hex: 0x9A9A9A)

    // MARK: - Semantic 业务语义
    static let coins       = UIColor(hex: 0xE0A458)
    static let coinsBg     = UIColor(hex: 0xFBF1DF)
    static let diamonds    = UIColor(hex: 0x5B8DBE)
    static let diamondsBg  = UIColor(hex: 0xE7EFF7)
    static let success     = UIColor(hex: 0x2E7D52)
    static let warning     = UIColor(hex: 0xD89B2E)
    static let error       = UIColor(hex: 0xC0392B)
    static let link        = UIColor(hex: 0x1F6FB2)
    static let linkPressed = UIColor(hex: 0x185A91)
    static let selectionBg = UIColor(hex: 0xFBE9DF)
    static let divider     = UIColor(hex: 0xE8E4DD)
    static let overlay      = UIColor.black.withAlphaComponent(0.4)

    // MARK: - Background 页面背景
    static let bgSplash   = UIColor(hex: 0xF5EFE6)
    static let bgRoot     = UIColor(hex: 0xFAF7F2)
    static let bgPrimary  = UIColor(hex: 0xFFFFFF)
    static let bgChat     = UIColor(hex: 0xF2EFEA)
    static let bgAI       = UIColor(hex: 0xF7F4EF)
    static let bgSettings = UIColor(hex: 0xF2EFEA)
    static let bgRecharge = UIColor(hex: 0xF5F2EC)
    static let bgSheet    = UIColor.white

    // MARK: - Semantic text colors
    static let textPrimary   = ink
    static let textSecondary = UIColor(hex: 0x5C5C5C)
    static let textTertiary  = stone
    static let textOnPrimary = UIColor.white
    static let textLink      = link
    static let textBrand     = primary
    static let textError     = error
    static let textCoins     = coins
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >>  8) & 0xFF) / 255.0,
            blue:  CGFloat( hex        & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}
