//
//  BlockManager.swift
//  Yorva
//
//  拉黑业务（铁律 6、铁律 8 第 4 点）
//  本地持久化保存拉黑列表；拉黑生效后全页面实时过滤拉黑用户的帖子、评论、聊天消息
//  与举报逻辑完全独立，不互相调用
//

import Foundation

final class BlockManager {

    static let shared = BlockManager()

    private let key = "yorva.block.list.v1"
    private(set) var blockedIds: [String] = []

    private init() {
        blockedIds = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func isBlocked(_ userId: String) -> Bool { blockedIds.contains(userId) }

    /// 拉黑用户：本地持久化 + 全局广播，触发所有页面过滤刷新
    func block(blockerId: String, blockedId: String) {
        guard !blockedIds.contains(blockedId) else { return }
        blockedIds.append(blockedId)
        UserDefaults.standard.set(blockedIds, forKey: key)
        DataRepository.shared.broadcast(.blockListChanged)
    }

    /// 解除拉黑：内容重新可见
    func unblock(_ userId: String) {
        blockedIds.removeAll { $0 == userId }
        UserDefaults.standard.set(blockedIds, forKey: key)
        DataRepository.shared.broadcast(.blockListChanged)
    }

    /// 全局过滤拉黑用户的帖子（铁律：拉黑后不展示该用户发布的任何内容）
    func filterPosts(_ posts: [Post]) -> [Post] {
        posts.filter { post in
            !blockedIds.contains(post.authorId)
        }
    }

    /// 全局过滤拉黑用户的评论
    func filterComments(_ comments: [Comment]) -> [Comment] {
        comments.filter { c in !blockedIds.contains(c.authorId) }
    }

    /// 全局过滤拉黑用户的会话（聊天消息实时过滤）
    func filterConversations(_ convs: [Conversation]) -> [Conversation] {
        convs.filter { conv in
            let otherIds = conv.participantIds.filter { $0 != AccountManager.shared.currentUser?.id }
            return !otherIds.contains { blockedIds.contains($0) }
        }
    }
}
