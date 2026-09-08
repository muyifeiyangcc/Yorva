//
//  SceneDelegate.swift
//  Yorva
//
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
