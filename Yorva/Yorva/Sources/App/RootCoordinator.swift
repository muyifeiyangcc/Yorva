//
//  RootCoordinator.swift
//  Yorva
//
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

    func routeInitial() {
        guard let window = window else { return }
        if !EULAStore.hasAgreed {
            showEULAHost(in: window)
        } else if let user = AccountManager.shared.currentUser {
            if AccountManager.shared.isProfileComplete(user) {
                showMainFlow(in: window)
            } else {
                showProfileCompletion(in: window)
            }
        } else {
            showAuthFlow(in: window)
        }
    }

    /// Present the required EULA without inserting an extra branded splash
    /// screen into the startup route.
    private func showEULAHost(in window: UIWindow) {
        let host = UIViewController()
        host.view.backgroundColor = AppTheme.bgSplash
        let nav = BaseNavigationController(rootViewController: host)
        nav.setNavigationBarHidden(true, animated: false)
        window.rootViewController = nav
        DispatchQueue.main.async { [weak self] in
            self?.presentEULA()
        }
    }

    private func presentEULA() {
        guard let host = window?.rootViewController else { return }
        let eula = EULAViewController()
        eula.modalPresentationStyle = .overFullScreen
        eula.modalTransitionStyle = .crossDissolve
        eula.onAgree = { [weak self] in
            guard let self = self else { return }
            if let user = AccountManager.shared.currentUser, AccountManager.shared.isProfileComplete(user) {
                self.showMainFlow(in: self.window!)
            } else if AccountManager.shared.currentUser != nil {
                self.showProfileCompletion(in: self.window!)
            } else {
                self.showAuthFlow(in: self.window!)
            }
        }
        eula.onCancel = {
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

    private func showProfileCompletion(in window: UIWindow) {
        let controller = CompleteProfileViewController()
        let nav = BaseNavigationController(rootViewController: controller)
        nav.setNavigationBarHidden(true, animated: false)
        window.rootViewController = nav
    }

    func showMainFlow(in window: UIWindow) {
        let tab = MainTabBarController()
        mainTabBarController = tab
        window.rootViewController = tab
    }

    func routeToAuth() {
        guard let window = window else { return }
        showAuthFlow(in: window)
    }

    func routeGuestToMain() {
        AccountManager.shared.enterGuestMode()
        guard let window = window else { return }
        showMainFlow(in: window)
    }
}
