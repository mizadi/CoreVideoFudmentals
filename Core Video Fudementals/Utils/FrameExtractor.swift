//
//  FrameExtractor.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 28/08/2025.
//

import AVFoundation
import CoreImage
import UIKit

enum FrameExtractError: Error { case noVideoTrack, unknown }

final class FrameExtractor {
    private let asset: AVAsset
    private let ciContext = CIContext(options: nil)

    init(url: URL) { self.asset = AVAsset(url: url) }

    /// Extracts up to `maxCount` images, sampling every Nth decoded frame.
    func extract(everyNthFrame: Int = 10, maxCount: Int = 200) throws -> [UIImage] {
        guard let track = asset.tracks(withMediaType: .video).first else {
            throw FrameExtractError.noVideoTrack
        }

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ])
        output.alwaysCopiesSampleData = false
        reader.add(output)

        var images: [UIImage] = []
        var frameIndex = 0

        reader.startReading()
        while reader.status == .reading, let sample = output.copyNextSampleBuffer() {
            defer { frameIndex += 1 }
            guard frameIndex % everyNthFrame == 0 else { continue }
            guard let pb = sample.imageBuffer else { continue }

            let ci = CIImage(cvPixelBuffer: pb)
            if let cg = ciContext.createCGImage(ci, from: ci.extent) {
                images.append(UIImage(cgImage: cg))
                if images.count >= maxCount { break }
            }
        }

        if reader.status == .failed { throw reader.error ?? FrameExtractError.unknown }
        return images
    }
}
