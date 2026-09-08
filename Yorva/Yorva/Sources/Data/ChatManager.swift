//
//  ChatManager.swift
//  Yorva
//
//

import Foundation
import UIKit

final class ChatManager {

    static let shared = ChatManager()

    private(set) var conversations: [Conversation] = []
    private(set) var messages: [ChatMessage] = []
    let yorvaAIFreeQuota = 3
    let yorvaAICostPerQuestion = 10

    private let storeKey = "yorva.chat.store.v3"
    private let quotaKey = "yorva.ai.free.quota.by.user.v2"
    private var quotaByUser: [String: Int] = [:]
    private var loadedUserKey: String?

    private init() {
        loadQuota()
        reloadSeed()
    }

    private var activeUserKey: String { AccountManager.shared.currentUser?.id ?? "guest" }

    func reloadSeed() {
        loadedUserKey = nil
        ensureLoadedForCurrentUser()
    }

    private func ensureLoadedForCurrentUser() {
        let key = activeUserKey
        guard loadedUserKey != key else { return }
        loadedUserKey = key
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let all = try? JSONDecoder().decode([String: ChatStoreDTO].self, from: data),
           let store = all[key] {
            conversations = store.conversations.map { $0.toConversation() }
            messages = store.messages.map { $0.toMessage() }
        } else {
            conversations = SeedData.mockConversations(users: DataRepository.shared.users).map {
                var copy = $0; copy.ownerId = key; return copy
            }
            messages = conversations.compactMap { $0.lastMessage }
            ensureYorvaAIConversation()
            persist()
        }
        ensureYorvaAIConversation()
        ensureYorvaAIGreeting()
    }

    private func ensureYorvaAIConversation() {
        guard !conversations.contains(where: { $0.isYorvaAI }) else { return }
        conversations.append(Conversation(id: "conv-yorva-ai", participantIds: [activeUserKey, "yorva-ai"],
                                          lastMessage: nil, unreadCount: 0, isYorvaAI: true, ownerId: activeUserKey))
    }

    /// Keep the first view useful even before the user has sent a question.
    /// This is persisted with the same account-scoped chat store as the rest
    /// of the conversation, so it is created only once per account.
    private func ensureYorvaAIGreeting() {
        let conversationId = "conv-yorva-ai"
        guard !messages.contains(where: { $0.conversationId == conversationId }) else { return }
        let greeting = ChatMessage(id: "msg-yorva-ai-greeting-\(activeUserKey)",
                                   conversationId: conversationId,
                                   senderId: "yorva-ai",
                                   type: .text,
                                   text: "What would you like to simplify today?",
                                   imageColor: nil,
                                   imageRatio: nil,
                                   voiceDuration: nil,
                                   isPlayed: false,
                                   createdAt: Date())
        messages.append(greeting)
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].lastMessage = greeting
        }
        persist()
    }

    var yorvaRemainingFree: Int {
        ensureLoadedForCurrentUser()
        return max(0, yorvaAIFreeQuota - (quotaByUser[activeUserKey] ?? 0))
    }

    func consumeYorvaFree() {
        ensureLoadedForCurrentUser()
        quotaByUser[activeUserKey, default: 0] += 1
        persistQuota()
    }

    // MARK: - Conversations

    func conversationsForCurrentUser() -> [Conversation] {
        ensureLoadedForCurrentUser()
        let nonAI = conversations.filter { !$0.isYorvaAI && ($0.ownerId == nil || $0.ownerId == activeUserKey) }
        return BlockManager.shared.filterConversations(nonAI).sorted {
            ($0.lastMessage?.createdAt ?? Date.distantPast) > ($1.lastMessage?.createdAt ?? Date.distantPast)
        }
    }

    func conversation(by id: String) -> Conversation? {
        ensureLoadedForCurrentUser()
        return conversations.first { $0.id == id }
    }

    func registerConversation(_ conversation: Conversation) {
        ensureLoadedForCurrentUser()
        guard !conversations.contains(where: { $0.id == conversation.id }) else { return }
        var copy = conversation
        copy.ownerId = activeUserKey
        conversations.append(copy)
        persist()
    }

    func messages(conversationId: String) -> [ChatMessage] {
        ensureLoadedForCurrentUser()
        return messages.filter { $0.conversationId == conversationId }.sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    func sendText(conversationId: String, senderId: String, text: String) -> ChatMessage {
        ensureLoadedForCurrentUser()
        let msg = ChatMessage(id: "msg-\(UUID().uuidString)", conversationId: conversationId, senderId: senderId,
                              type: .text, text: text, imageColor: nil, imageRatio: nil,
                              voiceDuration: nil, isPlayed: false, createdAt: Date())
        appendMessage(msg, to: conversationId); return msg
    }

    @discardableResult
    func sendImage(conversationId: String, senderId: String, color: UIColor, ratio: CGFloat,
                   image: UIImage? = nil) -> ChatMessage {
        ensureLoadedForCurrentUser()
        let msg = ChatMessage(id: "msg-\(UUID().uuidString)", conversationId: conversationId, senderId: senderId,
                              type: .image, text: nil, imageColor: color, imageRatio: ratio,
                              voiceDuration: nil, isPlayed: false, createdAt: Date(), image: image)
        appendMessage(msg, to: conversationId); return msg
    }

    @discardableResult
    func sendVoice(conversationId: String, senderId: String, duration: TimeInterval,
                   audioURL: URL? = nil) -> ChatMessage {
        ensureLoadedForCurrentUser()
        let durableAudioURL = persistAudioFile(audioURL)
        let msg = ChatMessage(id: "msg-\(UUID().uuidString)", conversationId: conversationId, senderId: senderId,
                              type: .voice, text: nil, imageColor: nil, imageRatio: nil,
                              voiceDuration: duration, isPlayed: false, createdAt: Date(), voiceURL: durableAudioURL)
        appendMessage(msg, to: conversationId); return msg
    }

    private func appendMessage(_ msg: ChatMessage, to convId: String) {
        if !conversations.contains(where: { $0.id == convId }) {
            conversations.append(Conversation(id: convId, participantIds: [], lastMessage: nil,
                                              unreadCount: 0, isYorvaAI: false, ownerId: activeUserKey))
        }
        messages.append(msg)
        if let idx = conversations.firstIndex(where: { $0.id == convId }) { conversations[idx].lastMessage = msg }
        persist()
        DataRepository.shared.broadcast(.chatUpdated(conversationId: convId))
    }

    func markPlayed(messageId: String, played: Bool) {
        ensureLoadedForCurrentUser()
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx].isPlayed = played
            persist()
            DataRepository.shared.broadcast(.voicePlaybackChanged(messageId: messageId))
        }
    }

    func clearUnread(conversationId: String) {
        ensureLoadedForCurrentUser()
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].unreadCount = 0
            persist()
            DataRepository.shared.broadcast(.chatUpdated(conversationId: conversationId))
        }
    }

    func removeUserState(_ userId: String) {
        let key = userId
        var all: [String: ChatStoreDTO] = [:]
        if let data = UserDefaults.standard.data(forKey: storeKey), let old = try? JSONDecoder().decode([String: ChatStoreDTO].self, from: data) { all = old }
        all.removeValue(forKey: key)
        if let data = try? JSONEncoder().encode(all) { UserDefaults.standard.set(data, forKey: storeKey) }
        quotaByUser.removeValue(forKey: key)
        persistQuota()
        if key == activeUserKey { conversations = []; messages = []; loadedUserKey = nil }
    }

    // MARK: - Yorva AI

    func yorvaAIReply(to question: String) -> String {
        let normalized = question
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
        let tokens = Set(normalized.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        var bestScore = 0
        var bestResponse: String?

        for rule in yorvaAIResponseRules {
            let score = rule.keywords.reduce(into: 0) { result, keyword in
                if keyword.contains(" ") ? normalized.contains(keyword) : tokens.contains(keyword) { result += 1 }
            }
            if score > bestScore {
                bestScore = score
                bestResponse = rule.response
            }
        }

        return bestResponse ?? yorvaAIFallbackResponse
    }

    /// Short, intentionally conservative guidance for the most common Yorva
    /// themes. Matching is deterministic and keyword-based so a question
    /// never receives an unrelated or invented answer.
    private struct AIResponseRule {
        let keywords: [String]
        let response: String
    }

    private let yorvaAIResponseRules: [AIResponseRule] = [
        AIResponseRule(keywords: ["rush", "morning", "time"], response: "Choose one thing to do more slowly this morning, and let the rest wait its turn."),
        AIResponseRule(keywords: ["stress", "anxious", "overwhelm", "overwhelmed"], response: "Name the next small step, then give yourself permission to do only that for now."),
        AIResponseRule(keywords: ["sleep", "night", "bed", "rest"], response: "Make the last ten minutes of your day quieter: dim the lights, put your phone away, and breathe."),
        AIResponseRule(keywords: ["phone", "screen", "notification", "digital"], response: "Put your phone out of reach for one short block and notice what becomes easier to hear."),
        AIResponseRule(keywords: ["habit", "routine", "consistent", "consistency"], response: "Make the habit easy enough to keep on an ordinary day; consistency grows from that starting point."),
        AIResponseRule(keywords: ["let go", "release", "stop", "carry"], response: "Ask what you can stop carrying today. One honest boundary can make room for the next thing."),
        AIResponseRule(keywords: ["focus", "work", "productive", "productivity"], response: "Protect one short, distraction-free block and choose a single finish line for it."),
        AIResponseRule(keywords: ["clutter", "clean", "space", "mess"], response: "Remove one thing you no longer use. A little open space can change how the whole room feels."),
        AIResponseRule(keywords: ["decision", "choose", "choice", "should"], response: "Give yourself two simple options, pick the kinder one, and let that be enough for today."),
        AIResponseRule(keywords: ["relationship", "friend", "family", "talk", "conversation"], response: "Make room for one clear, kind sentence. Honest communication usually starts smaller than expected."),
        AIResponseRule(keywords: ["create", "creative", "idea", "write", "make"], response: "Start with an imperfect version. You can shape a real idea more easily than an imagined perfect one."),
        AIResponseRule(keywords: ["busy", "tired", "energy"], response: "Rest is part of the work. Pick the task that matters most and leave a little energy for yourself."),
        AIResponseRule(keywords: ["grateful", "gratitude", "good", "joy"], response: "Keep one small detail from today in mind. Paying attention is a simple way to make it last."),
        AIResponseRule(keywords: ["future", "change", "plan", "next"], response: "You do not need a complete plan. Choose the next honest step and let it show you what follows.")
    ]

    private let yorvaAIFallbackResponse = "Start with one small choice you can make today, and notice what feels a little lighter afterward."

    @discardableResult
    func sendYorvaAIQuestion(_ text: String) -> (user: ChatMessage, ai: ChatMessage) {
        ensureLoadedForCurrentUser()
        let sender = AccountManager.shared.currentUser?.id ?? "self"
        let userMsg = ChatMessage(id: "msg-\(UUID().uuidString)", conversationId: "conv-yorva-ai", senderId: sender,
                                  type: .text, text: text, imageColor: nil, imageRatio: nil,
                                  voiceDuration: nil, isPlayed: false, createdAt: Date())
        appendMessage(userMsg, to: "conv-yorva-ai")
        let aiMsg = ChatMessage(id: "msg-\(UUID().uuidString)", conversationId: "conv-yorva-ai", senderId: "yorva-ai",
                                type: .text, text: yorvaAIReply(to: text), imageColor: nil, imageRatio: nil,
                                voiceDuration: nil, isPlayed: false, createdAt: Date().addingTimeInterval(0.5))
        appendMessage(aiMsg, to: "conv-yorva-ai")
        return (userMsg, aiMsg)
    }

    // MARK: - Persistence

    private func loadQuota() {
        if let data = UserDefaults.standard.data(forKey: quotaKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) { quotaByUser = decoded }
    }

    private func persistQuota() {
        if let data = try? JSONEncoder().encode(quotaByUser) { UserDefaults.standard.set(data, forKey: quotaKey) }
    }

    private func persistAudioFile(_ source: URL?) -> URL? {
        guard let source,
              FileManager.default.fileExists(atPath: source.path) else { return nil }
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("YorvaAudio", isDirectory: true)
        let destination = directory.appendingPathComponent(source.lastPathComponent)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.copyItem(at: source, to: destination)
            }
            return destination
        } catch {
            // The message should still be added for the current session even
            // if copying to Application Support fails unexpectedly.
            return source
        }
    }

    private func persist() {
        let store = ChatStoreDTO(conversations: conversations.map { ConversationDTO($0) },
                                 messages: messages.map { ChatMessageDTO($0) })
        var all: [String: ChatStoreDTO] = [:]
        if let data = UserDefaults.standard.data(forKey: storeKey), let old = try? JSONDecoder().decode([String: ChatStoreDTO].self, from: data) { all = old }
        all[activeUserKey] = store
        if let data = try? JSONEncoder().encode(all) { UserDefaults.standard.set(data, forKey: storeKey) }
    }
}

private struct ChatStoreDTO: Codable { let conversations: [ConversationDTO]; let messages: [ChatMessageDTO] }
private struct ConversationDTO: Codable {
    let id: String; let participantIds: [String]; let lastMessage: ChatMessageDTO?; let unreadCount: Int; let isYorvaAI: Bool; let ownerId: String?
    init(_ c: Conversation) {
        id = c.id; participantIds = c.participantIds
        lastMessage = c.lastMessage.map { message in MainActor.assumeIsolated { ChatMessageDTO(message) } }
        unreadCount = c.unreadCount; isYorvaAI = c.isYorvaAI; ownerId = c.ownerId
    }
    func toConversation() -> Conversation {
        let message = MainActor.assumeIsolated { lastMessage?.toMessage() }
        return Conversation(id: id, participantIds: participantIds, lastMessage: message, unreadCount: unreadCount, isYorvaAI: isYorvaAI, ownerId: ownerId)
    }
}
private struct ChatMessageDTO: Codable {
    let id: String; let conversationId: String; let senderId: String; let type: String; let text: String?
    let imageColorHex: UInt32?; let imageRatio: Double?; let voiceDuration: Double?; let isPlayed: Bool; let createdAt: TimeInterval
    let imageData: Data?; let voicePath: String?
    init(_ m: ChatMessage) {
        id = m.id; conversationId = m.conversationId; senderId = m.senderId; type = m.type == .text ? "text" : (m.type == .image ? "image" : "voice")
        text = m.text
        imageColorHex = m.imageColor.map { color in
            MainActor.assumeIsolated { Self.hex(color) }
        }
        imageRatio = m.imageRatio.map { Double($0) }
        voiceDuration = m.voiceDuration
        isPlayed = m.isPlayed
        createdAt = m.createdAt.timeIntervalSince1970
        imageData = m.image.flatMap { image in
            MainActor.assumeIsolated { image.jpegData(compressionQuality: 0.85) }
        }
        voicePath = m.voiceURL?.path
    }
    func toMessage() -> ChatMessage {
        let decodedColor = imageColorHex.map { value in
            MainActor.assumeIsolated { Self.color(value) }
        }
        let decodedImage = imageData.flatMap { data in
            MainActor.assumeIsolated { UIImage(data: data) }
        }
        return ChatMessage(id: id, conversationId: conversationId, senderId: senderId,
                    type: type == "image" ? .image : (type == "voice" ? .voice : .text), text: text,
                    imageColor: decodedColor, imageRatio: imageRatio.map { CGFloat($0) }, voiceDuration: voiceDuration,
                    isPlayed: isPlayed, createdAt: Date(timeIntervalSince1970: createdAt), image: decodedImage,
                    voiceURL: voicePath.map { URL(fileURLWithPath: $0) })
    }
    @MainActor private static func hex(_ color: UIColor) -> UInt32 { var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0; color.getRed(&r, green: &g, blue: &b, alpha: &a); return UInt32(r * 255) << 24 | UInt32(g * 255) << 16 | UInt32(b * 255) << 8 | UInt32(a * 255) }
    @MainActor private static func color(_ hex: UInt32) -> UIColor { UIColor(red: CGFloat((hex >> 24) & 255) / 255, green: CGFloat((hex >> 16) & 255) / 255, blue: CGFloat((hex >> 8) & 255) / 255, alpha: CGFloat(hex & 255) / 255) }
}
