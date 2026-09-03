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
}

// MARK: - Post

struct PostMedia {
    enum Kind { case image, video }
    let kind: Kind
    let aspectRatio: CGFloat    // 原比例宽高比（图片按原比例显示，铁律 11）
    let duration: TimeInterval? // 视频时长
    let placeholderColor: UIColor
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
}

struct Conversation {
    let id: String
    let participantIds: [String]   // 两个用户 id（Yorva AI 会话固定 ["self","yorva-ai"]）
    var lastMessage: ChatMessage?
    var unreadCount: Int
    var isYorvaAI: Bool
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
