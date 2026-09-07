//
//  FollowManager.swift
//  Yorva
//
//  关注 / 取消关注（铁律 8 状态联动）
//

import Foundation

final class FollowManager {

    static let shared = FollowManager()

    private let key = "yorva.follow.relations.v1"
    private(set) var relations: [FollowRelation] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([FollowDTO].self, from: data) {
            relations = decoded.map { $0.toRelation() }
        }
    }

    @discardableResult
    func follow(followerId: String, followeeId: String) -> FollowRelation {
        guard !relations.contains(where: { $0.followerId == followerId && $0.followeeId == followeeId }) else {
            return relations.first(where: { $0.followerId == followerId && $0.followeeId == followeeId })!
        }
        let r = FollowRelation(followerId: followerId, followeeId: followeeId, createdAt: Date())
        relations.append(r)
        persist()
        DataRepository.shared.broadcast(.followChanged)
        return r
    }

    func unfollow(followerId: String, followeeId: String) {
        relations.removeAll { $0.followerId == followerId && $0.followeeId == followeeId }
        persist()
        DataRepository.shared.broadcast(.followChanged)
    }

    func isFollowing(followerId: String, followeeId: String) -> Bool {
        relations.contains { $0.followerId == followerId && $0.followeeId == followeeId }
    }

    func following(userId: String) -> [String] {
        relations.filter { $0.followerId == userId }.map { $0.followeeId }
    }

    func followers(userId: String) -> [String] {
        relations.filter { $0.followeeId == userId }.map { $0.followerId }
    }

    func removeRelations(for userId: String) {
        relations.removeAll { $0.followerId == userId || $0.followeeId == userId }
        persist()
        DataRepository.shared.broadcast(.followChanged)
    }

    private func persist() {
        let dtos = relations.map { FollowDTO(from: $0) }
        if let data = try? JSONEncoder().encode(dtos) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

private struct FollowDTO: Codable {
    let followerId: String
    let followeeId: String
    let createdAt: TimeInterval
    init(from r: FollowRelation) {
        followerId = r.followerId; followeeId = r.followeeId
        createdAt = r.createdAt.timeIntervalSince1970
    }
    func toRelation() -> FollowRelation {
        FollowRelation(followerId: followerId, followeeId: followeeId,
                       createdAt: Date(timeIntervalSince1970: createdAt))
    }
}
