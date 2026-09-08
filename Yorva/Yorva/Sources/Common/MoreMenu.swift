//
//  MoreMenu.swift
//  Yorva
//
//  - Cancel
//

import UIKit

enum MoreMenu {

    static func showPostMoreMenu(post: Post, from presenter: UIViewController) {
        showUserMoreMenu(targetUserId: post.authorId,
                         from: presenter)
    }

    static func showAuthorMoreMenu(user: User, from presenter: UIViewController) {
        showUserMoreMenu(targetUserId: user.id, from: presenter)
    }

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
