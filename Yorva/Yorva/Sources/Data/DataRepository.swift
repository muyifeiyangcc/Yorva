//
//  DataRepository.swift
//  Yorva
//
//  数据仓库统一入口（铁律 8 数据架构要求）
//  全部页面仅依赖本仓库；修改行为仅操作数据源；页面自动响应刷新
//  通知中心驱动跨页面状态联动，避免页面单独写死数据
//

import Foundation
import UIKit

// MARK: - 数据变更事件

enum DataEvent {
    case profileUpdated
    case sessionCleared
    case walletUpdated
    case followChanged
    case blockListChanged
    case reportSubmitted
    case postsUpdated
    case postInteracted(postId: String)
    case commentsUpdated(postId: String)
    case chatUpdated(conversationId: String)
    case voicePlaybackChanged(messageId: String)
}

final class DataRepository {

    static let shared = DataRepository()

    private(set) var users: [User] = []

    /// 通知名映射（让外部页面通过 NotificationCenter 监听）
    private let notificationName = Notification.Name("yorva.data.didChange")

    private init() {
        users = SeedData.mockUsers()
    }

    func user(by id: String) -> User? {
        if let u = users.first(where: { $0.id == id && !$0.isDeleted }) { return u }
        if let account = AccountManager.shared.accounts.first(where: { $0.id == id && !$0.isDeleted }) { return account }
        return nil
    }

    /// 将注册/编辑后的账号同步到统一用户仓库，保证跨页面、跨账号都能解析头像和资料。
    func upsertUser(_ user: User) {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            users.append(user)
            return
        }
        users[index] = user
    }

    /// 重置全部数据（调试 / 数据解析异常兜底）
    func resetAll() {
        users = SeedData.mockUsers()
        AccountManager.shared.accounts.forEach { upsertUser($0) }
        ContentManager.shared.reloadSeed()
        ChatManager.shared.reloadSeed()
    }

    // MARK: - 广播与订阅

    func broadcast(_ event: DataEvent) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: self.notificationName, object: event)
        }
    }

    func subscribe(_ block: @escaping (DataEvent) -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: .main) { note in
            if let event = note.object as? DataEvent { block(event) }
        }
    }

    func unsubscribe(_ token: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(token)
    }
}
