//
//  SeedData.swift
//  Yorva
//
//  占位模拟数据集中独立管理（铁律：数据层规范 + 全局动态数据规范）
//  后续接入真实本地静态数据时仅修改本文件即可快速替换
//

import UIKit

enum SeedData {
    /// 预置测试账号（铁律 10）：123@gmail.com / 12345678
    static let prebuiltTestEmail = "123@gmail.com"
    static let prebuiltTestPassword = "12345678"

    /// 模拟用户池（不包含预置测试账号本身，账号登录后从该池随机选取 1 个作为默认关注对象）
    static func mockUsers() -> [User] {
        var users: [User] = []
        let names: [(String, String)] = [
            ("Aria Lee",     "AL"),
            ("Milo Chen",    "MC"),
            ("Iris Wang",    "IW"),
            ("Theo Park",    "TP"),
            ("Nora Fox",     "NF"),
            ("Rune Park",    "RP"),
            ("Sage Lin",     "SL"),
            ("Otto Hayes",  "OH")
        ]
        for (idx, (name, initials)) in names.enumerated() {
            users.append(User(
                id: "user-seed-\(idx)",
                email: "\(name.lowercased().replacingOccurrences(of: " ", with: ".")).seed@yorva.example",
                passwordDigest: "seed",
                nickname: name,
                avatarPlaceholderColor: UIColor.placeholderTint,
                avatarInitials: initials,
                bio: "Making room for less, one day at a time.",
                birthday: "1995-08-12",
                location: "Shanghai",
                gender: idx % 2 == 0 ? "Female" : "Male",
                isDeleted: false,
                coins: 120,
                diamonds: 0,
                isGuest: false
            ))
        }
        return users
    }

    /// 模拟主题
    static func mockThemes() -> [ThemeItem] {
        [
            ThemeItem(id: "theme-keep", title: "Keep",
                      desc: "Hold on to what truly matters.",
                      coverColor: AppTheme.olive,
                      postIds: ["post-theme-keep-1", "post-theme-keep-2"]),
            ThemeItem(id: "theme-habits", title: "Habits",
                      desc: "Small choices, big momentum.",
                      coverColor: AppTheme.coins,
                      postIds: ["post-theme-habits-1"]),
            ThemeItem(id: "theme-letgo", title: "Let go",
                      desc: "Release what no longer serves you.",
                      coverColor: AppTheme.primary,
                      postIds: ["post-theme-letgo-1", "post-theme-letgo-2"]),
            ThemeItem(id: "theme-lesstech", title: "Less tech",
                      desc: "Be where you are, not where your screen is.",
                      coverColor: AppTheme.diamonds,
                      postIds: ["post-theme-lesstech-1"])
        ]
    }

    /// 模拟 Prompt
    static func mockPrompts() -> [PromptItem] {
        [
            PromptItem(id: "p-free-1", title: "What did you keep today?", themeId: "theme-keep", costType: .free, costAmount: 0, isUsed: false),
            PromptItem(id: "p-free-2", title: "One habit you're keeping this week?", themeId: "theme-habits", costType: .free, costAmount: 0, isUsed: false),
            PromptItem(id: "p-free-3", title: "What are you letting go of tonight?", themeId: "theme-letgo", costType: .free, costAmount: 0, isUsed: false),
            PromptItem(id: "p-paid-1", title: "A small ritual for a calmer morning", themeId: "theme-keep", costType: .coins, costAmount: 300, isUsed: false),
            PromptItem(id: "p-paid-2", title: "The screen-free hour that changed my day", themeId: "theme-lesstech", costType: .coins, costAmount: 300, isUsed: false),
            PromptItem(id: "p-paid-3", title: "One thing you stopped buying", themeId: "theme-letgo", costType: .coins, costAmount: 300, isUsed: false),
            PromptItem(id: "p-paid-4", title: "A habit you broke gently", themeId: "theme-habits", costType: .coins, costAmount: 300, isUsed: false),
            PromptItem(id: "p-paid-5", title: "The comfort you kept instead of consuming", themeId: "theme-keep", costType: .coins, costAmount: 300, isUsed: false)
        ]
    }

    /// 模拟帖子
    static func mockPosts(users: [User]) -> [Post] {
        let now = Date()
        var posts: [Post] = []
        let samples: [(authorIdx: Int, promptId: String?, themeId: String?, mediaKind: PostMedia.Kind, ratio: CGFloat, answer: String, hoursAgo: Double, likes: Int, comments: Int)] = [
            (0, "p-free-1", "theme-keep", .image, 1.5, "Kept my morning slow. No phone, just tea and the window.", 1.5, 24, 3),
            (1, "p-free-2", "theme-habits", .image, 1.0, "Drank water before coffee for the third day. Small, but mine.", 3.2, 18, 1),
            (2, "p-free-3", "theme-letgo", .image, 1.4, "Let go of one subscription I never used. Feels lighter already.", 5.0, 41, 5),
            (3, "p-paid-1", "theme-keep", .image, 1.6, "Slow morning ritual: warm light, one page, no notifications.", 8.0, 12, 2),
            (4, "p-paid-2", "theme-lesstech", .video, 1.78, 12.0, "Closed the laptop for an hour and walked. Wild how loud the quiet is.", 22, 36, 7),
            (5, "p-free-1", "theme-keep", .image, 1.0, "Kept a promise to myself today. Just one, but I kept it.", 26, 9, 0)
        ]
        for (i, s) in samples.enumerated() {
            let author = users[s.authorIdx]
            let media = PostMedia(
                kind: s.mediaKind,
                aspectRatio: s.ratio,
                duration: s.mediaKind == .video ? s.hoursAgo != 12.0 ? 18 : 12 : nil,
                placeholderColor: author.avatarPlaceholderColor
            )
            posts.append(Post(
                id: "post-seed-\(i)",
                authorId: author.id,
                promptId: s.promptId,
                themeId: s.themeId,
                media: media,
                answer: s.answer,
                createdAt: now.addingTimeInterval(-s.hoursAgo * 3600),
                likeCount: s.likes,
                commentCount: s.comments,
                isLiked: i % 3 == 0,
                isSaved: i == 2,
                isVisible: true
            ))
        }
        return posts
    }

    /// 模拟评论
    static func mockComments(users: [User], posts: [Post]) -> [Comment] {
        let now = Date()
        var out: [Comment] = []
        for (i, post) in posts.enumerated() where i < 4 {
            for j in 0...min(2, max(0, post.commentCount - 1)) {
                let author = users[(i + j) % users.count]
                out.append(Comment(
                    id: "comment-\(post.id)-\(j)",
                    postId: post.id,
                    authorId: author.id,
                    text: ["This hit. Thank you for writing it.", "Needed this today.", "Saving for later."][j % 3],
                    createdAt: now.addingTimeInterval(-Double(j + 1) * 600),
                    isVisible: true
                ))
            }
        }
        return out
    }

    /// 模拟会话（不与预置账号绑定，仅作为会话列表占位；登录后自动接管当前账号）
    static func mockConversations(users: [User]) -> [Conversation] {
        let now = Date()
        var convs: [Conversation] = []
        for (i, user) in users.enumerated() where i < 3 {
            let msg = ChatMessage(
                id: "msg-seed-\(i)",
                conversationId: "conv-seed-\(i)",
                senderId: user.id,
                type: .text,
                text: ["Morning walk, no phone. You?", "Did you keep the ritual today?", "Let go of one thing tonight?"][i % 3],
                imageColor: nil,
                imageRatio: nil,
                voiceDuration: nil,
                isPlayed: false,
                createdAt: now.addingTimeInterval(-Double(i + 1) * 1800)
            )
            convs.append(Conversation(
                id: "conv-seed-\(i)",
                participantIds: [user.id],
                lastMessage: msg,
                unreadCount: i,
                isYorvaAI: false
            ))
        }
        return convs
    }
}
