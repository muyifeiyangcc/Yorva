//
//  SceneDelegate.swift
//  Yorva
//
//  替换 storyboard 自动绑定：以代码创建 UIWindow 并交给 RootCoordinator 决策首启路由
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let win = UIWindow(windowScene: windowScene)
        win.backgroundColor = AppTheme.bgSplash
        self.window = win
        win.makeKeyAndVisible()
        RootCoordinator.shared.attach(window: win)
    }
}
