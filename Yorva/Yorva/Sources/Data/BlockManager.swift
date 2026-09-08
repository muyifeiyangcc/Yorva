//
//  BlockManager.swift
//  Yorva
//
//

import Foundation

final class BlockManager {

    static let shared = BlockManager()

    private let key = "yorva.block.relations.v2"
    private var relationsByUser: [String: [BlockEntry]] = [:]

    private init() { load() }

    var blockedIds: [String] { entriesForCurrentUser().map(\.blockedId) }

    func isBlocked(_ userId: String) -> Bool { blockedIds.contains(userId) }

    func blockedAt(_ userId: String) -> Date? {
        entriesForCurrentUser().first { $0.blockedId == userId }?.createdAt
    }

    func block(blockerId: String, blockedId: String) {
        var entries = relationsByUser[blockerId] ?? []
        guard !entries.contains(where: { $0.blockedId == blockedId }) else { return }
        entries.append(BlockEntry(blockedId: blockedId, createdAt: Date()))
        relationsByUser[blockerId] = entries
        persist()
        DataRepository.shared.broadcast(.blockListChanged)
    }

    func unblock(_ userId: String) {
        let key = currentUserKey
        relationsByUser[key, default: []].removeAll { $0.blockedId == userId }
        persist()
        DataRepository.shared.broadcast(.blockListChanged)
    }

    func filterPosts(_ posts: [Post]) -> [Post] { posts.filter { !isBlocked($0.authorId) } }
    func filterComments(_ comments: [Comment]) -> [Comment] { comments.filter { !isBlocked($0.authorId) } }

    func filterConversations(_ convs: [Conversation]) -> [Conversation] {
        convs.filter { conv in
            let otherIds = conv.participantIds.filter { $0 != AccountManager.shared.currentUser?.id }
            return !otherIds.contains { isBlocked($0) }
        }
    }

    func removeUserState(_ userId: String) {
        relationsByUser.removeValue(forKey: userId)
        relationsByUser = relationsByUser.mapValues { $0.filter { $0.blockedId != userId } }
        persist()
    }

    private var currentUserKey: String { AccountManager.shared.currentUser?.id ?? "guest" }

    private func entriesForCurrentUser() -> [BlockEntry] {
        relationsByUser[currentUserKey] ?? []
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: [BlockEntry]].self, from: data) {
            relationsByUser = decoded
            return
        }
        if let old = UserDefaults.standard.stringArray(forKey: "yorva.block.list.v1"), !old.isEmpty {
            relationsByUser[currentUserKey] = old.map { BlockEntry(blockedId: $0, createdAt: Date()) }
            persist()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(relationsByUser) { UserDefaults.standard.set(data, forKey: key) }
    }
}

private struct BlockEntry: Codable {
    let blockedId: String
    let createdAt: Date
}
