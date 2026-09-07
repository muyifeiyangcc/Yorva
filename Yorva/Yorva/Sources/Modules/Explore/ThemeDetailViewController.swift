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

    private let headerImage = UIImageView()
    private let headerShade = UIView()
    private let backButton = UIButton(type: .system)
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let sectionLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = LoadingView()
    private var posts: [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupHierarchy() {
        headerImage.contentMode = .scaleAspectFill
        headerImage.clipsToBounds = true
        headerShade.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        backButton.setImage(UIImage(systemName: "chevron.backward")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.88)
        backButton.layer.cornerRadius = 18
        backButton.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        eyebrowLabel.font = .systemFont(ofSize: 12, weight: .regular)
        eyebrowLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        eyebrowLabel.attributedText = NSAttributedString(string: "THEME / REFLECTION", attributes: [.kern: 1.4])
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white
        descLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        descLabel.numberOfLines = 0
        sectionLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        sectionLabel.textColor = AppTheme.ink
        sectionLabel.text = "Worth a closer look"

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier)
        tableView.estimatedRowHeight = 320
        tableView.rowHeight = UITableView.automaticDimension
        tableView.isScrollEnabled = true
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 92, right: 0)

        [headerImage, headerShade, backButton, eyebrowLabel, titleLabel, descLabel, sectionLabel, tableView].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        headerImage.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(206)
        }
        headerShade.snp.makeConstraints { make in
            make.edges.equalTo(headerImage)
        }
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(36)
        }
        eyebrowLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(19)
            make.bottom.equalTo(titleLabel.snp.top).offset(-4)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(19)
            make.bottom.equalTo(descLabel.snp.top).offset(-4)
        }
        descLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.bottom.equalTo(headerImage.snp.bottom).offset(-16)
        }
        titleLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(40)
        }
        sectionLabel.snp.makeConstraints { make in
            make.top.equalTo(headerImage.snp.bottom).offset(18)
            make.left.right.equalToSuperview().inset(17)
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
        let assetName: String
        switch theme.id {
        case "theme-keep": assetName = "Section1"
        case "theme-habits": assetName = "Section"
        case "theme-letgo": assetName = "Section2"
        case "theme-lesstech": assetName = "Section3"
        default: assetName = "Section"
        }
        headerImage.image = UIImage(named: assetName)
        headerImage.backgroundColor = theme.coverColor
        titleLabel.text = theme.title
        descLabel.text = detailDescription(for: theme)
        posts = ContentManager.shared.themePosts(themeId: id)
        if posts.isEmpty {
            loadingView.state = .empty(title: "No posts for this theme yet",
                                       subtitle: "Be the first to share a story here.", actionTitle: nil)
            loadingView.show(in: view)
        } else {
            loadingView.hide()
        }
        tableView.reloadData()
        // 内容超出时允许纵向滚动：tableView 默认即纵向滚动；当超出屏幕时自动滚动（铁律：滚动容错）
    }

    private func detailDescription(for theme: ThemeItem) -> String {
        switch theme.id {
        case "theme-keep": return "What earns its place in a lighter life."
        case "theme-habits": return "Small choices that make days lighter."
        case "theme-letgo": return "Release what no longer serves you."
        case "theme-lesstech": return "Make room for life offline."
        default: return theme.desc
        }
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
