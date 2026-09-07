//
//  WebContainerViewController.swift
//  Yorva
//
//  网页容器（铁律 3）
//  Privacy Policy / Terms of Service 跳转固定链接 https://www.baidu.com
//  隐藏 TabBar + 顶部返回（铁律 5）+ push 跳转（铁律 13）
//

import UIKit
import SnapKit
import WebKit

final class WebContainerViewController: BaseViewController {

    var targetURL: URL?
    private var webView: WKWebView!

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }
    override var prefersNavigationBarHidden: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView = WKWebView()
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.bottom.equalToSuperview()
        }
        if let url = targetURL {
            webView.load(URLRequest(url: url))
        }
    }
}
