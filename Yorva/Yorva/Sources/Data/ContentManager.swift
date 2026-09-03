//
//  ContentManager.swift
//  Yorva
//
//  内容仓库：帖子 / 评论 / Prompt / 主题 / 点赞 / 收藏（铁律 8 动态数据 + 状态联动）
//

import Foundation
import UIKit

final class ContentManager {

    static let shared = ContentManager()

    private(set) var themes: [ThemeItem] = []
    private(set) var prompts: [PromptItem] = []
    private(set) var posts: [Post] = []
    private(set) var comments: [Comment] = []

    private let likedKey = "yorva.post.likes.v1"
    private let savedKey = "yorva.post.saves.v1"
    private var likedIds: [String] = []
    private var savedIds: [String] = []

    private init() {
        reloadSeed()
        likedIds = UserDefaults.standard.stringArray(forKey: likedKey) ?? []
        savedIds = UserDefaults.standard.stringArray(forKey: savedKey) ?? []
        applyFlags()
    }

    /// 重新加载占位数据（首启 / 数据异常兜底）
    func reloadSeed() {
        themes = SeedData.mockThemes()
        prompts = SeedData.mockPrompts()
        posts = SeedData.mockPosts(users: DataRepository.shared.users)
        comments = SeedData.mockComments(users: DataRepository.shared.users, posts: posts)
        applyFlags()
    }

    private func applyFlags() {
        for i in 0..<posts.count {
            let id = posts[i].id
            posts[i].isLiked = likedIds.contains(id)
            posts[i].isSaved = savedIds.contains(id)
        }
    }

    // MARK: - Themes & Prompts

    func theme(by id: String) -> ThemeItem? { themes.first { $0.id == id } }
    func prompt(by id: String) -> PromptItem? { prompts.first { $0.id == id } }

    /// Prompt library 中今日 / 可用列表
    func freePrompts() -> [PromptItem] { prompts.filter { $0.costType == .free } }
    func paidPrompts() -> [PromptItem] { prompts.filter { $0.costType == .coins } }

    // MARK: - Posts

    func post(by id: String) -> Post? { posts.first { $0.id == id } }

    /// 当前账号可见的 For You 列表（过滤拉黑 + 仅可见）
    func forYouPosts() -> [Post] {
        let visible = posts.filter { $0.isVisible }
        return BlockManager.shared.filterPosts(visible).sorted { $0.createdAt > $1.createdAt }
    }

    /// Following 列表：仅当前账号关注的作者帖子
    func followingPosts(userId: String) -> [Post] {
        let followeeIds = FollowManager.shared.following(userId: userId)
        let visible = posts.filter { $0.isVisible && followeeIds.contains($0.authorId) }
        return BlockManager.shared.filterPosts(visible).sorted { $0.createdAt > $1.createdAt }
    }

    /// 主题详情下「Worth a closer look」帖子
    func themePosts(themeId: String) -> [Post] {
        let visible = posts.filter { $0.themeId == themeId && $0.isVisible }
        return BlockManager.shared.filterPosts(visible).sorted { $0.createdAt > $1.createdAt }
    }

    /// 某作者的帖子
    func postsBy(authorId: String) -> [Post] {
        let visible = posts.filter { $0.authorId == authorId && $0.isVisible }
        return BlockManager.shared.filterPosts(visible).sorted { $0.createdAt > $1.createdAt }
    }

    /// 当前账号已收藏的帖子
    func savedPosts() -> [Post] {
        let saved = posts.filter { $0.isSaved && $0.isVisible }
        return BlockManager.shared.filterPosts(saved).sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Social interactions（状态联动）

    func toggleLike(postId: String) {
        guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return }
        posts[idx].isLiked.toggle()
        if posts[idx].isLiked {
            posts[idx].likeCount += 1
            likedIds.append(postId)
        } else {
            posts[idx].likeCount = max(0, posts[idx].likeCount - 1)
            likedIds.removeAll { $0 == postId }
        }
        persistFlags()
        DataRepository.shared.broadcast(.postInteracted(postId: postId))
    }

    func toggleSave(postId: String) {
        guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return }
        posts[idx].isSaved.toggle()
        if posts[idx].isSaved {
            savedIds.append(postId)
        } else {
            savedIds.removeAll { $0 == postId }
        }
        persistFlags()
        DataRepository.shared.broadcast(.postInteracted(postId: postId))
    }

    // MARK: - Comments

    func comments(postId: String) -> [Comment] {
        let list = comments.filter { $0.postId == postId && $0.isVisible }
        return BlockManager.shared.filterComments(list).sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    func addComment(postId: String, authorId: String, text: String) -> Comment? {
        guard !text.isBlank else { return nil }
        let c = Comment(id: "comment-\(comments.count + 1)-\(Int(Date().timeIntervalSince1970) % 1000)",
                        postId: postId, authorId: authorId, text: text,
                        createdAt: Date(), isVisible: true)
        comments.append(c)
        if let idx = posts.firstIndex(where: { $0.id == postId }) {
            posts[idx].commentCount += 1
        }
        DataRepository.shared.broadcast(.commentsUpdated(postId: postId))
        return c
    }

    // MARK: - Create post

    @discardableResult
    func createPost(authorId: String, promptId: String?, themeId: String?, media: PostMedia?, answer: String) -> Post {
        let post = Post(
            id: "post-user-\(posts.count + 1)",
            authorId: authorId, promptId: promptId, themeId: themeId,
            media: media, answer: answer,
            createdAt: Date(), likeCount: 0, commentCount: 0,
            isLiked: false, isSaved: false, isVisible: true
        )
        posts.insert(post, at: 0)
        DataRepository.shared.broadcast(.postsUpdated)
        return post
    }

    // MARK: - Persist flags

    private func persistFlags() {
        UserDefaults.standard.set(likedIds, forKey: likedKey)
        UserDefaults.standard.set(savedIds, forKey: savedKey)
    }
}
