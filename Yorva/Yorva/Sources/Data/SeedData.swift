//
//  SeedData.swift
//  Yorva
//
//

import UIKit

enum SeedData {
    static let prebuiltTestEmail = "123@gmail.com"
    static let prebuiltTestPassword = "12345678"


    static func mockUsers() -> [User] {
        [
            User(id: "user-jamie",
                 email: "jamie.m@yorva.app", passwordDigest: "seed",
                 nickname: "Jamie M.",
                 avatarPlaceholderColor: AppTheme.cream,
                 avatarInitials: "JM",
                 bio: "Embracing clean lines, clutter-free spaces, and quiet intentional living.",
                 birthday: "", location: "", gender: "",
                 isDeleted: false, coins: 0, diamonds: 0, isGuest: false,
                 avatarImage: nil,
                 avatarAssetName: "ca39bfd7ff70dc94c48efd8a410629f6"),
            User(id: "user-elena",
                 email: "elena.vance@yorva.app", passwordDigest: "seed",
                 nickname: "Elena Vance",
                 avatarPlaceholderColor: AppTheme.cream,
                 avatarInitials: "EV",
                 bio: "Slow living, capsule wardrobes, and mindful consumption.",
                 birthday: "", location: "", gender: "",
                 isDeleted: false, coins: 0, diamonds: 0, isGuest: false,
                 avatarImage: nil,
                 avatarAssetName: "741a425b2f1de142fc3654e14c6278cd"),
            User(id: "user-sven",
                 email: "sven.lindqvist@yorva.app", passwordDigest: "seed",
                 nickname: "Sven Lindqvist",
                 avatarPlaceholderColor: AppTheme.cream,
                 avatarInitials: "SL",
                 bio: "Finding peace through functional design and quiet daily rituals.",
                 birthday: "", location: "", gender: "",
                 isDeleted: false, coins: 0, diamonds: 0, isGuest: false,
                 avatarImage: nil,
                 avatarAssetName: "79dbc81de3ea4f6345caa66cc73ec574"),
            User(id: "user-nora",
                 email: "nora.fischer@yorva.app", passwordDigest: "seed",
                 nickname: "Nora Fischer",
                 avatarPlaceholderColor: AppTheme.cream,
                 avatarInitials: "NF",
                 bio: "Digital minimalism, quiet mornings, and living with purpose.",
                 birthday: "", location: "", gender: "",
                 isDeleted: false, coins: 0, diamonds: 0, isGuest: false,
                 avatarImage: nil,
                 avatarAssetName: "26c08b39d0f87f7f50b03ad72e60db7e"),
            User(id: "user-felix",
                 email: "felix.gruber@yorva.app", passwordDigest: "seed",
                 nickname: "Felix Gruber",
                 avatarPlaceholderColor: AppTheme.cream,
                 avatarInitials: "FG",
                 bio: "Exploring zero-waste habits and simple architectural lines.",
                 birthday: "", location: "", gender: "",
                 isDeleted: false, coins: 0, diamonds: 0, isGuest: false,
                 avatarImage: nil,
                 avatarAssetName: "0afc730f2fa9b7977e6a7f5994864666"),
            User(id: "user-mateo",
                 email: "mateo.ross@yorva.app", passwordDigest: "seed",
                 nickname: "Mateo Ross",
                 avatarPlaceholderColor: AppTheme.cream,
                 avatarInitials: "MR",
                 bio: "Documenting understated aesthetics and timeless functional objects.",
                 birthday: "", location: "", gender: "",
                 isDeleted: false, coins: 0, diamonds: 0, isGuest: false,
                 avatarImage: nil,
                 avatarAssetName: "b9290e4acf1eb8d83f8c49b511b670f0")
        ]
    }


    static func mockThemes() -> [ThemeItem] {
        [
            ThemeItem(id: "theme-keep", title: "Keep",
                      desc: "Hold on to what truly matters.",
                      coverColor: AppTheme.olive,
                      postIds: []),
            ThemeItem(id: "theme-habits", title: "Habits",
                      desc: "Small choices, big momentum.",
                      coverColor: AppTheme.coins,
                      postIds: []),
            ThemeItem(id: "theme-letgo", title: "Let go",
                      desc: "Release what no longer serves you.",
                      coverColor: AppTheme.primary,
                      postIds: [])
        ]
    }


    static func mockPrompts() -> [PromptItem] {
        [
            PromptItem(id: "p-free-keep", title: "What do you choose to keep?",
                       themeId: "theme-keep", costType: .free, costAmount: 0, isUsed: false,
                       metadata: "Keep · Personal choice"),
            PromptItem(id: "p-free-habits", title: "Which habit makes your day feel simpler?",
                       themeId: "theme-habits", costType: .free, costAmount: 0, isUsed: false,
                       metadata: "Habits · Everyday"),
            PromptItem(id: "p-free-letgo", title: "What are you ready to let go of this week?",
                       themeId: "theme-letgo", costType: .free, costAmount: 0, isUsed: false,
                       metadata: "Let go · Reflection"),
            PromptItem(id: "p-paid-1", title: "What space in your home brings you the most inner peace?",
                       themeId: nil, costType: .coins, costAmount: 300, isUsed: false,
                       metadata: "Space · Inner peace"),
            PromptItem(id: "p-paid-2", title: "What is one item you use every single day that you truly value?",
                       themeId: nil, costType: .coins, costAmount: 300, isUsed: false,
                       metadata: "Objects · Daily value"),
            PromptItem(id: "p-paid-3", title: "What is your most effective rule for setting digital boundaries?",
                       themeId: nil, costType: .coins, costAmount: 300, isUsed: false,
                       metadata: "Digital · Boundaries"),
            PromptItem(id: "p-paid-4", title: "What was the hardest thing for you to let go of this month?",
                       themeId: nil, costType: .coins, costAmount: 300, isUsed: false,
                       metadata: "Let go · Monthly"),
            PromptItem(id: "p-paid-5", title: "How do you start your morning without feeling rushed or overwhelmed?",
                       themeId: nil, costType: .coins, costAmount: 300, isUsed: false,
                       metadata: "Morning · Routine")
        ]
    }


    static func mockPosts(users: [User]) -> [Post] {
        let now = Date()
        let day: TimeInterval = 24 * 3600
        let samples: [(authorId: String, promptId: String, themeId: String,
                       media: PostMedia, answer: String, daysAgo: Double, commentCount: Int)] = [
            ("user-jamie", "p-free-habits", "theme-habits",
             PostMedia(kind: .image,
                       aspectRatio: 736.0 / 1107.0, duration: nil,
                       placeholderColor: AppTheme.cream,
                       imageAssetName: "472c8e735e6d768744bd949387dadaf4"),
             "Resetting my workspace every morning. Keeping only the essentials brings instant clarity to my mind.",
             6, 0),
            ("user-elena", "p-free-keep", "theme-keep",
             PostMedia(kind: .image,
                       aspectRatio: 736.0 / 1097.0, duration: nil,
                       placeholderColor: AppTheme.cream,
                       imageAssetName: "69f6cb701cd9741c1e937b195626f27e"),
             "Streamlining my wardrobe to 10 core items. Less time deciding in the morning, more energy for living.",
             5, 1),
            ("user-sven", "p-free-letgo", "theme-letgo",
             PostMedia(kind: .video,
                       aspectRatio: 720.0 / 1290.0, duration: 5.04,
                       placeholderColor: AppTheme.cream,
                       videoResourceName: "17c483f3828706660b444a35c4c197db_720w"),
             "Stepping away from all digital screens after work and pouring warm tea in complete silence to reflect.",
             4, 0),
            ("user-nora", "p-free-habits", "theme-habits",
             PostMedia(kind: .image,
                       aspectRatio: 736.0 / 1104.0, duration: nil,
                       placeholderColor: AppTheme.cream,
                       imageAssetName: "856f29ff99c67135c2bc3b64a927d769"),
             "Clearing out one single drawer at a time. Small steps toward a simpler, more intentional living environment.",
             3, 1),
            ("user-felix", "p-free-keep", "theme-keep",
             PostMedia(kind: .video,
                       aspectRatio: 720.0 / 1280.0, duration: 13.4,
                       placeholderColor: AppTheme.cream,
                       videoResourceName: "cd14f7a1acc0ddbeb74a3a0477f6f6af_720w"),
             "Keeping the peaceful geometric sunlight and window shadows in my living room. Simple forms bring comfort.",
             2, 1),
            ("user-mateo", "p-free-letgo", "theme-letgo",
             PostMedia(kind: .image,
                       aspectRatio: 736.0 / 1311.0, duration: nil,
                       placeholderColor: AppTheme.cream,
                       imageAssetName: "36682ddb66d7848318aae23561a873f5"),
             "Letting go of unnecessary visual noise and embracing monochrome tones to improve daily mental focus.",
             1, 1)
        ]
        return samples.enumerated().map { index, s in
            Post(id: "post-seed-\(index + 1)",
                 authorId: s.authorId,
                 promptId: s.promptId,
                 themeId: s.themeId,
                 media: s.media,
                 answer: s.answer,
                 createdAt: now.addingTimeInterval(-s.daysAgo * day),
                 likeCount: 0,
                 commentCount: s.commentCount,
                 isLiked: false,
                 isSaved: false,
                 isVisible: true)
        }
    }


    static func mockComments(users: [User], posts: [Post]) -> [Comment] {
        let now = Date()
        let hour: TimeInterval = 3600
        let rows: [(postAuthorId: String, commentAuthorId: String, text: String)] = [
            ("user-elena", "user-jamie", "Less is more."),
            ("user-nora", "user-sven", "Simply beautiful."),
            ("user-felix", "user-mateo", "Love this vibe."),
            ("user-mateo", "user-elena", "Clean and calm.")
        ]
        var out: [Comment] = []
        for (i, row) in rows.enumerated() {
            guard let post = posts.first(where: { $0.authorId == row.postAuthorId }) else { continue }
            out.append(Comment(
                id: "comment-seed-\(i + 1)",
                postId: post.id,
                authorId: row.commentAuthorId,
                text: row.text,
                createdAt: post.createdAt.addingTimeInterval(2 * hour),
                isVisible: true
            ))
        }
        return out
    }

    static func mockConversations(users: [User]) -> [Conversation] {
        []
    }
}
