//
//  RootCoordinator.swift
//  Yorva
//
//  应用根协调器：根据 EULA 同意状态 + 账号状态决定首启入口
//  铁律 1（EULA）+ 铁律 2（游客）+ 铁律 5（TabBar 仅根页）
//

import UIKit

final class RootCoordinator {

    static let shared = RootCoordinator()

    private(set) var window: UIWindow?
    private(set) var mainTabBarController: MainTabBarController?

    func attach(window: UIWindow) {
        self.window = window
        routeInitial()
    }

    /// 首启路由：未同意 EULA → 弹 EULA；同意但无有效账号 → 登录入口；有效账号 → 主页
    func routeInitial() {
        guard let window = window else { return }
        if !EULAStore.hasAgreed {
            showSplashWithEULA(in: window)
        } else if let _ = AccountManager.shared.currentUser {
            showMainFlow(in: window)
        } else {
            showAuthFlow(in: window)
        }
    }

    private func showSplashWithEULA(in window: UIWindow) {
        let splash = SplashViewController()
        splash.onFinished = { [weak self] in
            // Splash 过渡完成后弹出 EULA
            self?.presentEULA()
        }
        let nav = BaseNavigationController(rootViewController: splash)
        nav.setNavigationBarHidden(true, animated: false)
        window.rootViewController = nav
    }

    private func presentEULA() {
        guard let host = window?.rootViewController else { return }
        let eula = EULAViewController()
        eula.modalPresentationStyle = .overFullScreen
        eula.modalTransitionStyle = .crossDissolve
        eula.onAgree = { [weak self] in
            // 同意 EULA 后路由到下一阶段：有账号进主页，无账号进登录
            guard let self = self else { return }
            if let _ = AccountManager.shared.currentUser {
                self.showMainFlow(in: self.window!)
            } else {
                self.showAuthFlow(in: self.window!)
            }
        }
        eula.onCancel = {
            // 铁律 1：Cancel 直接退出 App，不进入任何页面
            exit(0)
        }
        host.present(eula, animated: true)
    }

    func showAuthFlow(in window: UIWindow) {
        let login = LoginEntryViewController()
        let nav = BaseNavigationController(rootViewController: login)
        nav.setNavigationBarHidden(true, animated: false)
        window.rootViewController = nav
    }

    func showMainFlow(in window: UIWindow) {
        let tab = MainTabBarController()
        mainTabBarController = tab
        window.rootViewController = tab
    }

    /// 退出登录后回到登录入口
    func routeToAuth() {
        guard let window = window else { return }
        showAuthFlow(in: window)
    }

    /// 游客进入主页（铁律 2）
    func routeGuestToMain() {
        AccountManager.shared.enterGuestMode()
        guard let window = window else { return }
        showMainFlow(in: window)
    }
}
