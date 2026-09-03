//
//  HomeViewController.swift
//  Yorva
//
//  Tab1 Home：For You / Following
//  铁律 2：游客态任意触控 / 切换 Tab 强制弹出必须登录弹窗
//

import UIKit
import SnapKit

final class HomeViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgRoot }

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let segmentControl = UISegmentedControl(items: ["For You", "Following"])
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = LoadingView()

    private var posts: [Post] = []
    private var state: LoadingView.State = .loading

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
        refreshData()
    }

    override func setupHierarchy() {
        titleLabel.text = "Makeroom for less."
        titleLabel.font = AppFont.largeTitle()
        titleLabel.textColor = AppTheme.olive
        subtitleLabel.text = "Record, reflect and share small choices every day."
        subtitleLabel.font = AppFont.bodySecondary()
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 0
        segmentControl.selectedSegmentIndex = 0
        segmentControl.setTitleTextAttributes([.font: AppFont.buttonSecondary(), .foregroundColor: AppTheme.stone], for: .normal)
        segmentControl.setTitleTextAttributes([.font: AppFont.buttonPrimary(), .foregroundColor: AppTheme.primary], for: .selected)
        segmentControl.selectedSegmentTintColor = AppTheme.cream
        segmentControl.backgroundColor = AppTheme.bgPrimary
        segmentControl.layer.cornerRadius = 12
        segmentControl.addAction(UIAction { [weak self] _ in self?.refreshData() }, for: .valueChanged)

        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 320
        tableView.rowHeight = UITableView.automaticDimension

        [titleLabel, subtitleLabel, segmentControl, tableView].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(16)
        }
        segmentControl.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentControl.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .postsUpdated, .postInteracted, .followChanged, .blockListChanged:
                self.refreshData()
            default: break
            }
        }
    }

    override func refreshData() {
        // 游客态不展示任何内容（铁律 2：全程禁止浏览任何内容）
        if AccountManager.shared.isGuest {
            state = .empty(title: "Sign in to view posts", subtitle: "Yorva shows posts only after you sign in.", actionTitle: "Sign in")
            loadingView.state = state
            loadingView.show(in: view)
            loadingView.onAction = { [weak self] in
                guard let nav = self?.navigationController else { return }
                let login = LoginEntryViewController()
                login.fromGuestFlow = true
                nav.pushViewController(login, animated: true)
            }
            posts = []
            tableView.reloadData()
            return
        }
        loadingView.hide()
        let me = AccountManager.shared.currentUser?.id ?? ""
        posts = segmentControl.selectedSegmentIndex == 0
            ? ContentManager.shared.forYouPosts()
            : ContentManager.shared.followingPosts(userId: me)
        if posts.isEmpty {
            let title = segmentControl.selectedSegmentIndex == 0 ? "No posts yet" : "Following feed is empty"
            let subtitle = segmentControl.selectedSegmentIndex == 0
                ? "Be the first to share a small choice today."
                : "Head to Explore and follow a few people to fill this feed."
            state = .empty(title: title, subtitle: subtitle, actionTitle: nil)
            loadingView.state = state
            loadingView.show(in: view)
        } else {
            loadingView.hide()
        }
        tableView.reloadData()
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate, PostCardCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { posts.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier, for: indexPath) as! PostCardCell
        let post = posts[indexPath.row]
        let author = DataRepository.shared.user(by: post.authorId)
        cell.configure(post: post, author: author)
        cell.delegate = self
        return cell
    }

    func postCardDidTapAuthor(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        let post = posts[idx]
        guard let author = DataRepository.shared.user(by: post.authorId) else { return }
        let vc = AuthorProfileViewController()
        vc.author = author
        navigationController?.pushViewController(vc, animated: true)
    }
    func postCardDidTapMore(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        MoreMenu.showPostMoreMenu(post: posts[idx], from: self)
    }
    func postCardDidTapLike(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        ContentManager.shared.toggleLike(postId: posts[idx].id)
    }
    func postCardDidTapComment(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        let vc = PostDetailViewController()
        vc.postId = posts[idx].id
        navigationController?.pushViewController(vc, animated: true)
    }
    func postCardDidTapSave(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        ContentManager.shared.toggleSave(postId: posts[idx].id)
        Toast.show(posts[idx].isSaved ? "Saved" : "Removed from saved")
    }
    func postCardDidTapPost(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        let vc = PostDetailViewController()
        vc.postId = posts[idx].id
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = PostDetailViewController()
        vc.postId = posts[indexPath.row].id
        navigationController?.pushViewController(vc, animated: true)
    }
}
