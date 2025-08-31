//
//  ExportPipelineView.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 28/08/2025.
//

import SwiftUI
import AVKit

struct ExportPipelineView: View {
    @State private var videoURL: URL?
    @State private var isPicking = false
    @State private var progress: Double = 0
    @State private var exporting = false
    @State private var exportedURL: URL?
    @State private var errorText: String?
    @State private var showShare = false
    @State private var showPlayer = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Pick Video") { isPicking = true }
                    .buttonStyle(.borderedProminent)

                Button("Export (Noir)") { Task { await runExport(filter: "CIPhotoEffectNoir") } }
                    .buttonStyle(.bordered)
                    .disabled(videoURL == nil || exporting)
            }

            if let url = videoURL {
                Text("Selected: \(url.lastPathComponent)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            if exporting {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exporting…").font(.footnote)
                    ProgressView(value: progress)
                }.padding(.horizontal)
            }

            if let out = exportedURL {
                VStack(spacing: 10) {
                    Text("Exported: \(out.lastPathComponent)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    HStack {
                        Button("Preview") { showPlayer = true }
                        Button("Save to Photos") { saveToPhotos(out) }
                        Button("Share…") { showShare = true }
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let errorText {
                Text(errorText).foregroundStyle(.red).font(.footnote)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Offline Export")
        .sheet(isPresented: $isPicking) {
            VideoPicker { url in
                self.videoURL = url
                self.exportedURL = nil
                self.progress = 0
                self.errorText = nil
            }
        }
        .sheet(isPresented: $showShare) {
            if let out = exportedURL { ActivityView(activityItems: [out]) }
        }
        .sheet(isPresented: $showPlayer) {
            if let out = exportedURL { AVPlayerViewControllerRepresentable(url: out) }
        }
        .alert("Notice", isPresented: $showAlert, actions: { Button("OK", role: .cancel) {} }, message: { Text(alertMessage) })
    }

    private func runExport(filter: String?) async {
        guard let url = videoURL else { return }
        exporting = true; errorText = nil; exportedURL = nil; progress = 0

        // Prefer .mov on Simulator for reliability
        let dest = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("export-\(UUID().uuidString).mov")

        do {
            let exporter = SimpleFilterExporter(url: url)
            try await exporter.export(to: dest, effect: .cinematic(bloomIntensity: 0.7, bloomRadius: 12, vignette: 0.9)) { p in
                DispatchQueue.main.async { self.progress = p }
            }
            await MainActor.run {
                self.exportedURL = dest
                self.exporting = false
                self.progress = 1
            }
        } catch {
            await MainActor.run {
                self.errorText = error.localizedDescription
                self.exporting = false
            }
        }
    }

    private func saveToPhotos(_ url: URL) {
        PhotoSaver.saveVideoToPhotos(url: url) { result in
            switch result {
            case .success:
                alertMessage = "Saved to Photos successfully."
                showAlert = true
            case .failure(let err):
                alertMessage = "Failed to save: \(err.localizedDescription)"
                showAlert = true
            }
        }
    }
}

// MARK: - AVPlayer preview

private struct AVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = AVPlayer(url: url)
        return vc
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
