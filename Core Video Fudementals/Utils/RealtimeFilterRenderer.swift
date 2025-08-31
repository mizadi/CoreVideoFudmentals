//
//  RealtimeFilterRenderer.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 28/08/2025.
//

import AVFoundation
import CoreImage
import QuartzCore
import UIKit

final class RealtimeFilterRenderer {
    private let player: AVPlayer
    private let output: AVPlayerItemVideoOutput
    private let ciContext = CIContext()
    private var displayLink: CADisplayLink?
    private weak var layer: CALayer?

    init(url: URL, renderLayer: CALayer) {
        self.layer = renderLayer
        let item = AVPlayerItem(asset: AVAsset(url: url))
        self.output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ])
        item.add(output)
        self.player = AVPlayer(playerItem: item)
    }

    func start() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .default)
        player.play()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        player.pause()
    }

    @objc private func tick() {
        let hostTime = CACurrentMediaTime()
        let itemTime = output.itemTime(forHostTime: hostTime)
        guard output.hasNewPixelBuffer(forItemTime: itemTime),
              let pb = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil),
              let layer = layer else { return }

        var image = CIImage(cvPixelBuffer: pb)

        // Example filter chain
        if let mono = CIFilter(name: "CIColorMonochrome") {
            mono.setValue(image, forKey: kCIInputImageKey)
            mono.setValue(CIColor(red: 0.85, green: 0.85, blue: 0.85), forKey: kCIInputColorKey)
            mono.setValue(0.9, forKey: kCIInputIntensityKey)
            image = mono.outputImage ?? image
        }
        if let vignette = CIFilter(name: "CIVignette") {
            vignette.setValue(image, forKey: kCIInputImageKey)
            vignette.setValue(1.0, forKey: kCIInputIntensityKey)
            vignette.setValue(2.0, forKey: kCIInputRadiusKey)
            image = vignette.outputImage ?? image
        }

        guard let cg = ciContext.createCGImage(image, from: image.extent) else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.contents = cg
        layer.contentsGravity = .resizeAspect
        layer.contentsScale = UIScreen.main.scale
        CATransaction.commit()
    }
}
