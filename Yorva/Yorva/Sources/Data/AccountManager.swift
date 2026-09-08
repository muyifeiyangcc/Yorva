//
//  AccountManager.swift
//  Yorva
//
//

import Foundation
import UIKit

final class AccountManager {

    static let shared = AccountManager()

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


    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([UserDTO].self, from: data) {
            accounts = decoded.map { $0.toUser() }
        } else {
            accounts = []
            ensurePrebuiltAccount()
        }
        if accounts.isEmpty {
            ensurePrebuiltAccount()
        }
    }

    private func ensurePrebuiltAccount() {
        guard !accounts.contains(where: { $0.email == SeedData.prebuiltTestEmail }) else { return }
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

    func register(email: String, password: String) -> Result<User, AccountError> {
        guard email.isValidEmail else { return .failure(.invalidEmail) }
        guard password.count >= 8 else { return .failure(.passwordTooShort) }
        if accounts.contains(where: { $0.email.lowercased() == email.lowercased() && !$0.isDeleted }) {
            return .failure(.emailExists)
        }
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
        accounts.append(user)
        DataRepository.shared.upsertUser(user)
        persist()
        currentUser = user
        isGuest = false
        persistCurrent()
        return .success(user)
    }

    func login(email: String, password: String) -> Result<User, AccountError> {
        guard let user = accounts.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            return .failure(.accountNotFound)
        }
        guard !user.isDeleted else { return .failure(.accountDeleted) }
        guard user.passwordDigest == password else { return .failure(.passwordWrong) }
        currentUser = user
        isGuest = false
        persistCurrent()
        if user.id == "user-prebuilt" {
            ["user-jamie", "user-elena"].forEach { followerId in
                FollowManager.shared.follow(followerId: followerId, followeeId: user.id)
            }
        }
        return .success(user)
    }

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

    func logout() {
        currentUser = nil
        isGuest = false
        UserDefaults.standard.removeObject(forKey: currentIdKey)
        UserDefaults.standard.removeObject(forKey: guestKey)
        DataRepository.shared.broadcast(.sessionCleared)
    }

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

    func enterGuestMode() {
        currentUser = nil
        isGuest = true
        persistCurrent()
    }

    func isProfileComplete(_ user: User) -> Bool {
        // Location is optional and is no longer part of profile completion.
        return !user.nickname.isBlank && !user.birthday.isBlank && !user.gender.isBlank
    }

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
