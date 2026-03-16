//
//  ContentView.swift
//  zjl-mp3
//
//  Created by ZhangJinglin on 2026/3/15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var controller = PlaybackController()
    @State private var showPicker = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack {
                        Text(controller.folderDisplayName)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Pick Folder") {
                            showPicker = true
                        }
                    }
                    .padding(.horizontal)

                    if let errorMessage = controller.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                    }
                }

                if controller.playlist.isEmpty {
                    Spacer()
                    Text("No MP3 files in selected folder.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(Array(controller.playlist.enumerated()), id: \.element) { index, url in
                            Button {
                                controller.playItem(at: index)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(url.lastPathComponent)
                                            .font(.body)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    if controller.currentIndex == index {
                                        Text(controller.isPlaying ? "Playing" : "Paused")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                PlayerView(controller: controller)
                    .padding(.horizontal)
            }
            .navigationTitle("zjl-mp3")
            .sheet(isPresented: $showPicker) {
                FolderPickerView { url in
                    controller.loadFolder(url: url)
                }
            }
            .onAppear {
                controller.restoreBookmarkIfNeeded()
            }
        }
    }
}

#Preview {
    ContentView()
}
