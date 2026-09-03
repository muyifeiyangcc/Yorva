//
//  BaseNavigationController.swift
//  Yorva
//
//  统一导航控制器，所有 push 进入的二级及更深页面使用此导航栈
//  使用导航栈 push 进入下一页（铁律 13：禁止 present 进入业务下级页）
//

import UIKit

class BaseNavigationController: UINavigationController, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        // 统一处理手势返回
        interactivePopGestureRecognizer?.delegate = nil
        navigationBar.tintColor = AppTheme.ink
    }

    // 首页不允许侧滑返回（避免意外退出 Tab 根页面）
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        interactivePopGestureRecognizer?.isEnabled = navigationController.viewControllers.count > 1
    }
}
