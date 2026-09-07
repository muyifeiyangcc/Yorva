//
//  AccountManager.swift
//  Yorva
//
//  账号体系：注册 / 登录 / 找回密码 / 删除账号 / 完善资料 / 游客态
//  铁律 2、铁律 4、铁律 10
//

import Foundation
import UIKit

final class AccountManager {

    static let shared = AccountManager()

    // 持久化键
    private let accountsKey = "yorva.accounts.v1"
    private let currentIdKey = "yorva.current.account.id"
    private let deletedEmailsKey = "yorva.deleted.emails.v1"
    private let guestKey = "yorva.guest.flag"

    private(set) var accounts: [User] = []
    private(set) var currentUser: User?
    private(set) var isGuest: Bool = false

    private init() {
        loadAccounts()
        loadCurrent()
        accounts.forEach { DataRepository.shared.upsertUser($0) }
    }

    // MARK: - Accounts persistence（轻量持久化，仅本地）

    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([UserDTO].self, from: data) {
            accounts = decoded.map { $0.toUser() }
        } else {
            // 预置账号未持久化时，注入首启可用账号（铁律 10）
            accounts = []
            ensurePrebuiltAccount()
        }
        if accounts.isEmpty {
            ensurePrebuiltAccount()
        }
    }

    private func ensurePrebuiltAccount() {
        guard !accounts.contains(where: { $0.email == SeedData.prebuiltTestEmail }) else { return }
        // 默认 1 个关注对象从初始化默认静态数据源随机选取一条；延迟到登录成功时建立关系，避免账号未登录即写入关系
        let prebuilt = User(
            id: "user-prebuilt",
            email: SeedData.prebuiltTestEmail,
            passwordDigest: SeedData.prebuiltTestPassword,
            nickname: "yorva",
            avatarPlaceholderColor: AppTheme.primary,
            avatarInitials: "YT",
            bio: "Trying Yorva for the first time.",
            birthday: "1996-04-22",
            location: "Lodon",
            gender: "Female",
            isDeleted: false,
            coins: 0,
            diamonds: 0,
            isGuest: false
        )
        accounts.append(prebuilt)
        persist()
    }

    private func loadCurrent() {
        isGuest = UserDefaults.standard.bool(forKey: guestKey)
        if let id = UserDefaults.standard.string(forKey: currentIdKey),
           var user = accounts.first(where: { $0.id == id && !$0.isDeleted }) {
            user.coins = max(0, user.coins)
            currentUser = user
        }
    }

    private func persist() {
        let dtos = accounts.map { UserDTO(from: $0) }
        if let data = try? JSONEncoder().encode(dtos) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
    }

    private func persistCurrent() {
        UserDefaults.standard.set(currentUser?.id, forKey: currentIdKey)
        UserDefaults.standard.set(isGuest, forKey: guestKey)
    }

    // MARK: - Account lifecycle

    /// 注册新账号；新用户初始化金币数值固定为 0（铁律 9）
    func register(email: String, password: String) -> Result<User, AccountError> {
        guard email.isValidEmail else { return .failure(.invalidEmail) }
        guard password.count >= 8 else { return .failure(.passwordTooShort) }
        if accounts.contains(where: { $0.email.lowercased() == email.lowercased() && !$0.isDeleted }) {
            return .failure(.emailExists)
        }
        // 之前删除过同名邮箱：本次注册复活邮箱（铁律 10：删除后失效，但允许新注册同邮箱重新激活）
        let newId = "user-\(UUID().uuidString.prefix(8))"
        let user = User(
            id: newId,
            email: email,
            passwordDigest: password,
            nickname: "Yorva Member",
            avatarPlaceholderColor: UIColor.placeholderTint,
            avatarInitials: String(email.prefix(2)).uppercased(),
            bio: "",
            birthday: "",
            location: "",
            gender: "",
            isDeleted: false,
            coins: 0,
            diamonds: 0,
            isGuest: false
        )
        // 默认 1 个关注对象，从初始化默认静态数据源随机选取一条（铁律 10）
        let followPool = DataRepository.shared.users.filter { $0.id != newId }
        if let followee = followPool.randomElement() {
            FollowManager.shared.follow(followerId: newId, followeeId: followee.id)
        }
        accounts.append(user)
        DataRepository.shared.upsertUser(user)
        persist()
        // 注册成功：进入完善资料页（资料不完整）
        currentUser = user
        isGuest = false
        persistCurrent()
        return .success(user)
    }

    /// 邮箱登录（铁律 10：被删除账号无法登录）
    func login(email: String, password: String) -> Result<User, AccountError> {
        guard let user = accounts.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            return .failure(.accountNotFound)
        }
        guard !user.isDeleted else { return .failure(.accountDeleted) }
        guard user.passwordDigest == password else { return .failure(.passwordWrong) }
        currentUser = user
        isGuest = false
        persistCurrent()
        // 预置测试账号：默认拥有 2 个粉丝（Jamie M. / Elena Vance 关注该账号），幂等建立
        if user.id == "user-prebuilt" {
            ["user-jamie", "user-elena"].forEach { followerId in
                FollowManager.shared.follow(followerId: followerId, followeeId: user.id)
            }
        } else if FollowManager.shared.following(userId: user.id).isEmpty {
            // 其他账号兜底：从初始化静态数据源随机选取 1 个关注对象
            let pool = DataRepository.shared.users.filter { $0.id != user.id }
            if let f = pool.randomElement() { FollowManager.shared.follow(followerId: user.id, followeeId: f.id) }
        }
        return .success(user)
    }

    /// 找回密码：成功后回到登录页（铁律 4 推动邮箱登录流程）
    func resetPassword(email: String, newPassword: String) -> Result<Void, AccountError> {
        guard email.isValidEmail else { return .failure(.invalidEmail) }
        guard newPassword.count >= 8 else { return .failure(.passwordTooShort) }
        guard let idx = accounts.firstIndex(where: { $0.email.lowercased() == email.lowercased() && !$0.isDeleted }) else {
            return .failure(.accountNotFound)
        }
        accounts[idx].passwordDigest = newPassword
        persist()
        return .success(())
    }

    /// 完善资料 / 编辑资料
    func updateProfile(nickname: String, bio: String, birthday: String, location: String, gender: String,
                       avatarColor: UIColor, initials: String, avatarImage: UIImage? = nil) {
        guard var user = currentUser else { return }
        user.nickname = nickname
        user.bio = bio
        user.birthday = birthday
        user.location = location
        user.gender = gender
        user.avatarPlaceholderColor = avatarColor
        user.avatarInitials = initials
        // nil means the user explicitly selected the gray system placeholder.
        user.avatarImage = avatarImage
        currentUser = user
        if let idx = accounts.firstIndex(where: { $0.id == user.id }) {
            accounts[idx] = user
        }
        DataRepository.shared.upsertUser(user)
        persist()
        DataRepository.shared.broadcast(.profileUpdated)
    }

    /// 退出登录：清理当前会话，但保留账户数据（铁律 5 + 10）
    func logout() {
        currentUser = nil
        isGuest = false
        UserDefaults.standard.removeObject(forKey: currentIdKey)
        UserDefaults.standard.removeObject(forKey: guestKey)
        DataRepository.shared.broadcast(.sessionCleared)
    }

    /// 删除账号：本地标记失效，重启无法登录（铁律 10）
    func deleteAccount() {
        guard var user = currentUser else { return }
        let deletedUserID = user.id
        FollowManager.shared.removeRelations(for: deletedUserID)
        BlockManager.shared.removeUserState(deletedUserID)
        ContentManager.shared.removeUserState(deletedUserID)
        ChatManager.shared.removeUserState(deletedUserID)
        user.isDeleted = true
        currentUser = nil
        if let idx = accounts.firstIndex(where: { $0.id == user.id }) {
            accounts[idx] = user
        }
        DataRepository.shared.upsertUser(user)
        persist()
        logout()
    }

    /// 游客入口（铁律 2）：进入游客态
    func enterGuestMode() {
        currentUser = nil
        isGuest = true
        persistCurrent()
    }

    /// 资料是否完整（注册成功后进入完善资料页）
    func isProfileComplete(_ user: User) -> Bool {
        // Location is optional and is no longer part of profile completion.
        return !user.nickname.isBlank && !user.birthday.isBlank && !user.gender.isBlank
    }

    /// 写入金币变更（仅 CurrencyManager 应调用，避免散落写入）
    func applyCurrencyChange(coins: Int, diamonds: Int) {
        guard var user = currentUser else { return }
        user.coins = max(0, user.coins + coins)
        user.diamonds = max(0, user.diamonds + diamonds)
        currentUser = user
        if let idx = accounts.firstIndex(where: { $0.id == user.id }) {
            accounts[idx] = user
        }
        persist()
        DataRepository.shared.broadcast(.walletUpdated)
    }
}

enum AccountError: Error {
    case invalidEmail, passwordTooShort, emailExists
    case accountNotFound, accountDeleted, passwordWrong
    case profileIncomplete

    var userMessage: String {
        switch self {
        case .invalidEmail: return "Please enter a valid email."
        case .passwordTooShort: return "Password must be at least 8 characters."
        case .emailExists: return "This email is already registered."
        case .accountNotFound: return "Account not found or has been deactivated."
        case .accountDeleted: return "Account not found or has been deactivated."
        case .passwordWrong: return "Email or password is incorrect."
        case .profileIncomplete: return "Please complete your profile to continue."
        }
    }
}

// MARK: - DTO 持久化辅助

private struct UserDTO: Codable {
    let id: String
    let email: String
    let passwordDigest: String
    let nickname: String
    let avatarHex: UInt32
    let avatarInitials: String
    let bio: String
    let birthday: String
    let location: String
    let gender: String
    let isDeleted: Bool
    let coins: Int
    let diamonds: Int
    let isGuest: Bool
    let avatarImageData: Data?

    init(from u: User) {
        id = u.id; email = u.email; passwordDigest = u.passwordDigest
        nickname = u.nickname; avatarHex = Self.hex(from: u.avatarPlaceholderColor)
        avatarInitials = u.avatarInitials; bio = u.bio
        birthday = u.birthday; location = u.location; gender = u.gender
        isDeleted = u.isDeleted; coins = u.coins; diamonds = u.diamonds; isGuest = u.isGuest
        avatarImageData = u.avatarImage?.jpegData(compressionQuality: 0.85)
    }
    func toUser() -> User {
        User(id: id, email: email, passwordDigest: passwordDigest,
             nickname: nickname,
             avatarPlaceholderColor: Self.color(hex: avatarHex),
             avatarInitials: avatarInitials, bio: bio,
             birthday: birthday, location: location, gender: gender,
             isDeleted: isDeleted, coins: coins, diamonds: diamonds, isGuest: isGuest,
             avatarImage: avatarImageData.flatMap { UIImage(data: $0) })
    }
    static func hex(from color: UIColor) -> UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UInt32(r * 255) << 16 | UInt32(g * 255) << 8 | UInt32(b * 255)
    }
    static func color(hex: UInt32) -> UIColor { UIColor(hex: hex) }
}
