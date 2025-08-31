//
//  RealtimeFilterView.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 28/08/2025.
//


import SwiftUI

struct RealtimeFilterView: View {
    @State private var videoURL: URL?
    @State private var isPicking = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Pick Video") { isPicking = true }
                    .buttonStyle(.borderedProminent)
            }
            FilterPreview(url: videoURL)
                .overlay {
                    if videoURL == nil {
                        Text("Pick a video to start").foregroundStyle(.secondary)
                    }
                }
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .navigationTitle("Real-Time Filtering")
        .sheet(isPresented: $isPicking) {
            VideoPicker { url in self.videoURL = url }
        }
    }
}

private struct FilterPreview: UIViewRepresentable {
    let url: URL?

    final class ViewBox: UIView {
        var renderer: RealtimeFilterRenderer?
        override class var layerClass: AnyClass { CALayer.self }
        func configure(with url: URL?) {
            renderer?.stop()
            (layer as? CALayer)?.contents = nil
            guard let url else { return }
            renderer = RealtimeFilterRenderer(url: url, renderLayer: self.layer)
            renderer?.start()
        }
        deinit { renderer?.stop() }
    }

    func makeUIView(context: Context) -> ViewBox { ViewBox() }
    func updateUIView(_ uiView: ViewBox, context: Context) { uiView.configure(with: url) }
}
