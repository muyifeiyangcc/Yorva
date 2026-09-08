//
//  CompleteProfileViewController.swift
//  Yorva
//
//

import UIKit
import SnapKit

final class CompleteProfileViewController: BaseViewController {

    override var pageBackgroundColor: UIColor { AuthDesign.backgroundColor }
    override var isSecondaryLevel: Bool { true }

    private let backButton = AuthDesign.makeBackButton()
    private let titleLabel = AuthDesign.makeTitleLabel()
    private let subtitleLabel = AuthDesign.makeSubtitleLabel()
    private let profileCard = AuthFormBackgroundView()
    private let avatar = AvatarView()
    private let profileCardTitle = UILabel()
    private let profileCardSubtitle = UILabel()
    private let avatarEditButton = UIButton(type: .system)
    private let nicknameCaption = AuthDesign.makeFieldCaption("NICKNAME")
    private let birthdayCaption = AuthDesign.makeFieldCaption("DATE OF BIRTH")
    private let genderCaption = AuthDesign.makeFieldCaption("GENDER")
    private let nicknameField = UITextField()
    private let birthdayField = UITextField()
    private let genderField = UITextField()
    private let bioField = UITextView()
    private let bioCountLabel = UILabel()
    private let maleButton = UIButton(type: .system)
    private let femaleButton = UIButton(type: .system)
    private let saveButton = AuthBottomButton(title: "Save")
    private let errorLabel = UILabel()

    private let bioLimit = 80
    private var selectedAvatarColor: UIColor = AppTheme.primary
    private var selectedAvatarInitials: String = "Y"
    private var selectedAvatarImage: UIImage?
    private var mediaPicker: MediaPickerCoordinator?

    private static let birthdayDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()

    private static let birthdayInputFormats = ["MM/dd/yyyy", "MM / dd / yyyy", "yyyy-MM-dd"]

    override func shouldUseScrollContainer() -> Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        if let user = AccountManager.shared.currentUser {
            selectedAvatarColor = user.avatarPlaceholderColor
            selectedAvatarInitials = user.avatarInitials
            nicknameField.text = user.nickname
            birthdayField.text = self.displayBirthday(user.birthday)
            genderField.text = user.gender
            bioField.text = user.bio
            avatar.configure(user: user)
            selectedAvatarImage = user.avatarImage
            updateGenderSelection()
        }
    }

    override func setupHierarchy() {
        titleLabel.attributedText = AuthDesign.makeTitle("A little about you.", size: 30)
        subtitleLabel.text = "This helps shape a more thoughtful space around your everyday life."

        avatar.color = selectedAvatarColor
        avatar.initials = selectedAvatarInitials
        profileCardTitle.text = "Add a profile photo"
        profileCardTitle.textColor = AppTheme.ink
        profileCardTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        profileCardSubtitle.text = "A face, a place, or anything that feels like you."
        profileCardSubtitle.textColor = UIColor(hex: 0x62655D)
        profileCardSubtitle.font = .systemFont(ofSize: 9, weight: .regular)

        avatarEditButton.setTitle("Choose photo", for: .normal)
        avatarEditButton.setTitleColor(AppTheme.ink, for: .normal)
        avatarEditButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
        avatarEditButton.backgroundColor = .white
        avatarEditButton.layer.cornerRadius = 13
        avatarEditButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 11)
        avatarEditButton.addAction(UIAction { [weak self] _ in self?.showAvatarSheet() }, for: .touchUpInside)

        nicknameField.configureAuthField(placeholder: "How should we call you?")
        nicknameField.backgroundColor = .white
        birthdayField.configureAuthField(placeholder: "MM / DD / YYYY")
        birthdayField.backgroundColor = .white
        birthdayField.delegate = self
        birthdayField.tintColor = .clear
        genderField.configureAuthField(placeholder: "Gender")
        bioField.font = AppFont.textFieldInput()
        bioField.textColor = AppTheme.ink
        bioField.delegate = self
        bioCountLabel.font = AppFont.caption()
        bioCountLabel.textColor = AppTheme.stone
        updateBioCount()

        configureGenderButton(maleButton, title: "Male")
        configureGenderButton(femaleButton, title: "Female")
        maleButton.addAction(UIAction { [weak self] _ in self?.selectGender("Male") }, for: .touchUpInside)
        femaleButton.addAction(UIAction { [weak self] _ in self?.selectGender("Female") }, for: .touchUpInside)

        errorLabel.font = AppFont.textFieldError()
        errorLabel.textColor = AppTheme.textError
        errorLabel.numberOfLines = 0
        backButton.addAction(UIAction { [weak self] _ in self?.handleBackTapped() }, for: .touchUpInside)
        saveButton.addAction(UIAction { [weak self] _ in self?.attemptSave() }, for: .touchUpInside)

        let host = self.view!
        view.addSubview(backButton)
        [titleLabel, subtitleLabel, profileCard, nicknameCaption, nicknameField,
         birthdayCaption, birthdayField, genderCaption, maleButton, femaleButton,
         errorLabel].forEach { host.addSubview($0) }
        [avatar, profileCardTitle, profileCardSubtitle, avatarEditButton].forEach {
            profileCard.addSubview($0)
        }
        view.addSubview(saveButton)
    }

    private func configureGenderButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(AppTheme.ink, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(hex: 0xD9DDD1).cgColor
        button.backgroundColor = .white
    }

    private func selectGender(_ gender: String) {
        genderField.text = gender
        updateGenderSelection()
    }

    private func updateGenderSelection() {
        let gender = genderField.text?.lowercased()
        maleButton.backgroundColor = gender == "male" ? AuthDesign.lime : .white
        femaleButton.backgroundColor = gender == "female" ? AuthDesign.lime : .white
    }

    override func applyAutoLayoutConstraints() {
        let host = self.view!
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(34)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(48)
            make.left.right.equalTo(host).inset(17)
            make.height.equalTo(36)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(7)
            make.left.right.equalTo(titleLabel)
        }
        profileCard.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(23)
            make.left.right.equalTo(host).inset(17)
            make.height.equalTo(101)
        }
        avatar.snp.makeConstraints { make in
            make.left.equalTo(profileCard).offset(17)
            make.centerY.equalTo(profileCard)
            make.size.equalTo(67)
        }
        profileCardTitle.snp.makeConstraints { make in
            make.top.equalTo(profileCard).offset(17)
            make.left.equalTo(avatar.snp.right).offset(14)
            make.right.equalTo(profileCard).inset(12)
        }
        profileCardSubtitle.snp.makeConstraints { make in
            make.top.equalTo(profileCardTitle.snp.bottom).offset(4)
            make.left.right.equalTo(profileCardTitle)
        }
        avatarEditButton.snp.makeConstraints { make in
            make.top.equalTo(profileCardSubtitle.snp.bottom).offset(8)
            make.left.equalTo(profileCardTitle)
            make.height.equalTo(26)
        }
        nicknameCaption.snp.makeConstraints { make in
            make.top.equalTo(profileCard.snp.bottom).offset(23)
            make.left.right.equalTo(host).inset(17)
        }
        nicknameField.snp.makeConstraints { make in
            make.top.equalTo(nicknameCaption.snp.bottom).offset(7)
            make.left.right.equalTo(nicknameCaption)
            make.height.equalTo(43)
        }
        birthdayCaption.snp.makeConstraints { make in
            make.top.equalTo(nicknameField.snp.bottom).offset(17)
            make.left.right.equalTo(nicknameCaption)
        }
        birthdayField.snp.makeConstraints { make in
            make.top.equalTo(birthdayCaption.snp.bottom).offset(7)
            make.left.right.equalTo(nicknameCaption)
            make.height.equalTo(43)
        }
        genderCaption.snp.makeConstraints { make in
            make.top.equalTo(birthdayField.snp.bottom).offset(17)
            make.left.right.equalTo(nicknameCaption)
        }
        maleButton.snp.makeConstraints { make in
            make.top.equalTo(genderCaption.snp.bottom).offset(7)
            make.left.equalTo(nicknameCaption)
            make.width.equalTo(166)
            make.height.equalTo(41)
        }
        femaleButton.snp.makeConstraints { make in
            make.top.equalTo(maleButton)
            make.left.equalTo(maleButton.snp.right).offset(8)
            make.right.equalTo(nicknameCaption)
            make.height.equalTo(maleButton)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(maleButton.snp.bottom).offset(7)
            make.left.right.equalTo(nicknameCaption)
        }
        saveButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(18)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }


    private func showAvatarSheet() {
        CustomSheet.show(title: "Change avatar", items: [
            SheetItem(title: "Choose from album", icon: "photo.on.rectangle", isCancel: false) { [weak self] in
                self?.pickAvatar(source: .photoLibrary)
            },
            SheetItem(title: "Take photo", icon: "camera", isCancel: false) { [weak self] in
                self?.pickAvatar(source: .camera)
            },
            SheetItem(title: "Pick a color", icon: "paintpalette", isCancel: false) { [weak self] in
                self?.selectedAvatarImage = nil
                self?.avatar.setImage(nil)
                self?.avatar.color = UIColor.placeholderTint
                self?.selectedAvatarColor = self?.avatar.color ?? AppTheme.primary
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ])
    }

    private enum AvatarSource { case photoLibrary, camera }
    private func pickAvatar(source: AvatarSource) {
        let pickerSource: MediaPickerCoordinator.Source = source == .photoLibrary ? .photoLibrary : .camera
        mediaPicker = MediaPickerCoordinator(presenter: self, allowsVideo: false) { [weak self] selection in
            guard let self = self, let image = selection?.image else { return }
            self.selectedAvatarImage = image
            self.avatar.setImage(image)
            Toast.show("Avatar updated")
        }
        mediaPicker?.present(source: pickerSource)
    }

    private func updateBioCount() {
        let count = (bioField.text ?? "").count
        bioCountLabel.text = "\(count)/\(bioLimit)"
    }

    private func attemptSave() {
        let nick = nicknameField.text ?? ""
        guard !nick.isBlank else { errorLabel.text = "Please enter a nickname."; return }
        guard !(birthdayField.text ?? "").isBlank else { errorLabel.text = "Please enter your birthday."; return }
        guard let birthday = birthdayDate(from: birthdayField.text), isAtLeast18(birthday) else {
            errorLabel.text = "You must be at least 18 years old."
            return
        }
        guard !(genderField.text ?? "").isBlank else { errorLabel.text = "Please select a gender."; return }
        errorLabel.text = ""
        let initials = String(nick.prefix(2)).uppercased()
        // Location is no longer collected during profile completion. Preserve
        // any legacy value already stored on the account instead of clearing it.
        let existingLocation = AccountManager.shared.currentUser?.location ?? ""
        AccountManager.shared.updateProfile(nickname: nick, bio: bioField.text ?? "",
                                           birthday: birthdayField.text ?? "",
                                           location: existingLocation,
                                           gender: genderField.text ?? "",
                                           avatarColor: selectedAvatarColor,
                                           initials: initials,
                                           avatarImage: selectedAvatarImage)
        Toast.show("Profile saved")
        RootCoordinator.shared.showMainFlow(in: view.window!)
    }

    private func handleBirthdayTapped() {
        guard let maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) else { return }
        let initialDate = birthdayDate(from: birthdayField.text).map { min($0, maximumDate) } ?? maximumDate
        BirthdayPickerSheet.present(initialDate: initialDate, maximumDate: maximumDate) { [weak self] date in
            guard let self = self, let date = date else { return }
            self.birthdayField.text = Self.birthdayDisplayFormatter.string(from: date)
            self.errorLabel.text = nil
        }
    }

    private func birthdayDate(from value: String?) -> Date? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        for format in Self.birthdayInputFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    private func displayBirthday(_ value: String) -> String? {
        guard let date = birthdayDate(from: value) else { return value.isBlank ? nil : value }
        return Self.birthdayDisplayFormatter.string(from: date)
    }

    private func isAtLeast18(_ date: Date) -> Bool {
        guard let maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) else { return false }
        return date <= maximumDate
    }
}

/// App-styled birthday picker presented as a bottom sheet.
private final class BirthdayPickerSheet: UIView {
    private let container = UIView()
    private let datePicker = UIDatePicker()
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)
    private let completion: (Date?) -> Void
    private var didFinish = false

    private init(initialDate: Date, maximumDate: Date, completion: @escaping (Date?) -> Void) {
        self.completion = completion
        super.init(frame: .zero)
        backgroundColor = AppTheme.overlay

        let backdrop = UIView()
        backdrop.backgroundColor = .clear
        addSubview(backdrop)
        backdrop.snp.makeConstraints { $0.edges.equalToSuperview() }
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        dismissTap.cancelsTouchesInView = true
        backdrop.addGestureRecognizer(dismissTap)

        container.backgroundColor = AppTheme.bgSheet
        container.layer.cornerRadius = 20
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        container.layer.masksToBounds = true
        addSubview(container)

        let titleLabel = UILabel()
        titleLabel.text = "Date of birth"
        titleLabel.font = AppFont.bodySecondary()
        titleLabel.textColor = AppTheme.textTertiary
        titleLabel.textAlignment = .center
        container.addSubview(titleLabel)

        let divider = UIView()
        divider.backgroundColor = AppTheme.divider
        container.addSubview(divider)

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.calendar = Calendar(identifier: .gregorian)
        datePicker.locale = Locale(identifier: "en_US_POSIX")
        datePicker.minimumDate = Calendar.current.date(byAdding: .year, value: -120, to: Date())
        datePicker.maximumDate = maximumDate
        datePicker.date = min(initialDate, maximumDate)
        datePicker.tintColor = AppTheme.ink
        container.addSubview(datePicker)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(AppTheme.textSecondary, for: .normal)
        cancelButton.titleLabel?.font = AppFont.sheetItem()
        cancelButton.addAction(UIAction { [weak self] _ in self?.cancel() }, for: .touchUpInside)

        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(AppTheme.ink, for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        doneButton.backgroundColor = AuthDesign.lime
        doneButton.layer.cornerRadius = 14
        doneButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.finish(self.datePicker.date)
        }, for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        actions.axis = .horizontal
        actions.spacing = 10
        actions.distribution = .fillEqually
        container.addSubview(actions)

        container.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(380)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
            make.height.equalTo(22)
        }
        divider.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(4)
            make.left.right.equalToSuperview()
            make.height.equalTo(216)
        }
        actions.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(datePicker.snp.bottom).offset(8)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().inset(UIApplication.shared.activeKeyWindow?.safeAreaInsets.bottom ?? 0)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    static func present(initialDate: Date, maximumDate: Date, completion: @escaping (Date?) -> Void) {
        guard let host = UIApplication.shared.activeKeyWindow else { return }
        let sheet = BirthdayPickerSheet(initialDate: initialDate, maximumDate: maximumDate, completion: completion)
        host.addSubview(sheet)
        sheet.snp.makeConstraints { $0.edges.equalToSuperview() }
        host.layoutIfNeeded()
        sheet.container.transform = CGAffineTransform(translationX: 0, y: sheet.container.bounds.height)
        sheet.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 0.35) {
            sheet.alpha = 1
            sheet.container.transform = .identity
        }
    }

    @objc private func cancel() { finish(nil) }

    private func finish(_ date: Date?) {
        guard !didFinish else { return }
        didFinish = true
        UIView.animate(withDuration: 0.22, animations: {
            self.alpha = 0
            self.container.transform = CGAffineTransform(translationX: 0, y: self.container.bounds.height)
        }) { _ in
            self.removeFromSuperview()
            self.completion(date)
        }
    }
}

extension CompleteProfileViewController: UITextViewDelegate, UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === birthdayField {
            handleBirthdayTapped()
            return false
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > bioLimit {
            textView.text = String(textView.text.prefix(bioLimit))
        }
        updateBioCount()
    }
}
