//
//  DataRepository.swift
//  Yorva
//
//

import Foundation
import UIKit


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

    private let notificationName = Notification.Name("yorva.data.didChange")

    private init() {
        users = SeedData.mockUsers()
    }

    func user(by id: String) -> User? {
        if let u = users.first(where: { $0.id == id && !$0.isDeleted }) { return u }
        if let account = AccountManager.shared.accounts.first(where: { $0.id == id && !$0.isDeleted }) { return account }
        return nil
    }

    func upsertUser(_ user: User) {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            users.append(user)
            return
        }
        users[index] = user
    }

    func resetAll() {
        users = SeedData.mockUsers()
        AccountManager.shared.accounts.forEach { upsertUser($0) }
        ContentManager.shared.reloadSeed()
        ChatManager.shared.reloadSeed()
    }


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
