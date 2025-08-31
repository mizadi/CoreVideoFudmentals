# Core Video Fundamentals

A learning project that explores **Core Video** and **AVFoundation** on iOS.  
This repo demonstrates three pillars of video processing:

1. Frame Extraction – Decode a video into individual frames for thumbnails or analysis.
2. Real-Time Filtering – Apply Core Image filters live while a video is playing.
3. Offline Export – Bake Core Image effects into a new video file and save/share it.

Built with SwiftUI + UIKit integration. Runs on both Simulator and device.

---

## Features

### 1. Frame Extraction
- Uses `AVAssetReader` to decode raw frames.
- Converts each `CMSampleBuffer` into `UIImage` thumbnails.
- Displays them in a grid with SwiftUI’s `LazyVGrid`.

Use case: generating video thumbnails, building scrub bars like YouTube.

---

### 2. Real-Time Filtering
- Uses `AVPlayerItemVideoOutput` to intercept frames during playback.
- Applies a simple Core Image filter chain (monochrome + vignette).
- Renders back to a `CALayer` for smooth playback.

Use case: live effects like Instagram/TikTok filters, AR overlays, live previews.

---

### 3. Offline Export (Filtered Video)
- Uses `AVMutableVideoComposition` with a Core Image filter handler.
- Runs an `AVAssetExportSession` to re-encode the filtered frames.
- Produces a new `.mov` file that can be previewed, saved to Photos, or shared.

Use case: permanent edits – watermarks, stylized looks, or post-processing before upload.

---

## Export Effects

You can choose from several built-in effect chains:

- Cinematic – Bloom glow + subtle contrast + vignette.
- Sepia – Warm, vintage film tone.
- Duotone – Teal/orange shadow-highlight mapping.
- Comic – Stylized edge/ink filter.

Example:

```swift
let exporter = SimpleFilterExporter(url: videoURL)
try await exporter.export(to: dest,
                          effect: .cinematic(bloomIntensity: 0.7,
                                             bloomRadius: 12,
                                             vignette: 0.9)) { p in
    DispatchQueue.main.async { self.progress = p }
}

