//
//  CompleteProfileViewController.swift
//  Yorva
//
//  完善资料 / 编辑资料（首次登录后必填；铁律 11 头像 Sheet / 铁律 12 自定义 Sheet）
//

import UIKit
import SnapKit

final class CompleteProfileViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let avatar = AvatarView()
    private let avatarEditButton = UIButton(type: .system)
    private let nicknameField = UITextField()
    private let birthdayField = UITextField()
    private let locationField = UITextField()
    private let genderField = UITextField()
    private let bioField = UITextView()
    private let bioCountLabel = UILabel()
    private let saveButton = PrimaryButton(title: "Save")
    private let errorLabel = UILabel()

    private let bioLimit = 80
    private var selectedAvatarColor: UIColor = AppTheme.primary
    private var selectedAvatarInitials: String = "Y"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Complete Profile"
        setupHierarchy()
        applyAutoLayoutConstraints()
        if let user = AccountManager.shared.currentUser {
            selectedAvatarColor = user.avatarPlaceholderColor
            selectedAvatarInitials = user.avatarInitials
            nicknameField.text = user.nickname
            birthdayField.text = user.birthday
            locationField.text = user.location
            genderField.text = user.gender
            bioField.text = user.bio
            updateBioCount()
            avatar.configure(user: user)
        }
    }

    override func setupHierarchy() {
        avatar.color = selectedAvatarColor
        avatar.initials = selectedAvatarInitials
        avatarEditButton.setTitle("Edit", for: .normal)
        avatarEditButton.setTitleColor(AppTheme.textBrand, for: .normal)
        avatarEditButton.titleLabel?.font = AppFont.buttonTextLink()
        avatarEditButton.addAction(UIAction { [weak self] _ in self?.showAvatarSheet() }, for: .touchUpInside)

        nicknameField.configureYorvaField(placeholder: "Nickname")
        birthdayField.configureYorvaField(placeholder: "Birthday (YYYY-MM-DD)")
        locationField.configureYorvaField(placeholder: "Location")
        genderField.configureYorvaField(placeholder: "Gender")
        bioField.font = AppFont.textFieldInput()
        bioField.textColor = AppTheme.ink
        bioField.backgroundColor = AppTheme.bgRoot
        bioField.layer.cornerRadius = 12
        bioField.layer.borderWidth = 1
        bioField.layer.borderColor = AppTheme.divider.cgColor
        bioField.delegate = self
        bioField.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)

        bioCountLabel.font = AppFont.caption()
        bioCountLabel.textColor = AppTheme.stone
        bioCountLabel.textAlignment = .right
        updateBioCount()

        errorLabel.font = AppFont.textFieldError()
        errorLabel.textColor = AppTheme.textError
        errorLabel.numberOfLines = 0

        saveButton.addAction(UIAction { [weak self] _ in self?.attemptSave() }, for: .touchUpInside)

        [avatar, avatarEditButton, nicknameField, birthdayField, locationField, genderField, bioField, bioCountLabel, errorLabel, saveButton].forEach { view.addSubview($0) }
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
            make.top.equalTo(avatarEditButton.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
        birthdayField.snp.makeConstraints { make in
            make.top.equalTo(nicknameField.snp.bottom).offset(12)
            make.left.right.height.equalTo(nicknameField)
        }
        locationField.snp.makeConstraints { make in
            make.top.equalTo(birthdayField.snp.bottom).offset(12)
            make.left.right.height.equalTo(nicknameField)
        }
        genderField.snp.makeConstraints { make in
            make.top.equalTo(locationField.snp.bottom).offset(12)
            make.left.right.height.equalTo(nicknameField)
        }
        bioField.snp.makeConstraints { make in
            make.top.equalTo(genderField.snp.bottom).offset(12)
            make.left.right.equalTo(nicknameField)
            make.height.equalTo(80)
        }
        bioCountLabel.snp.makeConstraints { make in
            make.top.equalTo(bioField.snp.bottom).offset(4)
            make.right.equalTo(nicknameField)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(bioCountLabel.snp.bottom).offset(4)
            make.left.right.equalTo(nicknameField)
        }
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(12)
            make.left.right.equalTo(nicknameField)
        }
    }

    // MARK: - 头像 Sheet（铁律 11 / 12）

    private func showAvatarSheet() {
        CustomSheet.show(title: "Change avatar", items: [
            SheetItem(title: "Choose from album", icon: "photo.on.rectangle", isCancel: false) { [weak self] in
                self?.pickAvatar(source: .photoLibrary)
            },
            SheetItem(title: "Take photo", icon: "camera", isCancel: false) { [weak self] in
                self?.pickAvatar(source: .camera)
            },
            SheetItem(title: "Pick a color", icon: "paintpalette", isCancel: false) { [weak self] in
                self?.avatar.color = UIColor.placeholderTint
                self?.selectedAvatarColor = self?.avatar.color ?? AppTheme.primary
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ])
    }

    private enum AvatarSource { case photoLibrary, camera }
    private func pickAvatar(source: AvatarSource) {
        // 暂无切图资源；模拟用户已完成头像选取（占位视图尺寸保持一致便于后续替换图片）
        Toast.show("Avatar updated")
    }

    private func updateBioCount() {
        let count = (bioField.text ?? "").count
        bioCountLabel.text = "\(count)/\(bioLimit)"
    }

    private func attemptSave() {
        let nick = (nicknameField.text ?? "")
        guard !nick.isBlank else { errorLabel.text = "Please enter a nickname."; return }
        guard !(birthdayField.text ?? "").isBlank else { errorLabel.text = "Please enter your birthday."; return }
        guard !(locationField.text ?? "").isBlank else { errorLabel.text = "Please enter your location."; return }
        guard !(genderField.text ?? "").isBlank else { errorLabel.text = "Please select a gender."; return }
        errorLabel.text = ""
        let initials = String(nick.prefix(2)).uppercased()
        AccountManager.shared.updateProfile(nickname: nick, bio: bioField.text ?? "",
                                           birthday: birthdayField.text ?? "",
                                           location: locationField.text ?? "",
                                           gender: genderField.text ?? "",
                                           avatarColor: selectedAvatarColor,
                                           initials: initials)
        Toast.show("Profile saved")
        RootCoordinator.shared.showMainFlow(in: view.window!)
    }
}

extension CompleteProfileViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > bioLimit {
            textView.text = String(textView.text.prefix(bioLimit))
        }
        updateBioCount()
    }
}
