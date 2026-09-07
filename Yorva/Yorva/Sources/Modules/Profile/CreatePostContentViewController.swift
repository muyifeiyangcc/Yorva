//
//  CreatePostContentViewController.swift
//  Yorva
//
//  发帖第二步：选择媒体、填写短答并发布。
//

import UIKit
import SnapKit

final class CreatePostContentViewController: BaseViewController {

    var selectedPrompt: PromptItem?
    override var pageBackgroundColor: UIColor { UIColor(hex: 0xFAF9F3) }
    override var isSecondaryLevel: Bool { true }
    override func shouldUseScrollContainer() -> Bool { true }

    private let brandLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressDone = UIView()
    private let progressRemaining = UIView()
    private let mediaSectionLabel = UILabel()
    private let mediaRequiredLabel = UILabel()
    private let mediaCard = UIView()
    private let mediaBackground = UIImageView()
    private let mediaPreview = UIImageView()
    private let mediaIcon = UIImageView()
    private let mediaTitleLabel = UILabel()
    private let mediaHintLabel = UILabel()
    private let mediaAddButton = UIButton(type: .system)
    private let answerSectionLabel = UILabel()
    private let answerRequiredLabel = UILabel()
    private let answerTextView = UITextView()
    private let answerPlaceholderLabel = UILabel()
    private let countLabel = UILabel()
    private let recommendationLabel = UILabel()
    private let errorLabel = UILabel()
    private let bottomBar = UIView()
    private let bottomHintLabel = UILabel()
    private let publishButton = UIButton(type: .system)

    private var pickedRatio: CGFloat = 1.5
    private var pickedColor: UIColor = AppTheme.cream
    private var pickedImage: UIImage?
    private var pickedVideoURL: URL?
    private var pickedKind: PostMedia.Kind = .image
    private var pickedDuration: TimeInterval?
    private var hasMedia = false
    private let answerLimit = 280
    private var mediaPicker: MediaPickerCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let hostWidth = (contentView ?? view).bounds.width
        let textWidth = max(0, hostWidth - 34)
        if textWidth > 0, titleLabel.preferredMaxLayoutWidth != textWidth {
            titleLabel.preferredMaxLayoutWidth = textWidth
        }
    }

    override func setupHierarchy() {
        brandLabel.text = "yorva"
        brandLabel.font = .systemFont(ofSize: 21, weight: .bold)
        brandLabel.textColor = AppTheme.ink

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor(hex: 0x777A72), for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 17
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        cancelButton.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = -5
        titleLabel.attributedText = NSAttributedString(string: "Make something\nworth keeping.", attributes: [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: AppTheme.ink,
            .paragraphStyle: paragraph
        ])
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.text = "One prompt, one visual, one honest answer."
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor(hex: 0x7B7E77)
        progressDone.backgroundColor = UIColor(hex: 0x0D110F)
        progressRemaining.backgroundColor = UIColor(hex: 0xE3E4E1)
        [progressDone, progressRemaining].forEach { $0.layer.cornerRadius = 2 }

        mediaSectionLabel.text = "Add Photo / Video"
        mediaSectionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        mediaSectionLabel.textColor = AppTheme.ink
        mediaRequiredLabel.text = "Required"
        mediaRequiredLabel.font = .systemFont(ofSize: 10, weight: .regular)
        mediaRequiredLabel.textColor = UIColor(hex: 0x7B7E77)

        mediaCard.layer.cornerRadius = 22
        mediaCard.layer.masksToBounds = true
        mediaCard.backgroundColor = UIColor(hex: 0xDDF9F7)
        mediaBackground.image = UIImage(named: "pub_bg")
        mediaBackground.contentMode = .scaleAspectFill
        mediaBackground.clipsToBounds = true
        mediaPreview.contentMode = .scaleAspectFill
        mediaPreview.clipsToBounds = true
        mediaPreview.isHidden = true
        mediaIcon.image = UIImage(systemName: "photo")?.withTintColor(AppTheme.ink, renderingMode: .alwaysOriginal)
        mediaIcon.backgroundColor = .white
        mediaIcon.layer.cornerRadius = 14
        mediaIcon.contentMode = .center
        mediaTitleLabel.text = "Add one visual"
        mediaTitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        mediaTitleLabel.textColor = AppTheme.ink
        mediaTitleLabel.textAlignment = .center
        mediaHintLabel.text = "1 photo or 1 short video · max 30s"
        mediaHintLabel.font = .systemFont(ofSize: 10, weight: .regular)
        mediaHintLabel.textColor = UIColor(hex: 0x52706D)
        mediaHintLabel.textAlignment = .center
        mediaAddButton.setTitle("Choose media", for: .normal)
        mediaAddButton.setTitleColor(.white, for: .normal)
        mediaAddButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .regular)
        mediaAddButton.backgroundColor = UIColor(hex: 0x0D110F)
        mediaAddButton.layer.cornerRadius = 17
        mediaAddButton.addAction(UIAction { [weak self] _ in self?.openMediaSheet() }, for: .touchUpInside)
        [mediaBackground, mediaPreview, mediaIcon, mediaTitleLabel, mediaHintLabel, mediaAddButton].forEach { mediaCard.addSubview($0) }

        answerSectionLabel.text = "Short Answer"
        answerSectionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        answerSectionLabel.textColor = AppTheme.ink
        answerRequiredLabel.text = "Required"
        answerRequiredLabel.font = .systemFont(ofSize: 10, weight: .regular)
        answerRequiredLabel.textColor = UIColor(hex: 0x7B7E77)
        answerTextView.font = .systemFont(ofSize: 14, weight: .regular)
        answerTextView.textColor = AppTheme.ink
        answerTextView.backgroundColor = .white
        answerTextView.layer.cornerRadius = 18
        answerTextView.layer.borderWidth = 1
        answerTextView.layer.borderColor = UIColor(hex: 0xE1E0D9).cgColor
        answerTextView.delegate = self
        answerTextView.textContainerInset = UIEdgeInsets(top: 15, left: 14, bottom: 12, right: 14)
        answerPlaceholderLabel.text = "Write a short answer to the prompt..."
        answerPlaceholderLabel.font = .systemFont(ofSize: 14, weight: .regular)
        answerPlaceholderLabel.textColor = UIColor(hex: 0xA4A69F)
        answerTextView.addSubview(answerPlaceholderLabel)
        recommendationLabel.text = "1–3 sentences recommended"
        recommendationLabel.font = .systemFont(ofSize: 10, weight: .regular)
        recommendationLabel.textColor = UIColor(hex: 0x7B7E77)
        countLabel.text = "0 / \(answerLimit)"
        countLabel.font = .systemFont(ofSize: 10, weight: .regular)
        countLabel.textColor = UIColor(hex: 0x7B7E77)
        countLabel.textAlignment = .right
        errorLabel.font = .systemFont(ofSize: 11, weight: .regular)
        errorLabel.textColor = UIColor(hex: 0xC0392B)
        errorLabel.numberOfLines = 0

        bottomBar.backgroundColor = .white
        bottomBar.layer.cornerRadius = 20
        bottomBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        bottomBar.layer.shadowOpacity = 1
        bottomBar.layer.shadowRadius = 14
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: 4)
        bottomHintLabel.text = "Your post will appear in the Yorva feed."
        bottomHintLabel.font = .systemFont(ofSize: 10, weight: .regular)
        bottomHintLabel.textColor = UIColor(hex: 0x7B7E77)
        publishButton.setTitle("Publish", for: .normal)
        publishButton.setTitleColor(AppTheme.ink, for: .normal)
        publishButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        publishButton.backgroundColor = UIColor(hex: 0xD9FF3F)
        publishButton.layer.cornerRadius = 20
        publishButton.addAction(UIAction { [weak self] _ in self?.attemptPublish() }, for: .touchUpInside)

        let host = contentView ?? view!
        [brandLabel, cancelButton, titleLabel, subtitleLabel, progressDone, progressRemaining,
         mediaSectionLabel, mediaRequiredLabel, mediaCard, answerSectionLabel, answerRequiredLabel,
         answerTextView, recommendationLabel, countLabel, errorLabel].forEach { host.addSubview($0) }
        [bottomHintLabel, publishButton].forEach { bottomBar.addSubview($0) }
        view.addSubview(bottomBar)
    }

    override func applyAutoLayoutConstraints() {
        let host = contentView ?? view!
        brandLabel.snp.makeConstraints { make in
            make.top.equalTo(host).offset(20)
            make.left.equalToSuperview().offset(19)
            make.height.equalTo(28)
        }
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(host).offset(12)
            make.right.equalToSuperview().inset(19)
            make.width.equalTo(61)
            make.height.equalTo(34)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(brandLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(17)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.left.right.equalTo(titleLabel)
        }
        progressDone.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(17)
            make.left.equalTo(titleLabel)
            make.width.equalTo(168)
            make.height.equalTo(4)
        }
        progressRemaining.snp.makeConstraints { make in
            make.centerY.equalTo(progressDone)
            make.left.equalTo(progressDone.snp.right).offset(7)
            make.right.equalTo(titleLabel)
            make.height.equalTo(4)
        }
        mediaSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(progressDone.snp.bottom).offset(18)
            make.left.equalTo(titleLabel)
        }
        mediaRequiredLabel.snp.makeConstraints { make in
            make.centerY.equalTo(mediaSectionLabel)
            make.right.equalTo(titleLabel)
        }
        mediaCard.snp.makeConstraints { make in
            make.top.equalTo(mediaSectionLabel.snp.bottom).offset(12)
            make.left.right.equalTo(titleLabel)
            make.height.equalTo(202)
        }
        mediaBackground.snp.makeConstraints { make in make.edges.equalToSuperview() }
        mediaPreview.snp.makeConstraints { make in make.edges.equalToSuperview() }
        mediaIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(33)
            make.size.equalTo(44)
        }
        mediaTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(mediaIcon.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(16)
        }
        mediaHintLabel.snp.makeConstraints { make in
            make.top.equalTo(mediaTitleLabel.snp.bottom).offset(6)
            make.left.right.equalToSuperview().inset(16)
        }
        mediaAddButton.snp.makeConstraints { make in
            make.top.equalTo(mediaHintLabel.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(34)
        }
        answerSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(mediaCard.snp.bottom).offset(24)
            make.left.equalTo(titleLabel)
        }
        answerRequiredLabel.snp.makeConstraints { make in
            make.centerY.equalTo(answerSectionLabel)
            make.right.equalTo(titleLabel)
        }
        answerTextView.snp.makeConstraints { make in
            make.top.equalTo(answerSectionLabel.snp.bottom).offset(12)
            make.left.right.equalTo(titleLabel)
            make.height.equalTo(127)
        }
        answerPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(14)
            make.right.equalToSuperview().inset(14)
        }
        recommendationLabel.snp.makeConstraints { make in
            make.top.equalTo(answerTextView.snp.bottom).offset(12)
            make.left.equalTo(titleLabel)
        }
        countLabel.snp.makeConstraints { make in
            make.centerY.equalTo(recommendationLabel)
            make.right.equalTo(titleLabel)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendationLabel.snp.bottom).offset(4)
            make.left.right.equalTo(titleLabel)
        }
        errorLabel.isHidden = true
        errorLabel.snp.makeConstraints { make in
            make.bottom.equalTo(host).offset(-24)
        }
        bottomBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(61)
        }
        bottomHintLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(publishButton.snp.left).offset(-8)
        }
        publishButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(78)
            make.height.equalTo(40)
        }
    }

    // MARK: - Media

    private func openMediaSheet() {
        CustomSheet.show(title: "Add media", items: [
            SheetItem(title: "Choose from album", icon: "photo.on.rectangle", isCancel: false) { [weak self] in
                self?.presentMediaPicker(source: .photoLibrary)
            },
            SheetItem(title: "Take photo", icon: "camera", isCancel: false) { [weak self] in
                self?.presentMediaPicker(source: .camera)
            },
            SheetItem(title: "Record 30s video", icon: "video", isCancel: false) { [weak self] in
                self?.presentMediaPicker(source: .cameraVideo)
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ])
    }

    private func presentMediaPicker(source: MediaPickerCoordinator.Source) {
        mediaPicker = MediaPickerCoordinator(presenter: self, allowsVideo: true) { [weak self] selection in
            guard let self = self, let selection = selection else { return }
            self.applyMedia(selection)
        }
        mediaPicker?.present(source: source)
    }

    private func applyMedia(_ selection: MediaSelection) {
        hasMedia = true
        pickedRatio = selection.aspectRatio
        pickedKind = selection.kind
        pickedDuration = selection.duration
        pickedImage = selection.image
        pickedVideoURL = selection.videoURL
        pickedColor = selection.image == nil ? AppTheme.cream : .placeholderTint
        mediaPreview.backgroundColor = pickedColor
        mediaPreview.image = selection.image
        mediaPreview.isHidden = selection.image == nil
        mediaBackground.isHidden = selection.image != nil
        mediaIcon.isHidden = selection.image != nil
        mediaTitleLabel.text = selection.kind == .video ? "Video selected" : "Photo selected"
        mediaHintLabel.text = selection.kind == .video ? "Tap to replace · max 30s" : "Tap to replace this photo"
        mediaAddButton.setTitle("Change media", for: .normal)
    }

    // MARK: - Publish

    private func attemptPublish() {
        guard hasMedia else {
            showError("Please add a photo or video.")
            return
        }
        let answer = answerTextView.text ?? ""
        guard !answer.isBlank else {
            showError("Please write a short answer (1–3 sentences).")
            return
        }
        errorLabel.isHidden = true
        guard let me = AccountManager.shared.currentUser else { return }
        let media = PostMedia(kind: pickedKind, aspectRatio: pickedRatio, duration: pickedDuration,
                              placeholderColor: pickedColor, image: pickedImage, videoURL: pickedVideoURL)
        _ = ContentManager.shared.createPost(authorId: me.id,
                                             promptId: selectedPrompt?.id,
                                             themeId: selectedPrompt?.themeId,
                                             media: media, answer: answer)
        Toast.show("Post published")
        navigationController?.popToRootViewController(animated: true)
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}

extension CreatePostContentViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > answerLimit {
            textView.text = String(textView.text.prefix(answerLimit))
        }
        answerPlaceholderLabel.isHidden = !textView.text.isEmpty
        countLabel.text = "\(textView.text.count) / \(answerLimit)"
        if !textView.text.isEmpty { errorLabel.isHidden = true }
    }
}
