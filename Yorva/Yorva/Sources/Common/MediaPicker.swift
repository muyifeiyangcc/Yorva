//
//  MediaPicker.swift
//  Yorva
//
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct MediaSelection {
    let image: UIImage?
    let videoURL: URL?
    let kind: PostMedia.Kind
    let aspectRatio: CGFloat
    let duration: TimeInterval?
}

final class MediaPickerCoordinator: NSObject {

    enum Source: Equatable { case photoLibrary, camera, cameraVideo }

    weak var presenter: UIViewController?
    private let allowsVideo: Bool
    private let completion: (MediaSelection?) -> Void

    init(presenter: UIViewController, allowsVideo: Bool,
         completion: @escaping (MediaSelection?) -> Void) {
        self.presenter = presenter
        self.allowsVideo = allowsVideo
        self.completion = completion
    }

    func present(source: Source) {
        switch source {
        case .photoLibrary:
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.selectionLimit = 1
            configuration.filter = allowsVideo ? .any(of: [.images, .videos]) : .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            presenter?.present(picker, animated: true)
        case .camera, .cameraVideo:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                completion(nil)
                return
            }
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = source == .cameraVideo
                ? [UTType.movie.identifier]
                : [UTType.image.identifier]
            picker.videoMaximumDuration = 30
            picker.videoQuality = .typeHigh
            picker.delegate = self
            presenter?.present(picker, animated: true)
        }
    }

    private func finish(_ selection: MediaSelection?) {
        completion(selection)
    }

    private func selection(for image: UIImage) -> MediaSelection {
        let width = max(image.size.width, 1)
        let height = max(image.size.height, 1)
        return MediaSelection(image: image, videoURL: nil, kind: .image,
                              aspectRatio: width / height, duration: nil)
    }

    private func selection(for videoURL: URL) -> MediaSelection {
        let asset = AVAsset(url: videoURL)
        let duration = asset.duration.seconds.isFinite ? asset.duration.seconds : nil
        let track = asset.tracks(withMediaType: .video).first
        let naturalSize = track?.naturalSize ?? CGSize(width: 16, height: 9)
        let transformedSize = CGRect(origin: .zero, size: naturalSize)
            .applying(track?.preferredTransform ?? .identity).standardized.size
        let width = max(abs(transformedSize.width), 1)
        let height = max(abs(transformedSize.height), 1)
        let thumbnail = videoThumbnail(for: asset)
        return MediaSelection(image: thumbnail, videoURL: videoURL, kind: .video,
                              aspectRatio: width / height, duration: duration)
    }

    private func videoThumbnail(for asset: AVAsset) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func copyVideoToTemporaryURL(_ url: URL) -> URL? {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("yorva-video-\(UUID().uuidString).mov")
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }
}

extension MediaPickerCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        let provider = result.itemProvider
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async { self?.finish(self?.selection(for: image)) }
            }
            return
        }
        guard allowsVideo, provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { return }
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
            guard let self = self, let url = url, let copiedURL = self.copyVideoToTemporaryURL(url) else { return }
            DispatchQueue.main.async { self.finish(self.selection(for: copiedURL)) }
        }
    }
}

extension MediaPickerCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            finish(selection(for: image))
            return
        }
        if let url = info[.mediaURL] as? URL, let copiedURL = copyVideoToTemporaryURL(url) {
            finish(selection(for: copiedURL))
        }
    }
}
