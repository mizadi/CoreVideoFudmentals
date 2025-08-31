//
//  VideoPicker.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 28/08/2025.
//


import SwiftUI
import PhotosUI

struct VideoPicker: UIViewControllerRepresentable {
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        init(_ parent: VideoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first?.itemProvider, item.hasItemConformingToTypeIdentifier("public.movie") else { return }
            item.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, _ in
                guard let url = url else { return }
                // Copy to a temp location we own
                let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".mov")
                try? FileManager.default.copyItem(at: url, to: tmp)
                DispatchQueue.main.async { self.parent.onPick(tmp) }
            }
        }
    }

    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.selectionLimit = 1
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
}
