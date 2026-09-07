//
//  MoreMenu.swift
//  Yorva
//
//  帖子 / 作者 / 聊天 / 评论「更多菜单」（铁律：拉黑 vs 举报独立）
//  - Report（仅本地记录举报，不屏蔽）
//  - Block（本地持久化 + 全局过滤，二次确认）
//  - Cancel
//

import UIKit

enum MoreMenu {

    /// 帖子更多菜单
    static func showPostMoreMenu(post: Post, from presenter: UIViewController) {
        showUserMoreMenu(targetUserId: post.authorId,
                         from: presenter)
    }

    /// 作者资料页更多菜单
    static func showAuthorMoreMenu(user: User, from presenter: UIViewController) {
        showUserMoreMenu(targetUserId: user.id, from: presenter)
    }

    /// 统一的用户举报 / 拉黑菜单。菜单文案固定为 Report、Block、Cancel，
    /// 不把用户名拼接进 Sheet 或确认弹窗，避免不同入口展示不一致。
    static func showUserMoreMenu(targetUserId: String, from presenter: UIViewController) {
        let me = AccountManager.shared.currentUser?.id ?? ""
        let items: [SheetItem] = [
            SheetItem(title: "Report", icon: nil, isCancel: false) {
                let vc = ReportViewController()
                vc.targetUserId = targetUserId
                presenter.navigationController?.pushViewController(vc, animated: true)
            },
            SheetItem(title: "Block", icon: nil, isCancel: false) {
                ConfirmDialog.show(
                    title: "Block this user?",
                    message: "Posts, comments and messages from this user will be hidden across Yorva. You can unblock them later.",
                    confirmTitle: "Block",
                    cancelTitle: "Cancel",
                    isDestructive: true,
                    onConfirm: {
                        guard !targetUserId.isEmpty, targetUserId != me else { return }
                        BlockManager.shared.block(blockerId: me, blockedId: targetUserId)
                        Toast.show("Blocked")
                        _ = presenter.navigationController?.popViewController(animated: true)
                    }
                )
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ]
        CustomSheet.show(items: items)
    }
}
