//
//  BaseViewController.swift
//  Yorva
//
//  所有页面控制器基类
//  - 全局适配刘海屏 / 灵动岛 / 非刘海屏（铁律：刘海屏适配强制规范）
//  - 所有页面使用 AutoLayout（铁律：禁止硬编码宽高）
//  - 内容溢出场景开启纵向滚动容器（铁律：滚动容错强制规范）
//  - 二级及深层页面隐藏 TabBar + 统一返回按钮（铁律 5）
//  - 接收数据仓库变更通知自动刷新（铁律 8）
//

import UIKit
import SnapKit

class BaseViewController: UIViewController {

    /// 全页面统一的背景色（子类可重写覆盖）
    var pageBackgroundColor: UIColor { AppTheme.bgRoot }

    /// 是否为二级及更深页面（隐藏 TabBar、提供返回）
    var isSecondaryLevel: Bool { false }

    /// 内容容器（自动纵向滚动）
    private(set) var scrollView: UIScrollView?
    private(set) var contentView: UIView?

    private var dataObserverToken: NSObjectProtocol?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = pageBackgroundColor
        configureBaseAppearance()
        setupScrollContainerIfNeeded()
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTabBarVisibility()
        configureNavigationBarAppearance()
        refreshData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    deinit {
        if let token = dataObserverToken { DataRepository.shared.unsubscribe(token) }
    }

    // MARK: - Base appearance

    /// 二级页面隐藏 TabBar；根页面保留（铁律 5）
    private func configureTabBarVisibility() {
        if isSecondaryLevel {
            tabBarController?.tabBar.isHidden = true
        } else {
            tabBarController?.tabBar.isHidden = false
        }
    }

    /// 导航栏样式：刘海屏 / 灵动岛 / 非刘海屏统一适配
    /// 使用 safeAreaInsets 顶部偏移保证不同机型高度、内边距统一
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = pageBackgroundColor
        appearance.titleTextAttributes = [
            .foregroundColor: AppTheme.ink,
            .font: AppFont.navTitle()
        ]
        appearance.shadowColor = AppTheme.divider
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        // 二级及更深页面统一左侧返回按钮（铁律 5）
        if isSecondaryLevel {
            navigationItem.hidesBackButton = false
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward")?
                    .withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal),
                style: .plain, target: self, action: #selector(handleBackTapped))
            navigationItem.leftBarButtonItem?.tintColor = AppTheme.ink
        }
        // 充分适配刘海屏 / 灵动岛 / 非刘海屏：导航栏使用系统布局，由 safeArea 自动处理顶部 inset
    }

    @objc func handleBackTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Scroll container

    /// 子类如需纵向滚动内容，重写 shouldUseScrollContainer 返回 true 即可
    func shouldUseScrollContainer() -> Bool { false }

    private func setupScrollContainerIfNeeded() {
        guard shouldUseScrollContainer() else { return }
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = true
        sv.backgroundColor = .clear
        sv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sv)
        // 滚动容器贴合安全区，避开刘海屏 / 灵动岛 / 底部 Home 指示区
        sv.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        let cv = UIView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        sv.addSubview(cv)
        cv.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        scrollView = sv
        contentView = cv
    }

    // MARK: - Hooks for subclass

    /// 在此处添加视图层级（直接 add 到 view 或 contentView）
    func setupHierarchy() {}
    /// 在此处施加 AutoLayout 约束（使用 SnapKit）
    func applyAutoLayoutConstraints() {}
    /// 在此处订阅数据变更
    func bindData() {}
    /// 数据刷新入口；viewWillAppear 与收到通知都会调用
    func refreshData() {}

    /// 数据通知订阅便捷方法
    func subscribeDataEvents(_ block: @escaping (DataEvent) -> Void) {
        dataObserverToken = DataRepository.shared.subscribe(block)
    }
}
