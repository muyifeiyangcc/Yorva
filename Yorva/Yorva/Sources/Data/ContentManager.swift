//
//  ContentManager.swift
//  Yorva
//
//  内容仓库：帖子 / 评论 / Prompt / 主题 / 点赞 / 收藏（动态、持久化、按账号隔离）
//

import Foundation
import UIKit
import AVFoundation

final class ContentManager {

    static let shared = ContentManager()

    private(set) var themes: [ThemeItem] = []
    private(set) var prompts: [PromptItem] = []
    private(set) var posts: [Post] = []
    private(set) var comments: [Comment] = []

    private let contentKey = "yorva.content.store.v3"
    private let likedKey = "yorva.post.likes.by.user.v2"
    private let savedKey = "yorva.post.saves.by.user.v2"
    private var likedByUser: [String: [String]] = [:]
    private var savedByUser: [String: [String]] = [:]
    private var lastAppliedUserKey: String?

    private init() {
        loadFlags()
        reloadSeed()
    }

    /// 载入已保存的内容；首次安装时才使用 SeedData 作为初始数据。
    func reloadSeed() {
        themes = SeedData.mockThemes()
        prompts = SeedData.mockPrompts()
        if let data = UserDefaults.standard.data(forKey: contentKey),
           let stored = try? JSONDecoder().decode(ContentStoreDTO.self, from: data) {
            posts = stored.posts.map { $0.toPost() }
            comments = stored.comments.map { $0.toComment() }
        } else {
            posts = SeedData.mockPosts(users: DataRepository.shared.users)
            comments = SeedData.mockComments(users: DataRepository.shared.users, posts: posts)
            persistContent()
        }
        applyFlags()
    }

    private var activeUserKey: String { AccountManager.shared.currentUser?.id ?? "guest" }

    private func ensureCurrentUserScope() {
        let key = activeUserKey
        guard key != lastAppliedUserKey else { return }
        lastAppliedUserKey = key
        applyFlags()
    }

    private func loadFlags() {
        if let data = UserDefaults.standard.data(forKey: likedKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            likedByUser = decoded
        } else if let old = UserDefaults.standard.stringArray(forKey: "yorva.post.likes.v1") {
            likedByUser[activeUserKey] = old
        }
        if let data = UserDefaults.standard.data(forKey: savedKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            savedByUser = decoded
        } else if let old = UserDefaults.standard.stringArray(forKey: "yorva.post.saves.v1") {
            savedByUser[activeUserKey] = old
        }
    }

    private func applyFlags() {
        let likes = Set(likedByUser[activeUserKey] ?? [])
        let saves = Set(savedByUser[activeUserKey] ?? [])
        for i in posts.indices {
            posts[i].isLiked = likes.contains(posts[i].id)
            posts[i].isSaved = saves.contains(posts[i].id)
        }
    }

    // MARK: - Themes & Prompts

    func theme(by id: String) -> ThemeItem? { themes.first { $0.id == id } }
    func prompt(by id: String) -> PromptItem? { prompts.first { $0.id == id } }
    func freePrompts() -> [PromptItem] { prompts.filter { $0.costType == .free } }
    func paidPrompts() -> [PromptItem] { prompts.filter { $0.costType == .coins } }

    // MARK: - Posts

    func post(by id: String) -> Post? {
        ensureCurrentUserScope()
        guard let post = posts.first(where: { $0.id == id && $0.isVisible }),
              !BlockManager.shared.isBlocked(post.authorId) else { return nil }
        return post
    }

    func forYouPosts() -> [Post] {
        ensureCurrentUserScope()
        return BlockManager.shared.filterPosts(posts.filter { $0.isVisible }).sorted { $0.createdAt > $1.createdAt }
    }

    func followingPosts(userId: String) -> [Post] {
        ensureCurrentUserScope()
        let followeeIds = FollowManager.shared.following(userId: userId)
        let visible = posts.filter { $0.isVisible && followeeIds.contains($0.authorId) }
        return BlockManager.shared.filterPosts(visible).sorted { $0.createdAt > $1.createdAt }
    }

    func themePosts(themeId: String) -> [Post] {
        ensureCurrentUserScope()
        return BlockManager.shared.filterPosts(posts.filter { $0.themeId == themeId && $0.isVisible }).sorted { $0.createdAt > $1.createdAt }
    }

    func postsBy(authorId: String) -> [Post] {
        ensureCurrentUserScope()
        return BlockManager.shared.filterPosts(posts.filter { $0.authorId == authorId && $0.isVisible }).sorted { $0.createdAt > $1.createdAt }
    }

    /// 指定用户真实收藏的帖子，支持在他人个人资料页展示 Saved。
    func savedPosts(forUserId userId: String) -> [Post] {
        ensureCurrentUserScope()
        let savedIDs = Set(savedByUser[userId] ?? [])
        return BlockManager.shared.filterPosts(posts.filter { savedIDs.contains($0.id) && $0.isVisible }).sorted { $0.createdAt > $1.createdAt }
    }

    func savedPosts() -> [Post] { savedPosts(forUserId: activeUserKey) }

    func removeUserState(_ userId: String) {
        likedByUser.removeValue(forKey: userId)
        savedByUser.removeValue(forKey: userId)
        persistFlags()
    }

    // MARK: - Social interactions

    func toggleLike(postId: String) {
        ensureCurrentUserScope()
        guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return }
        var ids = Set(likedByUser[activeUserKey] ?? [])
        if ids.insert(postId).inserted {
            posts[idx].likeCount += 1
        } else {
            ids.remove(postId)
            posts[idx].likeCount = max(0, posts[idx].likeCount - 1)
        }
        likedByUser[activeUserKey] = Array(ids)
        applyFlags()
        persistFlags()
        persistContent()
        DataRepository.shared.broadcast(.postInteracted(postId: postId))
    }

    func toggleSave(postId: String) {
        ensureCurrentUserScope()
        guard posts.contains(where: { $0.id == postId }) else { return }
        var ids = Set(savedByUser[activeUserKey] ?? [])
        if ids.contains(postId) { ids.remove(postId) } else { ids.insert(postId) }
        savedByUser[activeUserKey] = Array(ids)
        applyFlags()
        persistFlags()
        DataRepository.shared.broadcast(.postInteracted(postId: postId))
    }

    // MARK: - Comments

    func comments(postId: String) -> [Comment] {
        BlockManager.shared.filterComments(comments.filter { $0.postId == postId && $0.isVisible }).sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    func addComment(postId: String, authorId: String, text: String) -> Comment? {
        guard !text.isBlank, posts.contains(where: { $0.id == postId && $0.isVisible }) else { return nil }
        let c = Comment(id: "comment-\(UUID().uuidString)", postId: postId, authorId: authorId,
                        text: text, createdAt: Date(), isVisible: true)
        comments.append(c)
        if let idx = posts.firstIndex(where: { $0.id == postId }) { posts[idx].commentCount += 1 }
        persistContent()
        DataRepository.shared.broadcast(.commentsUpdated(postId: postId))
        // Reuse the post interaction refresh path so every feed cell updates its comment count.
        DataRepository.shared.broadcast(.postInteracted(postId: postId))
        return c
    }

    // MARK: - Create post

    @discardableResult
    func createPost(authorId: String, promptId: String?, themeId: String?, media: PostMedia?, answer: String) -> Post {
        let durableMedia = persistMediaFile(media)
        let post = Post(id: "post-user-\(UUID().uuidString)", authorId: authorId, promptId: promptId,
                        themeId: themeId, media: durableMedia, answer: answer, createdAt: Date(), likeCount: 0,
                        commentCount: 0, isLiked: false, isSaved: false, isVisible: true)
        posts.insert(post, at: 0)
        persistContent()
        DataRepository.shared.broadcast(.postsUpdated)
        return post
    }

    private func persistMediaFile(_ media: PostMedia?) -> PostMedia? {
        guard let media, let source = media.videoURL else { return media }
        let thumbnail = media.image ?? videoThumbnail(for: source)
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("YorvaMedia", isDirectory: true)
        let destination = directory.appendingPathComponent(source.lastPathComponent)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.copyItem(at: source, to: destination)
            }
            return PostMedia(kind: media.kind, aspectRatio: media.aspectRatio, duration: media.duration,
                             placeholderColor: media.placeholderColor, image: thumbnail, videoURL: destination)
        } catch {
            // Keep the post and its thumbnail in the current session even if
            // the media copy is temporarily unavailable.
            return PostMedia(kind: media.kind, aspectRatio: media.aspectRatio, duration: media.duration,
                             placeholderColor: media.placeholderColor, image: thumbnail, videoURL: source)
        }
    }

    private func videoThumbnail(for url: URL) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: AVAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Persistence

    private func persistFlags() {
        if let data = try? JSONEncoder().encode(likedByUser) { UserDefaults.standard.set(data, forKey: likedKey) }
        if let data = try? JSONEncoder().encode(savedByUser) { UserDefaults.standard.set(data, forKey: savedKey) }
    }

    private func persistContent() {
        let store = ContentStoreDTO(posts: posts.map { PostDTO($0) }, comments: comments.map { CommentDTO($0) })
        if let data = try? JSONEncoder().encode(store) { UserDefaults.standard.set(data, forKey: contentKey) }
    }
}

private struct ContentStoreDTO: Codable {
    let posts: [PostDTO]
    let comments: [CommentDTO]
}

private struct PostDTO: Codable {
    let id: String; let authorId: String; let promptId: String?; let themeId: String?
    let media: PostMediaDTO?; let answer: String; let createdAt: TimeInterval
    let likeCount: Int; let commentCount: Int; let isVisible: Bool
    init(_ p: Post) {
        id = p.id; authorId = p.authorId; promptId = p.promptId; themeId = p.themeId
        media = p.media.map { PostMediaDTO($0) }; answer = p.answer; createdAt = p.createdAt.timeIntervalSince1970
        likeCount = p.likeCount; commentCount = p.commentCount; isVisible = p.isVisible
    }
    func toPost() -> Post {
        Post(id: id, authorId: authorId, promptId: promptId, themeId: themeId, media: media?.toMedia(),
             answer: answer, createdAt: Date(timeIntervalSince1970: createdAt), likeCount: likeCount,
             commentCount: commentCount, isLiked: false, isSaved: false, isVisible: isVisible)
    }
}

private struct PostMediaDTO: Codable {
    let kind: String; let aspectRatio: Double; let duration: Double?; let placeholderHex: UInt32
    let imageData: Data?; let videoPath: String?
    let imageAssetName: String?; let videoResourceName: String?
    init(_ m: PostMedia) {
        kind = m.kind == .image ? "image" : "video"; aspectRatio = Double(m.aspectRatio)
        duration = m.duration
        placeholderHex = MainActor.assumeIsolated { Self.hex(m.placeholderColor) }
        // Asset 目录图片不编码进 UserDefaults，仅持久化资源名
        imageData = m.imageAssetName == nil ? m.image.flatMap { image in
            MainActor.assumeIsolated { image.jpegData(compressionQuality: 0.85) }
        } : nil
        videoPath = m.videoURL?.path
        imageAssetName = m.imageAssetName
        videoResourceName = m.videoResourceName
    }
    func toMedia() -> PostMedia {
        let decodedColor = MainActor.assumeIsolated { Self.color(placeholderHex) }
        let decodedImage = imageData.flatMap { data in
            MainActor.assumeIsolated { UIImage(data: data) }
        }
        return PostMedia(kind: kind == "video" ? .video : .image, aspectRatio: CGFloat(aspectRatio), duration: duration,
                  placeholderColor: decodedColor, image: decodedImage,
                  videoURL: videoPath.map { URL(fileURLWithPath: $0) },
                  imageAssetName: imageAssetName,
                  videoResourceName: videoResourceName)
    }
    @MainActor private static func hex(_ color: UIColor) -> UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UInt32(r * 255) << 24 | UInt32(g * 255) << 16 | UInt32(b * 255) << 8 | UInt32(a * 255)
    }
    @MainActor private static func color(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 24) & 255) / 255, green: CGFloat((hex >> 16) & 255) / 255,
                blue: CGFloat((hex >> 8) & 255) / 255, alpha: CGFloat(hex & 255) / 255)
    }
}

private struct CommentDTO: Codable {
    let id: String; let postId: String; let authorId: String; let text: String
    let createdAt: TimeInterval; let isVisible: Bool
    init(_ c: Comment) { id = c.id; postId = c.postId; authorId = c.authorId; text = c.text; createdAt = c.createdAt.timeIntervalSince1970; isVisible = c.isVisible }
    func toComment() -> Comment { Comment(id: id, postId: postId, authorId: authorId, text: text, createdAt: Date(timeIntervalSince1970: createdAt), isVisible: isVisible) }
}
