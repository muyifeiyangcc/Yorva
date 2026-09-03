//
//  ChatManager.swift
//  Yorva
//
//  聊天会话 / 消息 / Yorva AI 提问（铁律 8 + 铁律 11）
//

import Foundation
import UIKit

final class ChatManager {

    static let shared = ChatManager()

    private(set) var conversations: [Conversation] = []
    private(set) var messages: [ChatMessage] = []

    // Yorva AI 免费提问次数与单次金币消耗
    let yorvaAIFreeQuota = 3
    let yorvaAICostPerQuestion = 5
    private let yorvaQuotaKey = "yorva.ai.free.quota.v1"

    private init() {
        reloadSeed()
    }

    func reloadSeed() {
        conversations = SeedData.mockConversations(users: DataRepository.shared.users)
        messages = conversations.compactMap { $0.lastMessage }
        ensureYorvaAIConversation()
    }

    private func ensureYorvaAIConversation() {
        if !conversations.contains(where: { $0.isYorvaAI }) {
            conversations.append(Conversation(id: "conv-yorva-ai", participantIds: ["yorva-ai"],
                                              lastMessage: nil, unreadCount: 0, isYorvaAI: true))
        }
    }

    var yorvaRemainingFree: Int {
        let used = UserDefaults.standard.integer(forKey: yorvaQuotaKey)
        return max(0, yorvaAIFreeQuota - used)
    }

    func consumeYorvaFree() {
        let used = UserDefaults.standard.integer(forKey: yorvaQuotaKey)
        UserDefaults.standard.set(used + 1, forKey: yorvaQuotaKey)
    }

    // MARK: - Conversations

    func conversationsForCurrentUser() -> [Conversation] {
        // ChatList 已单独展示 Yorva AI 卡片，此处返回非 AI 会话，避免重复
        let nonAI = conversations.filter { !$0.isYorvaAI }
        return BlockManager.shared.filterConversations(nonAI)
            .sorted { ($0.lastMessage?.createdAt ?? Date.distantPast) > ($1.lastMessage?.createdAt ?? Date.distantPast) }
    }

    func conversation(by id: String) -> Conversation? { conversations.first { $0.id == id } }

    func messages(conversationId: String) -> [ChatMessage] {
        messages.filter { $0.conversationId == conversationId }.sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    func sendText(conversationId: String, senderId: String, text: String) -> ChatMessage {
        let msg = ChatMessage(id: "msg-\(messages.count + 1)", conversationId: conversationId,
                              senderId: senderId, type: .text, text: text,
                              imageColor: nil, imageRatio: nil, voiceDuration: nil,
                              isPlayed: false, createdAt: Date())
        appendMessage(msg, to: conversationId)
        return msg
    }

    @discardableResult
    func sendImage(conversationId: String, senderId: String, color: UIColor, ratio: CGFloat) -> ChatMessage {
        let msg = ChatMessage(id: "msg-\(messages.count + 1)", conversationId: conversationId,
                              senderId: senderId, type: .image, text: nil,
                              imageColor: color, imageRatio: ratio, voiceDuration: nil,
                              isPlayed: false, createdAt: Date())
        appendMessage(msg, to: conversationId)
        return msg
    }

    @discardableResult
    func sendVoice(conversationId: String, senderId: String, duration: TimeInterval) -> ChatMessage {
        let msg = ChatMessage(id: "msg-\(messages.count + 1)", conversationId: conversationId,
                              senderId: senderId, type: .voice, text: nil,
                              imageColor: nil, imageRatio: nil, voiceDuration: duration,
                              isPlayed: false, createdAt: Date())
        appendMessage(msg, to: conversationId)
        return msg
    }

    private func appendMessage(_ msg: ChatMessage, to convId: String) {
        messages.append(msg)
        if let idx = conversations.firstIndex(where: { $0.id == convId }) {
            conversations[idx].lastMessage = msg
        }
        DataRepository.shared.broadcast(.chatUpdated(conversationId: convId))
    }

    func markPlayed(messageId: String, played: Bool) {
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx].isPlayed = played
            DataRepository.shared.broadcast(.voicePlaybackChanged(messageId: messageId))
        }
    }

    func clearUnread(conversationId: String) {
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].unreadCount = 0
            DataRepository.shared.broadcast(.chatUpdated(conversationId: conversationId))
        }
    }

    // MARK: - Yorva AI

    /// Yorva AI 回复（占位生成器：根据用户提问生成简短回复）
    func yorvaAIReply(to question: String) -> String {
        let templates = [
            "That's a thoughtful prompt. Try keeping just one thing today and notice what changes.",
            "A small step counts. Pick the habit that feels easiest to keep this week.",
            "Less, but slower. Try a screen-free 10 minutes before bed tonight.",
            "Start by naming what you're ready to release. Naming makes it lighter."
        ]
        return templates.randomElement() ?? templates[0]
    }

    @discardableResult
    func sendYorvaAIQuestion(_ text: String) -> (user: ChatMessage, ai: ChatMessage) {
        let userMsg = ChatMessage(id: "msg-\(messages.count + 1)", conversationId: "conv-yorva-ai",
                                 senderId: AccountManager.shared.currentUser?.id ?? "self",
                                 type: .text, text: text,
                                 imageColor: nil, imageRatio: nil, voiceDuration: nil,
                                 isPlayed: false, createdAt: Date())
        appendMessage(userMsg, to: "conv-yorva-ai")
        let reply = yorvaAIReply(to: text)
        let aiMsg = ChatMessage(id: "msg-\(messages.count + 1)", conversationId: "conv-yorva-ai",
                                senderId: "yorva-ai", type: .text, text: reply,
                                imageColor: nil, imageRatio: nil, voiceDuration: nil,
                                isPlayed: false, createdAt: Date().addingTimeInterval(0.5))
        appendMessage(aiMsg, to: "conv-yorva-ai")
        return (userMsg, aiMsg)
    }
}
