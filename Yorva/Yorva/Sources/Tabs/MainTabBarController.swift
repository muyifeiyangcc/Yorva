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

/// 设计稿中的浮动 TabBar：白色圆角胶囊、五个等宽触控槽位，图标直接使用 Assets 切图。
final class CustomTabBarView: UIView {

    var onSelectTab: ((Int) -> Void)?
    var onCreatePost: (() -> Void)?

    private let tabButtons: [UIButton] = (0..<4).map { _ in UIButton(type: .custom) }
    private let createButton = UIButton(type: .custom)
    private let slotStack = UIStackView()
    private var selectedIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 4)

        slotStack.axis = .horizontal
        slotStack.alignment = .fill
        slotStack.distribution = .fillEqually
        slotStack.spacing = 0
        addSubview(slotStack)
        slotStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let imageNames = ["tab1", "tab2", "tab4", "tab5"]
        let selectedImageNames = ["tab1_sel", "tab2_sel", "tab4_sel", "tab5_sel"]
        for index in 0..<5 {
            let slot = UIView()
            slot.backgroundColor = .clear
            slotStack.addArrangedSubview(slot)
            let button: UIButton
            if index == 2 {
                button = createButton
                button.setImage(UIImage(named: "tab3")?.withRenderingMode(.alwaysOriginal), for: .normal)
                button.accessibilityLabel = "Create post"
                button.addAction(UIAction { [weak self] _ in self?.onCreatePost?() }, for: .touchUpInside)
            } else {
                let tabIndex = index < 2 ? index : index - 1
                button = tabButtons[tabIndex]
                button.setImage(UIImage(named: imageNames[tabIndex])?.withRenderingMode(.alwaysOriginal), for: .normal)
                button.setImage(UIImage(named: selectedImageNames[tabIndex])?.withRenderingMode(.alwaysOriginal), for: .selected)
                button.accessibilityLabel = ["Home", "Explore", "Chat", "Profile"][tabIndex]
                button.addAction(UIAction { [weak self] _ in self?.onSelectTab?(tabIndex) }, for: .touchUpInside)
            }
            button.adjustsImageWhenHighlighted = false
            button.imageView?.contentMode = .scaleAspectFit
            slot.addSubview(button)
            button.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(CGSize(width: 48, height: 48))
            }
        }
        setSelectedIndex(0)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setSelectedIndex(_ index: Int) {
        guard tabButtons.indices.contains(index) else { return }
        selectedIndex = index
        for (buttonIndex, button) in tabButtons.enumerated() {
            button.isSelected = buttonIndex == selectedIndex
        }
    }

    func setHidden(_ hidden: Bool, animated: Bool) {
        guard isHidden != hidden else { return }
        if animated {
            if !hidden { alpha = 0; isHidden = false }
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = hidden ? 0 : 1
            }) { _ in
                self.isHidden = hidden
            }
        } else {
            isHidden = hidden
            alpha = hidden ? 0 : 1
        }
    }
}

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    private let customTabBar = CustomTabBarView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.bgRoot
        delegate = self
        configureTabs()
        tabBar.isHidden = true
        tabBar.isUserInteractionEnabled = false
        customTabBar.onSelectTab = { [weak self] index in
            self?.selectTab(index)
        }
        customTabBar.onCreatePost = { [weak self] in
            self?.handleCenterPostButton()
        }
        view.addSubview(customTabBar)
        customTabBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(61)
        }
    }

    private func configureTabs() {
        let home = HomeViewController()
        home.tabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)
        let explore = ExploreViewController()
        explore.tabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)
        let chat = ChatListViewController()
        chat.tabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)
        let profile = ProfileViewController()
        profile.tabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)

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

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let index = viewControllers?.firstIndex(where: { $0 === viewController }) else { return }
        customTabBar.setSelectedIndex(index)
    }

    private func selectTab(_ index: Int) {
        guard let controllers = viewControllers, controllers.indices.contains(index) else { return }
        guard tabBarController(self, shouldSelect: controllers[index]) else { return }
        selectedIndex = index
        customTabBar.setSelectedIndex(index)
    }

    /// 公开的 Tab 切换入口（用于头像等场景跳转到 Me 页时同步底部选中态）
    func switchToTab(_ index: Int) {
        guard let controllers = viewControllers, controllers.indices.contains(index) else { return }
        selectedIndex = index
        customTabBar.setSelectedIndex(index)
    }

    /// 仅根 Tab 显示自定义 TabBar，二级页面推入时隐藏。
    func setCustomTabBarHidden(_ hidden: Bool, animated: Bool = false) {
        customTabBar.setHidden(hidden, animated: animated)
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
        ConfirmDialog.show(title: "Sign in required",
                           message: "Please sign in to continue browsing Yorva.",
                           confirmTitle: "Sign in", cancelTitle: "Cancel") { [weak self] in
            // 进入邮箱登录（push 跳转，铁律 13）
            guard let self = self, let nav = self.navigationControllerForSelectedTab else { return }
            let login = LoginEntryViewController()
            login.fromGuestFlow = true
            nav.pushViewController(login, animated: true)
        }
    }
}

// 让 MainTabBarController 充当其子导航控制器的代理（用于禁用根页侧滑返回）
extension MainTabBarController: UINavigationControllerDelegate {}
