//
//  MoreMenu.swift
//  Yorva
//
//  帖子 / 作者「更多菜单」（铁律：拉黑 vs 举报独立）
//  - Follow / Unfollow
//  - Report（仅本地记录举报，不屏蔽）
//  - Block（本地持久化 + 全局过滤，二次确认）
//

import UIKit

enum MoreMenu {

    /// 帖子更多菜单
    static func showPostMoreMenu(post: Post, from presenter: UIViewController) {
        let author = DataRepository.shared.user(by: post.authorId)
        let me = AccountManager.shared.currentUser?.id ?? ""
        let isFollowing = author.map { FollowManager.shared.isFollowing(followerId: me, followeeId: $0.id) } ?? false

        let items: [SheetItem] = [
            SheetItem(title: isFollowing ? "Unfollow @\(author?.nickname ?? "")" : "Follow @\(author?.nickname ?? "")",
                      icon: isFollowing ? "person.badge.minus" : "person.badge.plus",
                      isCancel: false) {
                guard let a = author else { return }
                if isFollowing { FollowManager.shared.unfollow(followerId: me, followeeId: a.id) }
                else { FollowManager.shared.follow(followerId: me, followeeId: a.id) }
            },
            SheetItem(title: "Report", icon: "exclamationmark.bubble", isCancel: false) {
                let vc = ReportViewController()
                vc.targetUserId = post.authorId
                vc.targetName = author?.nickname
                presenter.navigationController?.pushViewController(vc, animated: true)
            },
            SheetItem(title: "Block @\(author?.nickname ?? "")", icon: "hand.raised", isCancel: false) {
                guard let a = author else { return }
                ConfirmDialog.show(
                    title: "Block \(a.nickname)?",
                    message: "Posts, comments and messages from this user will be hidden across Yorva. You can unblock them later.",
                    confirmTitle: "Block",
                    cancelTitle: "Cancel",
                    isDestructive: true,
                    onConfirm: {
                        BlockManager.shared.block(blockerId: me, blockedId: a.id)
                        Toast.show("Blocked \(a.nickname)")
                        _ = presenter.navigationController?.popViewController(animated: true)
                    }
                )
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ]
        CustomSheet.show(items: items)
    }

    /// 作者资料页更多菜单（仅 Report / Block，无 Follow）
    static func showAuthorMoreMenu(user: User, from presenter: UIViewController) {
        let me = AccountManager.shared.currentUser?.id ?? ""
        let items: [SheetItem] = [
            SheetItem(title: "Report", icon: "exclamationmark.bubble", isCancel: false) {
                let vc = ReportViewController()
                vc.targetUserId = user.id
                vc.targetName = user.nickname
                presenter.navigationController?.pushViewController(vc, animated: true)
            },
            SheetItem(title: "Block @\(user.nickname)", icon: "hand.raised", isCancel: false) {
                ConfirmDialog.show(
                    title: "Block \(user.nickname)?",
                    message: "Posts, comments and messages from this user will be hidden across Yorva. You can unblock them later.",
                    confirmTitle: "Block",
                    cancelTitle: "Cancel",
                    isDestructive: true,
                    onConfirm: {
                        BlockManager.shared.block(blockerId: me, blockedId: user.id)
                        Toast.show("Blocked \(user.nickname)")
                        _ = presenter.navigationController?.popViewController(animated: true)
                    }
                )
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ]
        CustomSheet.show(items: items)
    }
}
