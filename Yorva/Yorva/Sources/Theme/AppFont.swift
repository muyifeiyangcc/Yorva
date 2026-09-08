//
//  AppFont.swift
//  Yorva
//
//

import UIKit

enum AppFont {
    static func splash(_ size: CGFloat = 30) -> UIFont {
        .systemFont(ofSize: size, weight: .semibold)
    }
    static func largeTitle()         -> UIFont { .systemFont(ofSize: 28, weight: .semibold) }
    static func navTitle()           -> UIFont { .systemFont(ofSize: 17, weight: .semibold) }
    static func section()            -> UIFont { .systemFont(ofSize: 20, weight: .semibold) }
    static func cardTitle()          -> UIFont { .systemFont(ofSize: 16, weight: .medium) }
    static func cardTitleSemibold() -> UIFont { .systemFont(ofSize: 16, weight: .semibold) }
    static func body()               -> UIFont { .systemFont(ofSize: 15, weight: .regular) }
    static func bodySecondary()      -> UIFont { .systemFont(ofSize: 14, weight: .regular) }
    static func bodyTertiary()       -> UIFont { .systemFont(ofSize: 13, weight: .regular) }
    static func caption()            -> UIFont { .systemFont(ofSize: 12, weight: .regular) }
    static func captionStrong()     -> UIFont { .systemFont(ofSize: 12, weight: .medium) }
    static func micro()              -> UIFont { .systemFont(ofSize: 10, weight: .medium) }
    static func statNumber()         -> UIFont { .systemFont(ofSize: 18, weight: .semibold) }
    static func coinNumber() -> UIFont {
        UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)
    }
    static func coinNumberSmall() -> UIFont {
        UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
    }
    static func buttonPrimary()   -> UIFont { .systemFont(ofSize: 16, weight: .semibold) }
    static func buttonSecondary() -> UIFont { .systemFont(ofSize: 15, weight: .medium) }
    static func buttonTextLink()  -> UIFont { .systemFont(ofSize: 15, weight: .medium) }
    static func buttonDestructive() -> UIFont { .systemFont(ofSize: 16, weight: .semibold) }
    static func textFieldInput()  -> UIFont { .systemFont(ofSize: 16, weight: .regular) }
    static func textFieldError()  -> UIFont { .systemFont(ofSize: 12, weight: .regular) }
    static func chatBubble()      -> UIFont { .systemFont(ofSize: 15, weight: .regular) }
    static func voiceDuration() -> UIFont {
        UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    }
    static func emptyTitle()    -> UIFont { .systemFont(ofSize: 16, weight: .medium) }
    static func emptySubtitle() -> UIFont { .systemFont(ofSize: 13, weight: .regular) }
    static func toast()         -> UIFont { .systemFont(ofSize: 14, weight: .medium) }
    static func eulaTitle()     -> UIFont { .systemFont(ofSize: 18, weight: .semibold) }
    static func eulaBody()      -> UIFont { .systemFont(ofSize: 14, weight: .regular) }
    static func sheetItem()     -> UIFont { .systemFont(ofSize: 16, weight: .medium) }
    static func reportOption()          -> UIFont { .systemFont(ofSize: 15, weight: .regular) }
    static func reportOptionSelected()  -> UIFont { .systemFont(ofSize: 15, weight: .medium) }
}
