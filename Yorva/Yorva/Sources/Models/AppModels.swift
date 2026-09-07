//
//  AppModels.swift
//  Yorva
//
//  数据模型层：集中定义所有数据结构，对应 PRD 第 6 章
//

import UIKit

// MARK: - User

struct User {
    var id: String
    var email: String
    var passwordDigest: String
    var nickname: String
    var avatarPlaceholderColor: UIColor   // 占位头像底色（暂无图标资源）
    var avatarInitials: String            // 占位头像首字母
    var bio: String
    var birthday: String
    var location: String
    var gender: String
    var isDeleted: Bool                   // 账号被删除后标记失效（铁律 10）
    var coins: Int
    var diamonds: Int
    var isGuest: Bool                    // 游客态标识（铁律 2）
    var avatarImage: UIImage? = nil      // 用户选择的头像（仅运行期资源）
    var avatarAssetName: String? = nil   // 本地 Asset Catalog 中的头像资源名（初始化静态数据）
}

// MARK: - Theme / Prompt

struct ThemeItem {
    let id: String
    let title: String          // 如 Keep / Habits / Let go / Less tech
    let desc: String
    let coverColor: UIColor   // 占位大图底色（暂无切图）
    var postIds: [String]
}

enum PromptCostType { case free, coins }
struct PromptItem {
    let id: String
    let title: String
    let themeId: String?
    let costType: PromptCostType
    let costAmount: Int          // 0 表示免费
    var isUsed: Bool
    var metadata: String = ""
}

// MARK: - Post

struct PostMedia {
    enum Kind { case image, video }
    let kind: Kind
    let aspectRatio: CGFloat    // 原比例宽高比（图片按原比例显示，铁律 11）
    let duration: TimeInterval? // 视频时长
    let placeholderColor: UIColor
    let image: UIImage?         // 用户选择的图片（仅运行期资源）
    let videoURL: URL?          // 用户选择的视频（仅运行期资源）
    let imageAssetName: String?  // 本地 Asset Catalog 中的图片资源名（初始化静态数据）
    let videoResourceName: String? // App Bundle 内视频文件名（不含扩展名，位于 file/ 资源目录）

    init(kind: Kind, aspectRatio: CGFloat, duration: TimeInterval?, placeholderColor: UIColor,
         image: UIImage? = nil, videoURL: URL? = nil,
         imageAssetName: String? = nil, videoResourceName: String? = nil) {
        self.kind = kind
        self.aspectRatio = aspectRatio
        self.duration = duration
        self.placeholderColor = placeholderColor
        self.image = image
        self.videoURL = videoURL
        self.imageAssetName = imageAssetName
        self.videoResourceName = videoResourceName
    }

    /// 解析最终展示图片：优先用户运行期选择的图片，其次本地 Asset 资源
    var resolvedImage: UIImage? {
        if let image { return image }
        if let name = imageAssetName { return UIImage(named: name) }
        return nil
    }

    /// 解析最终播放地址：优先用户运行期视频，其次 App Bundle 内打包的视频资源
    var resolvedVideoURL: URL? {
        if let videoURL { return videoURL }
        if let name = videoResourceName {
            return Bundle.main.url(forResource: name, withExtension: "mp4")
        }
        return nil
    }
}

struct Post {
    let id: String
    let authorId: String
    let promptId: String?
    let themeId: String?
    var media: PostMedia?
    var answer: String
    var createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool
    var isSaved: Bool
    var isVisible: Bool         // 帖子是否可见（被作者删除时为 false）
}

// MARK: - Comment

struct Comment {
    let id: String
    let postId: String
    let authorId: String
    var text: String
    var createdAt: Date
    var isVisible: Bool          // 拉黑作者时该评论被过滤
}

// MARK: - Conversation / Message

enum MessageType { case text, image, voice }

struct ChatMessage {
    let id: String
    let conversationId: String
    let senderId: String         // self / other / "yorva-ai"
    var type: MessageType
    var text: String?
    var imageColor: UIColor?     // 占位图片底色
    var imageRatio: CGFloat?
    var voiceDuration: TimeInterval?
    var isPlayed: Bool
    var createdAt: Date
    var image: UIImage? = nil        // 用户选择的图片（仅运行期资源）
    var voiceURL: URL? = nil         // 录音文件 URL（仅运行期资源）

    init(id: String, conversationId: String, senderId: String, type: MessageType,
         text: String?, imageColor: UIColor?, imageRatio: CGFloat?,
         voiceDuration: TimeInterval?, isPlayed: Bool, createdAt: Date,
         image: UIImage? = nil, voiceURL: URL? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.type = type
        self.text = text
        self.imageColor = imageColor
        self.imageRatio = imageRatio
        self.voiceDuration = voiceDuration
        self.isPlayed = isPlayed
        self.createdAt = createdAt
        self.image = image
        self.voiceURL = voiceURL
    }
}

struct Conversation {
    let id: String
    let participantIds: [String]   // 两个用户 id（Yorva AI 会话固定 ["self","yorva-ai"]）
    var lastMessage: ChatMessage?
    var unreadCount: Int
    var isYorvaAI: Bool
    /// 会话所属账号；旧种子会在首次载入时绑定到当前账号。
    var ownerId: String? = nil
}

// MARK: - Relation / Report

struct FollowRelation {
    let followerId: String
    let followeeId: String
    let createdAt: Date
}

struct BlockRelation {
    let blockerId: String
    let blockedId: String
    let createdAt: Date
}

enum ReportReason: String, CaseIterable {
    case spam = "Spam or scam"
    case harassment = "Harassment"
    case hate = "Hate speech"
    case nudity = "Nudity"
    case dangerous = "Dangerous activity"
    case falseInfo = "False information"
    case other = "Other"

    var displayName: String { rawValue }
}

struct ReportRecord {
    let id: String
    let reporterId: String
    let targetUserId: String
    let reason: ReportReason
    let detail: String
    let createdAt: Date
}

// MARK: - Wallet / Product / Purchase

enum CurrencyType { case coins, diamonds }

struct WalletProduct {
    let productId: String        // StoreKit V1 product id
    let coinsAmount: Int         // 该商品对应的金币数额
    let priceUSD: Double         // 固定美元标价（不使用 priceLocale）
    let title: String
    var skProduct: AnyObject?    // 运行时从 SKProductsResponse 填充，弱关联避免强依赖
}

enum PurchaseStatus { case idle, purchasing, purchased, failed, restored, deferred }

struct PurchaseRecord {
    let id: String
    let productId: String
    let coinsGained: Int
    let status: PurchaseStatus
    let createdAt: Date
}
