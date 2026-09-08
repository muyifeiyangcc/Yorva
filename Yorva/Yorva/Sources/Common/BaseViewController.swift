//
//  BaseViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

class BaseViewController: UIViewController {

    var pageBackgroundColor: UIColor { AppTheme.bgRoot }

    var isSecondaryLevel: Bool { false }

    var prefersNavigationBarHidden: Bool { true }

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
        navigationController?.setNavigationBarHidden(prefersNavigationBarHidden, animated: animated)
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

    private func configureBaseAppearance() {
        navigationItem.largeTitleDisplayMode = .never
    }

    private func configureTabBarVisibility() {
        if let mainTabBarController = tabBarController as? MainTabBarController {
            mainTabBarController.setCustomTabBarHidden(isSecondaryLevel)
        } else {
            tabBarController?.tabBar.isHidden = isSecondaryLevel
        }
    }

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
        if isSecondaryLevel {
            navigationItem.hidesBackButton = false
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward")?
                    .withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal),
                style: .plain, target: self, action: #selector(handleBackTapped))
            navigationItem.leftBarButtonItem?.tintColor = AppTheme.ink
        }
    }

    @objc func handleBackTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Scroll container

    func shouldUseScrollContainer() -> Bool { false }

    private func setupScrollContainerIfNeeded() {
        guard shouldUseScrollContainer() else { return }
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = true
        sv.keyboardDismissMode = .interactive
        sv.contentInsetAdjustmentBehavior = .always
        sv.backgroundColor = .clear
        sv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sv)
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

    func setupHierarchy() {}
    func applyAutoLayoutConstraints() {}
    func bindData() {}
    func refreshData() {}

    func subscribeDataEvents(_ block: @escaping (DataEvent) -> Void) {
        dataObserverToken = DataRepository.shared.subscribe(block)
    }
}
