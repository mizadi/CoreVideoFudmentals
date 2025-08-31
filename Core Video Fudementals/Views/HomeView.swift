//
//  HomeView.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 28/08/2025.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("1) Frame Extraction") { FrameExtractView() }
                NavigationLink("2) Real-Time Filtering") { RealtimeFilterView() }
                NavigationLink("3) Offline Export") { ExportPipelineView() }
            }
            .navigationTitle("Core Video Fundamentals")
        }
    }
}
