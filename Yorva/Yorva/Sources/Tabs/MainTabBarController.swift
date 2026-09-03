//
//  MainTabBarController.swift
//  Yorva
//
//  四个 Tab 根页面 + 中央 + 发帖按钮
//  铁律 2：游客点击任意 Tab 都触发必须登录拦截
//  铁律 5：仅根页面显示 TabBar
//

import UIKit
import SnapKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.bgRoot
        delegate = self
        configureTabs()
        configureCenterButton()
        tabBar.backgroundColor = AppTheme.bgPrimary
        tabBar.tintColor = AppTheme.primary
        tabBar.unselectedItemTintColor = AppTheme.stone
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.05
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -1)
    }

    private func configureTabs() {
        let home = HomeViewController()
        home.tabBarItem = makeItem(title: "Home", symbol: "house")
        let explore = ExploreViewController()
        explore.tabBarItem = makeItem(title: "Explore", symbol: "safari")
        let chat = ChatListViewController()
        chat.tabBarItem = makeItem(title: "Chat", symbol: "bubble.left.and.bubble.right")
        let profile = ProfileViewController()
        profile.tabBarItem = makeItem(title: "Profile", symbol: "person")

        // 每个 Tab 独立导航栈，根页面隐藏返回按钮、显示 TabBar
        viewControllers = [
            BaseNavigationController(rootViewController: home),
            BaseNavigationController(rootViewController: explore),
            BaseNavigationController(rootViewController: chat),
            BaseNavigationController(rootViewController: profile)
        ]
        // 每个 Tab 根页面隐藏返回按钮（铁律 5：根页面展示 TabBar，二级页面隐藏）
        for nav in (viewControllers as? [UINavigationController] ?? []) {
            nav.delegate = self
            nav.navigationBar.prefersLargeTitles = false
        }
    }

    private func makeItem(title: String, symbol: String) -> UITabBarItem {
        let image = UIImage(systemName: symbol)?.withRenderingMode(.alwaysTemplate)
        let item = UITabBarItem(title: title, image: image, selectedImage: image)
        item.setTitleTextAttributes([.font: AppFont.micro(), .foregroundColor: AppTheme.stone], for: .normal)
        item.setTitleTextAttributes([.font: AppFont.micro(), .foregroundColor: AppTheme.primary], for: .selected)
        item.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
        item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)
        return item
    }

    // MARK: - 中央 + 发帖按钮

    private let centerButton = UIButton(type: .custom)

    private func configureCenterButton() {
        centerButton.backgroundColor = AppTheme.primary
        centerButton.layer.cornerRadius = 28
        centerButton.layer.masksToBounds = true
        centerButton.setImage(UIImage(systemName: "plus")?.withTintColor(.white, renderingMode: .alwaysOriginal),
                              for: .normal)
        centerButton.imageView?.contentMode = .scaleAspectFit
        tabBar.addSubview(centerButton)
        centerButton.snp.makeConstraints { make in
            make.centerX.equalTo(tabBar)
            make.centerY.equalTo(tabBar).offset(-12)
            make.size.equalTo(CGSize(width: 56, height: 56))
        }
        centerButton.addAction(UIAction { [weak self] _ in
            self?.handleCenterPostButton()
        }, for: .touchUpInside)
    }

    /// 中央 + 按钮：游客拦截（铁律 2）；登录态进入发帖-选 Prompt（铁律 13 push 跳转）
    private func handleCenterPostButton() {
        guard requiresLoginIfNeeded() else { return }
        let create = CreatePostSelectPromptViewController()
        navigationControllerForSelectedTab?.pushViewController(create, animated: true)
    }

    // MARK: - Delegate

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // 游客切换 Tab：拦截并弹必须登录弹窗（铁律 2）
        if AccountManager.shared.isGuest {
            presentGuestLoginRequired()
            return false
        }
        return true
    }

    /// 获取当前选中 Tab 对应导航栈
    var navigationControllerForSelectedTab: UINavigationController? {
        (selectedViewController as? UINavigationController)
    }

    // MARK: - 游客拦截（铁律 2）

    /// 触发任意游客操作时调用；返回 false 表示已被拦截
    @discardableResult
    func requiresLoginIfNeeded() -> Bool {
        if AccountManager.shared.isGuest {
            presentGuestLoginRequired()
            return false
        }
        return true
    }

    private func presentGuestLoginRequired() {
        let alert = UIAlertController(title: "Sign in required",
                                     message: "Please sign in to continue browsing Yorva.",
                                     preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sign in", style: .default) { [weak self] _ in
            // 进入邮箱登录（push 跳转，铁律 13）
            guard let self = self, let nav = self.navigationControllerForSelectedTab else { return }
            let login = LoginEntryViewController()
            login.fromGuestFlow = true
            nav.pushViewController(login, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

// 让 MainTabBarController 充当其子导航控制器的代理（用于禁用根页侧滑返回）
extension MainTabBarController: UINavigationControllerDelegate {}
