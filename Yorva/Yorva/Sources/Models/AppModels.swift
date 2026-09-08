//
//  AppModels.swift
//  Yorva
//
//

import UIKit

// MARK: - User

struct User {
    var id: String
    var email: String
    var passwordDigest: String
    var nickname: String
    var avatarPlaceholderColor: UIColor
    var avatarInitials: String
    var bio: String
    var birthday: String
    var location: String
    var gender: String
    var isDeleted: Bool
    var coins: Int
    var diamonds: Int
    var isGuest: Bool
    var avatarImage: UIImage? = nil
    var avatarAssetName: String? = nil
}

// MARK: - Theme / Prompt

struct ThemeItem {
    let id: String
    let title: String
    let desc: String
    let coverColor: UIColor
    var postIds: [String]
}

enum PromptCostType { case free, coins }
struct PromptItem {
    let id: String
    let title: String
    let themeId: String?
    let costType: PromptCostType
    let costAmount: Int
    var isUsed: Bool
    var metadata: String = ""
}

// MARK: - Post

struct PostMedia {
    enum Kind { case image, video }
    let kind: Kind
    let aspectRatio: CGFloat
    let duration: TimeInterval?
    let placeholderColor: UIColor
    let image: UIImage?
    let videoURL: URL?
    let imageAssetName: String?
    let videoResourceName: String?

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

    var resolvedImage: UIImage? {
        if let image { return image }
        if let name = imageAssetName { return UIImage(named: name) }
        return nil
    }

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
    var isVisible: Bool
}

// MARK: - Comment

struct Comment {
    let id: String
    let postId: String
    let authorId: String
    var text: String
    var createdAt: Date
    var isVisible: Bool
}

// MARK: - Conversation / Message

enum MessageType { case text, image, voice }

struct ChatMessage {
    let id: String
    let conversationId: String
    let senderId: String         // self / other / "yorva-ai"
    var type: MessageType
    var text: String?
    var imageColor: UIColor?
    var imageRatio: CGFloat?
    var voiceDuration: TimeInterval?
    var isPlayed: Bool
    var createdAt: Date
    var image: UIImage? = nil
    var voiceURL: URL? = nil

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
    let participantIds: [String]
    var lastMessage: ChatMessage?
    var unreadCount: Int
    var isYorvaAI: Bool
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
    let coinsAmount: Int
    let priceUSD: Double
    let title: String
    var skProduct: AnyObject?
}

enum PurchaseStatus { case idle, purchasing, purchased, failed, restored, deferred }

struct PurchaseRecord {
    let id: String
    let productId: String
    let coinsGained: Int
    let status: PurchaseStatus
    let createdAt: Date
}
