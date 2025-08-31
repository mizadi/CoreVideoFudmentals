//
//  SimpleExportError.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 31/08/2025.
//

import AVFoundation
import CoreImage

enum SimpleExportError: Error, LocalizedError {
    case noVideoTrack
    case cannotCreateSession
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .noVideoTrack: return "No video track found in asset."
        case .cannotCreateSession: return "Could not create AVAssetExportSession."
        case .exportFailed(let msg): return "Export failed: \(msg)"
        }
    }
}

/// A few tasteful, simulator-safe effects you can showcase.
enum ExportEffect {
    case cinematic(bloomIntensity: Double = 0.6, bloomRadius: Double = 10, vignette: Double = 0.8) // glow + vignette
    case sepia(intensity: Double = 0.9)
    case duotone(shadows: CIColor = CIColor(red: 0.1, green: 0.2, blue: 0.3),
                 highlights: CIColor = CIColor(red: 0.95, green: 0.75, blue: 0.35)) // teal/orange
    case comic // comic-book stylization
}

final class SimpleFilterExporter {
    private let asset: AVAsset

    init(url: URL) {
        self.asset = AVAsset(url: url)
    }

    /// Export using AVMutableVideoComposition + AVAssetExportSession (simulator-safe).
    /// - Parameters:
    ///   - destURL: Destination file URL (use .mov for simulator reliability).
    ///   - effect: Which effect to bake in.
    ///   - progress: Synchronous progress callback (0…1).
    func export(
        to destURL: URL,
        effect: ExportEffect = .cinematic(),
        progress: @escaping (Double) -> Void
    ) async throws {
        // Remove existing file if present
        try? FileManager.default.removeItem(at: destURL)

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw SimpleExportError.noVideoTrack
        }

        // --- Build a MUTABLE video composition so we can set size & fps
        let videoComposition = AVMutableVideoComposition(asset: asset) { request in
            // Start with the source frame as a CIImage
            var img = request.sourceImage

            // Apply effect
            img = Self.apply(effect: effect, to: img)

            // Keep within the source extent to avoid odd borders
            img = img.cropped(to: request.sourceImage.extent)

            // Finish; AVFoundation handles the CIContext
            request.finish(with: img, context: nil)
        }

        // Orientation-corrected render size
        let tx = videoTrack.preferredTransform
        let orientedSize = videoTrack.naturalSize.applying(tx)
        videoComposition.renderSize = CGSize(width: abs(orientedSize.width), height: abs(orientedSize.height))

        // Frame duration: use track fps if available, fallback to 30 fps
        let fps = videoTrack.nominalFrameRate > 0 ? videoTrack.nominalFrameRate : 30
        videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(max(1, Int32(round(fps)))))

        // --- Create export session
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw SimpleExportError.cannotCreateSession
        }
        session.outputURL = destURL
        session.outputFileType = .mov            // .mov is very reliable on Simulator
        session.videoComposition = videoComposition
        session.shouldOptimizeForNetworkUse = true

        // --- Poll progress while exporting
        let progressQueue = DispatchQueue(label: "simple.export.progress")
        let progressDone = DispatchSemaphore(value: 0)
        var didFinishProgressLoop = false

        progressQueue.async {
            while true {
                progress(Double(session.progress))
                if session.status != .exporting { break }
                Thread.sleep(forTimeInterval: 0.1)
            }
            didFinishProgressLoop = true
            progressDone.signal()
        }

        // --- Run export
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            session.exportAsynchronously { cont.resume() }
        }

        // --- Ensure progress loop exits quickly
        if !didFinishProgressLoop {
            _ = progressDone.wait(timeout: .now() + 1.0)
        }

        // --- Final status handling
        switch session.status {
        case .completed:
            progress(1.0)
            return
        case .failed, .cancelled:
            let msg = session.error?.localizedDescription ?? "Unknown export error"
            throw SimpleExportError.exportFailed(msg)
        default:
            let msg = session.error?.localizedDescription ?? "Unexpected state \(session.status.rawValue)"
            throw SimpleExportError.exportFailed(msg)
        }
    }

    // MARK: Effect chains

    private static func apply(effect: ExportEffect, to image: CIImage) -> CIImage {
        switch effect {
        case .sepia(let intensity):
            let f = CIFilter(name: "CISepiaTone")!
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(intensity, forKey: kCIInputIntensityKey)
            return f.outputImage ?? image

        case .duotone(let shadows, let highlights):
            // Convert to mono → map luminance to two colors
            let mono = CIFilter(name: "CIPhotoEffectMono")!
            mono.setValue(image, forKey: kCIInputImageKey)
            let gray = mono.outputImage ?? image

            let falseColor = CIFilter(name: "CIFalseColor")!
            falseColor.setValue(gray, forKey: kCIInputImageKey)
            falseColor.setValue(shadows, forKey: "inputColor0")     // shadows
            falseColor.setValue(highlights, forKey: "inputColor1")  // highlights
            return falseColor.outputImage ?? gray

        case .comic:
            let f = CIFilter(name: "CIComicEffect")!
            f.setValue(image, forKey: kCIInputImageKey)
            return f.outputImage ?? image

        case .cinematic(let bloomIntensity, let bloomRadius, let vignette):
            // Bloom (soft glow)
            let bloom = CIFilter(name: "CIBloom")!
            bloom.setValue(image, forKey: kCIInputImageKey)
            bloom.setValue(bloomIntensity, forKey: kCIInputIntensityKey)
            bloom.setValue(bloomRadius, forKey: kCIInputRadiusKey)
            let bloomed = bloom.outputImage ?? image

            // Subtle contrast curve via CIColorControls (optional)
            let controls = CIFilter(name: "CIColorControls")!
            controls.setValue(bloomed, forKey: kCIInputImageKey)
            controls.setValue(1.05, forKey: kCIInputSaturationKey)
            controls.setValue(1.02, forKey: kCIInputContrastKey)
            let tuned = controls.outputImage ?? bloomed

            // Vignette
            let vig = CIFilter(name: "CIVignette")!
            vig.setValue(tuned, forKey: kCIInputImageKey)
            vig.setValue(vignette, forKey: kCIInputIntensityKey)
            vig.setValue(1.2 * max(image.extent.width, image.extent.height) / 300.0, forKey: kCIInputRadiusKey)
            return vig.outputImage ?? tuned
        }
    }
}
