//
//  AppDelegate.swift
//  Yorva
//
//  替换原 storyboard 模板：注入 IQKeyboardManagerSwift、初始化数据仓库
//

import UIKit
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 强制引入：IQKeyboardManagerSwift（统一处理键盘与输入框交互）
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistance = 12

        // 启动数据仓库（顺序：先用户，再内容/聊天，避免内容依赖用户为空）
        _ = DataRepository.shared
        _ = AccountManager.shared
        _ = ContentManager.shared
        _ = ChatManager.shared

        // 内购监听早绑定（铁律 9）
        _ = StoreKitManager.shared
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}
