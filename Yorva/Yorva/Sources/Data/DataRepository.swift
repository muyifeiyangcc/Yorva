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
        if let u = users.first(where: { $0.id == id }) { return u }
        if let cur = AccountManager.shared.currentUser, cur.id == id { return cur }
        return nil
    }

    /// 重置全部数据（调试 / 数据解析异常兜底）
    func resetAll() {
        users = SeedData.mockUsers()
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
