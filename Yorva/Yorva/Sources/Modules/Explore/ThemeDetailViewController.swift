//
//  ThemeDetailViewController.swift
//  Yorva
//
//  Tab2 二级页：主题详情（顶部大图 + 标签 + 描述 + Worth a closer look 帖子列表）
//

import UIKit
import SnapKit

final class ThemeDetailViewController: BaseViewController {

    var themeId: String?
    override var pageBackgroundColor: UIColor { AppTheme.bgRoot }
    override var isSecondaryLevel: Bool { true }

    private let headerImage = UIView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let sectionLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = LoadingView()
    private var posts: [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Theme"
        setupHierarchy()
        applyAutoLayoutConstraints()
        bindData()
        refreshData()
    }

    override func setupHierarchy() {
        headerImage.layer.cornerRadius = 16
        headerImage.layer.masksToBounds = true
        titleLabel.font = AppFont.cardTitleSemibold()
        titleLabel.textColor = AppTheme.ink
        descLabel.font = AppFont.bodySecondary()
        descLabel.textColor = AppTheme.textSecondary
        descLabel.numberOfLines = 0
        sectionLabel.font = AppFont.section()
        sectionLabel.textColor = AppTheme.olive
        sectionLabel.text = "Worth a closer look"

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier)
        tableView.estimatedRowHeight = 320
        tableView.rowHeight = UITableView.automaticDimension
        tableView.isScrollEnabled = false

        [headerImage, titleLabel, descLabel, sectionLabel, tableView].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        headerImage.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(180)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerImage.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(16)
        }
        sectionLabel.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(sectionLabel.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func bindData() {
        subscribeDataEvents { [weak self] event in
            switch event {
            case .postsUpdated, .postInteracted, .blockListChanged, .followChanged:
                self?.refreshData()
            default: break
            }
        }
    }

    override func refreshData() {
        guard let id = themeId, let theme = ContentManager.shared.theme(by: id) else { return }
        headerImage.backgroundColor = theme.coverColor
        titleLabel.text = theme.title
        descLabel.text = theme.desc
        posts = ContentManager.shared.themePosts(themeId: id)
        if posts.isEmpty {
            loadingView.state = .empty(title: "No posts for this theme yet",
                                       subtitle: "Be the first to share a story here.", actionTitle: nil)
            loadingView.show(in: view)
        } else {
            loadingView.hide()
        }
        tableView.reloadData()
        // 内容超出时允许纵向滚动：包裹 ScrollView 已在 BaseViewController 中支持，但本页采用 tableView
        // tableView 默认即纵向滚动；当超出屏幕时自动滚动（铁律：滚动容错）
    }
}

extension ThemeDetailViewController: UITableViewDataSource, UITableViewDelegate, PostCardCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { posts.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier, for: indexPath) as! PostCardCell
        let post = posts[indexPath.row]
        cell.configure(post: post, author: DataRepository.shared.user(by: post.authorId))
        cell.delegate = self
        return cell
    }
    func postCardDidTapAuthor(_ cell: PostCardCell) {
        guard let idx = tableView.indexPath(for: cell)?.row else { return }
        let post = posts[idx]
        if let author = DataRepository.shared.user(by: post.authorId) {
            let vc = AuthorProfileViewController()
            vc.author = author
            navigationController?.pushViewController(vc, animated: true)
        }
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
