//
//  FrameExtractView.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 28/08/2025.
//


import SwiftUI

struct FrameExtractView: View {
    @State private var videoURL: URL?
    @State private var thumbnails: [UIImage] = []
    @State private var isPicking = false
    @State private var isBusy = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Pick Video") { isPicking = true }
                    .buttonStyle(.borderedProminent)
                Button("Extract") { Task { await runExtract() } }
                    .buttonStyle(.bordered)
                    .disabled(videoURL == nil || isBusy)
            }

            if let url = videoURL {
                Text("Selected: \(url.lastPathComponent)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if isBusy { ProgressView("Decoding frames…") }

            if let errorText {
                Text(errorText).foregroundStyle(.red).font(.footnote)
            }

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(thumbnails.indices, id: \.self) { i in
                        Image(uiImage: thumbnails[i])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle("Frame Extraction")
        .sheet(isPresented: $isPicking) {
            VideoPicker { url in
                self.videoURL = url
                self.thumbnails = []
            }
        }
    }

    private func runExtract() async {
        guard let url = videoURL else { return }
        isBusy = true; errorText = nil; thumbnails = []
        do {
            let images = try await FrameExtractor(url: url).extract(everyNthFrame: 10, maxCount: 150)
            self.thumbnails = images
            self.isBusy = false
        } catch {
            self.errorText = error.localizedDescription
            self.isBusy = false
        }
    }
}

