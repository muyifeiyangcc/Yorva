//
//  CreatePostContentViewController.swift
//  Yorva
//
//  发帖-填写内容（铁律 11 / 铁律 12）
//  - 媒体入口：自定义底部 Sheet 选择相册 / 拍照；图片按原比例显示
//  - 短答 ≤280 字
//  - Publish 前校验必填项；成功后返回来源根页 + 刷新关联页面
//

import UIKit
import SnapKit

final class CreatePostContentViewController: BaseViewController {

    var selectedPrompt: PromptItem?
    override var pageBackgroundColor: UIColor { AppTheme.bgPrimary }
    override var isSecondaryLevel: Bool { true }

    private let promptLabel = UILabel()
    private let mediaCard = UIView()
    private let mediaAddButton = UIButton(type: .system)
    private let mediaPreview = UIView()
    private let answerTextView = UITextView()
    private let countLabel = UILabel()
    private let publishButton = PrimaryButton(title: "Publish")
    private let errorLabel = UILabel()
    private var pickedRatio: CGFloat = 1.5
    private var pickedColor: UIColor = AppTheme.cream
    private var hasMedia: Bool = false
    private let answerLimit = 280

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Post"
        setupHierarchy()
        applyAutoLayoutConstraints()
    }

    override func setupHierarchy() {
        promptLabel.font = AppFont.cardTitleSemibold()
        promptLabel.textColor = AppTheme.olive
        promptLabel.numberOfLines = 0
        promptLabel.text = selectedPrompt?.title ?? "Untitled prompt"

        mediaCard.backgroundColor = AppTheme.bgRoot
        mediaCard.layer.cornerRadius = 12
        mediaCard.layer.masksToBounds = true
        mediaCard.addSubview(mediaPreview)
        mediaPreview.backgroundColor = pickedColor
        mediaAddButton.setTitle("Add a photo or video", for: .normal)
        mediaAddButton.setTitleColor(AppTheme.textBrand, for: .normal)
        mediaAddButton.titleLabel?.font = AppFont.buttonTextLink()
        mediaAddButton.addAction(UIAction { [weak self] _ in self?.openMediaSheet() }, for: .touchUpInside)
        mediaCard.addSubview(mediaAddButton)

        answerTextView.font = AppFont.body()
        answerTextView.textColor = AppTheme.ink
        answerTextView.backgroundColor = AppTheme.bgRoot
        answerTextView.layer.cornerRadius = 12
        answerTextView.layer.borderWidth = 1
        answerTextView.layer.borderColor = AppTheme.divider.cgColor
        answerTextView.delegate = self
        answerTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)

        countLabel.font = AppFont.caption()
        countLabel.textColor = AppTheme.stone
        countLabel.textAlignment = .right
        countLabel.text = "0/\(answerLimit)"

        publishButton.addAction(UIAction { [weak self] _ in self?.attemptPublish() }, for: .touchUpInside)
        errorLabel.font = AppFont.textFieldError()
        errorLabel.textColor = AppTheme.textError
        errorLabel.numberOfLines = 0

        [promptLabel, mediaCard, answerTextView, countLabel, errorLabel, publishButton].forEach { view.addSubview($0) }
    }

    override func applyAutoLayoutConstraints() {
        promptLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        mediaCard.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(180)
        }
        mediaPreview.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        mediaAddButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        answerTextView.snp.makeConstraints { make in
            make.top.equalTo(mediaCard.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(120)
        }
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(answerTextView.snp.bottom).offset(4)
            make.right.equalToSuperview().offset(-16)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(16)
        }
        publishButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
        }
    }

    // MARK: - Media Sheet（铁律 11 / 12）

    private func openMediaSheet() {
        CustomSheet.show(title: "Add media", items: [
            SheetItem(title: "Choose from album", icon: "photo.on.rectangle", isCancel: false) { [weak self] in
                self?.applyMedia(ratio: 1.4, color: .placeholderTint)
            },
            SheetItem(title: "Take photo", icon: "camera", isCancel: false) { [weak self] in
                self?.applyMedia(ratio: 1.0, color: .placeholderTint)
            },
            SheetItem(title: "Record 30s video", icon: "video", isCancel: false) { [weak self] in
                self?.applyMedia(ratio: 1.78, color: .placeholderTint, isVideo: true)
            },
            SheetItem(title: "Cancel", icon: nil, isCancel: true, handler: nil)
        ])
    }

    private func applyMedia(ratio: CGFloat, color: UIColor, isVideo: Bool = false) {
        hasMedia = true
        pickedRatio = ratio
        pickedColor = color
        mediaPreview.backgroundColor = color
        mediaAddButton.setTitle(isVideo ? "Change video" : "Change photo", for: .normal)
    }

    // MARK: - Publish

    private func attemptPublish() {
        guard hasMedia else { errorLabel.text = "Please add a photo or video."; return }
        let answer = answerTextView.text ?? ""
        guard !answer.isBlank else { errorLabel.text = "Please write a short answer (1-3 sentences)."; return }
        errorLabel.text = ""
        guard let me = AccountManager.shared.currentUser else { return }
        let media = PostMedia(kind: .image, aspectRatio: pickedRatio, duration: nil, placeholderColor: pickedColor)
        _ = ContentManager.shared.createPost(authorId: me.id,
                                             promptId: selectedPrompt?.id,
                                             themeId: selectedPrompt?.themeId,
                                             media: media, answer: answer)
        Toast.show("Post published")
        navigationController?.popToRootViewController(animated: true)
    }
}

extension CreatePostContentViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > answerLimit {
            textView.text = String(textView.text.prefix(answerLimit))
        }
        countLabel.text = "\(textView.text.count)/\(answerLimit)"
    }
}
