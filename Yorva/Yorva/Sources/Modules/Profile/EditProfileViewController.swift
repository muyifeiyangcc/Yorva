//
//  EditProfileViewController.swift
//  Yorva
//
//  编辑资料（铁律 11 / 12）
//  头像 / 昵称 / 签名 / 保存后写入仓库即时刷新（铁律 8）
//

import UIKit
import SnapKit

final class EditProfileViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let avatar = AvatarView()
    private let avatarEditButton = TextLinkButton(title: "Change avatar")
    private let nicknameField = UITextField()
    private let bioField = UITextView()
    private let bioCount = UILabel()
    private let saveButton = PrimaryButton(title: "Save")
    private let bioLimit = 80

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        setupHierarchy()
        applyAutoLayoutConstraints()
        if let user = AccountManager.shared.currentUser {
            avatar.configure(user: user)
            nicknameField.text = user.nickname
            bioField.text = user.bio
            updateCount()
        }
    }

    override func setupHierarchy() {
        avatarEditButton.addAction(UIAction { [weak self] _ in self?.showAvatarSheet() }, for: .touchUpInside)
        nicknameField.configureYorvaField(placeholder: "Nickname")
        bioField.font = AppFont.textFieldInput()
        bioField.textColor = AppTheme.ink
        bioField.backgroundColor = AppTheme.bgRoot
        bioField.layer.cornerRadius = 12
        bioField.layer.borderWidth = 1
        bioField.layer.borderColor = AppTheme.divider.cgColor
        bioField.delegate = self
        bioField.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        bioCount.font = AppFont.caption()
        bioCount.textColor = AppTheme.stone
        bioCount.textAlignment = .right
        saveButton.addAction(UIAction { [weak self] _ in self?.attemptSave() }, for: .touchUpInside)
        [avatar, avatarEditButton, nicknameField, bioField, bioCount, saveButton].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        avatar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.centerX.equalToSuperview()
            make.size.equalTo(96)
        }
        avatarEditButton.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        nicknameField.snp.makeConstraints { make in
            make.top.equalTo(avatarEditButton.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
        bioField.snp.makeConstraints { make in
            make.top.equalTo(nicknameField.snp.bottom).offset(16)
            make.left.right.equalTo(nicknameField)
            make.height.equalTo(80)
        }
        bioCount.snp.makeConstraints { make in
            make.top.equalTo(bioField.snp.bottom).offset(4)
            make.right.equalTo(nicknameField)
        }
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(bioCount.snp.bottom).offset(20)
            make.left.right.equalTo(nicknameField)
        }
    }

    private func showAvatarSheet() {
        CustomSheet.show(title: "Change avatar", items: [
            SheetItem(title: "Choose from album", icon: "photo.on.rectangle", isCancel: false) { [weak self] in
                self?.avatar.color = .placeholderTint
            },
            SheetItem(title: "Take photo", icon: "camera", isCancel: false) { [weak self] in
                self?.avatar.color = .placeholderTint
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ])
    }

    private func updateCount() {
        bioCount.text = "\((bioField.text ?? "").count)/\(bioLimit)"
    }

    private func attemptSave() {
        guard let user = AccountManager.shared.currentUser else { return }
        let nickname = nicknameField.text ?? ""
        guard !nickname.isBlank else { Toast.show("Please enter a nickname"); return }
        AccountManager.shared.updateProfile(
            nickname: nickname,
            bio: bioField.text ?? "",
            birthday: user.birthday, location: user.location, gender: user.gender,
            avatarColor: avatar.color, initials: String(nickname.prefix(2)).uppercased())
        Toast.show("Profile saved")
        navigationController?.popViewController(animated: true)
    }
}

extension EditProfileViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > bioLimit {
            textView.text = String(textView.text.prefix(bioLimit))
        }
        updateCount()
    }
}
