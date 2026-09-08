//
//  WebContainerViewController.swift
//  Yorva
//
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
