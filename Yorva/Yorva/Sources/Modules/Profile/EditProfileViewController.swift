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

    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let navTitleLabel = UILabel()
    private let navDivider = UIView()
    private let titleLabel = UILabel()
    private let photoCard = UIView()
    private let photoGradient = CAGradientLayer()
    private let photoTitleLabel = UILabel()
    private let photoSubtitleLabel = UILabel()
    private let nicknameTitleLabel = UILabel()
    private let bioTitleLabel = UILabel()
    private let avatar = AvatarView()
    private let avatarEditButton = TextLinkButton(title: "Change avatar")
    private let nicknameField = UITextField()
    private let bioField = UITextView()
    private let bioCount = UILabel()
    private let saveButton = PrimaryButton(title: "Save")
    private let bioLimit = 160
    private var selectedAvatarImage: UIImage?
    private var mediaPicker: MediaPickerCoordinator?

    override func shouldUseScrollContainer() -> Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let user = AccountManager.shared.currentUser {
            avatar.configure(user: user)
            nicknameField.text = user.nickname
            bioField.text = user.bio
            selectedAvatarImage = user.avatarImage
            updateCount()
        }
    }

    override func setupHierarchy() {
        topBar.backgroundColor = UIColor(hex: 0xFAF9F3)
        backButton.setImage(UIImage(systemName: "chevron.backward")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal), for: .normal)
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 18
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        backButton.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        navTitleLabel.attributedText = NSAttributedString(string: "EDIT PROFILE", attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x7B7E77),
            .kern: 1.8
        ])
        navTitleLabel.textAlignment = .center
        navDivider.backgroundColor = UIColor(hex: 0xE1E0D9)
        titleLabel.text = "Make it yours."
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = AppTheme.ink

        photoCard.layer.cornerRadius = 22
        photoCard.layer.masksToBounds = true
        photoGradient.colors = [UIColor(hex: 0xD9FF3F).cgColor, UIColor(hex: 0xEFFFB1).cgColor]
        photoGradient.startPoint = CGPoint(x: 0, y: 0.5)
        photoGradient.endPoint = CGPoint(x: 1, y: 0.5)
        photoCard.layer.insertSublayer(photoGradient, at: 0)
        photoTitleLabel.text = "Your profile photo"
        photoTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        photoTitleLabel.textColor = AppTheme.ink
        photoSubtitleLabel.text = "A clear, recognizable photo helps people feel at\nhome here."
        photoSubtitleLabel.font = .systemFont(ofSize: 10, weight: .regular)
        photoSubtitleLabel.textColor = UIColor(hex: 0x4D5145)
        photoSubtitleLabel.numberOfLines = 2
        avatarEditButton.addAction(UIAction { [weak self] _ in self?.showAvatarSheet() }, for: .touchUpInside)
        avatarEditButton.setTitle("Change photo", for: .normal)
        avatarEditButton.setTitleColor(AppTheme.ink, for: .normal)
        avatarEditButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        avatarEditButton.backgroundColor = .white
        avatarEditButton.layer.cornerRadius = 16
        [avatar, photoTitleLabel, photoSubtitleLabel, avatarEditButton].forEach { photoCard.addSubview($0) }
        nicknameField.configureYorvaField(placeholder: "Nickname")
        nicknameField.font = .systemFont(ofSize: 13, weight: .regular)
        nicknameField.backgroundColor = .white
        nicknameField.layer.cornerRadius = 15
        nicknameField.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        nicknameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        nicknameField.leftViewMode = .always
        bioField.font = AppFont.textFieldInput()
        bioField.textColor = AppTheme.ink
        bioField.backgroundColor = .white
        bioField.layer.cornerRadius = 15
        bioField.layer.borderWidth = 1
        bioField.layer.borderColor = AppTheme.divider.cgColor
        bioField.delegate = self
        bioField.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        bioCount.font = AppFont.caption()
        bioCount.textColor = AppTheme.stone
        bioCount.textAlignment = .right
        saveButton.addAction(UIAction { [weak self] _ in self?.attemptSave() }, for: .touchUpInside)
        saveButton.backgroundColor = AppTheme.ink
        saveButton.setTitleColor(.white, for: .normal)
        configureFieldLabel(nicknameTitleLabel, text: "NICKNAME")
        configureFieldLabel(bioTitleLabel, text: "BIO / SIGNATURE")
        [backButton, navTitleLabel].forEach { topBar.addSubview($0) }
        [topBar, navDivider, titleLabel, photoCard, nicknameTitleLabel, nicknameField,
         bioTitleLabel, bioField, bioCount, saveButton].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        topBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(106)
        }
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(6)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(36)
        }
        navTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }
        navDivider.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(-1)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(17)
        }
        photoCard.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(121)
        }
        avatar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(17)
            make.centerY.equalToSuperview()
            make.size.equalTo(72)
        }
        photoTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalToSuperview().offset(23)
        }
        photoSubtitleLabel.snp.makeConstraints { make in
            make.left.equalTo(photoTitleLabel)
            make.top.equalTo(photoTitleLabel.snp.bottom).offset(4)
        }
        avatarEditButton.snp.makeConstraints { make in
            make.left.equalTo(photoTitleLabel)
            make.top.equalTo(photoSubtitleLabel.snp.bottom).offset(9)
            make.width.equalTo(84)
            make.height.equalTo(32)
        }
        nicknameTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(photoCard.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(17)
        }
        nicknameField.snp.makeConstraints { make in
            make.top.equalTo(nicknameTitleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(17)
            make.height.equalTo(43)
        }
        bioTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(nicknameField.snp.bottom).offset(18)
            make.left.equalTo(nicknameField)
        }
        bioField.snp.makeConstraints { make in
            make.top.equalTo(bioTitleLabel.snp.bottom).offset(8)
            make.left.right.equalTo(nicknameField)
            make.height.equalTo(110)
        }
        bioCount.snp.makeConstraints { make in
            make.top.equalTo(bioField.snp.bottom).offset(4)
            make.right.equalTo(nicknameField)
        }
        saveButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        photoGradient.frame = photoCard.bounds
    }

    private func configureFieldLabel(_ label: UILabel, text: String) {
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor(hex: 0x85857D),
            .kern: 1.1
        ])
    }

    private func showAvatarSheet() {
        CustomSheet.show(title: "Change avatar", items: [
            SheetItem(title: "Choose from album", icon: "photo.on.rectangle", isCancel: false) { [weak self] in
                self?.presentAvatarPicker(source: .photoLibrary)
            },
            SheetItem(title: "Take photo", icon: "camera", isCancel: false) { [weak self] in
                self?.presentAvatarPicker(source: .camera)
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ])
    }

    private func presentAvatarPicker(source: MediaPickerCoordinator.Source) {
        mediaPicker = MediaPickerCoordinator(presenter: self, allowsVideo: false) { [weak self] selection in
            guard let self = self, let image = selection?.image else { return }
            self.selectedAvatarImage = image
            self.avatar.setImage(image)
            Toast.show("Avatar updated")
        }
        mediaPicker?.present(source: source)
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
            avatarColor: avatar.color, initials: String(nickname.prefix(2)).uppercased(),
            avatarImage: selectedAvatarImage)
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
