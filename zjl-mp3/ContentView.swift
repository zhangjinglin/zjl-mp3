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
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 18) {
                    headerCard

                    if let errorMessage = controller.errorMessage {
                        errorBanner(errorMessage)
                    }

                    if controller.playlist.isEmpty {
                        emptyState
                    } else {
                        playlistSection
                    }

                    PlayerView(controller: controller)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("zjl-mp3")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
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

private extension ContentView {
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Folder Queue")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)

                    Text(controller.folderDisplayName)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 12)

                Button {
                    showPicker = true
                } label: {
                    Label("Pick Folder", systemImage: "folder.badge.gearshape")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .buttonStyle(AppCapsuleButtonStyle(fill: AppTheme.accent))
            }

            HStack(spacing: 12) {
                statPill(title: "Tracks", value: "\(controller.playlist.count)")
                statPill(title: "Speed", value: formattedRate(controller.playbackRate))
                statPill(title: "Mode", value: "Delete After Play")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow, radius: 24, y: 12)
    }

    func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.warning)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.errorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.18))
                    .frame(width: 92, height: 92)
                Image(systemName: "music.note.list")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
            Text("Pick a folder to build your queue")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
            Text("Every MP3 in that folder will play in order, start at your chosen speed, and delete itself after finishing.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    var playlistSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Playlist")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("\(controller.playlist.count) tracks")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(controller.playlist.enumerated()), id: \.element) { index, url in
                        trackRow(index: index, url: url)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    func trackRow(index: Int, url: URL) -> some View {
        let isCurrent = controller.currentIndex == index

        return Button {
            controller.playItem(at: index)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isCurrent ? AppTheme.accent : Color.white.opacity(0.06))
                        .frame(width: 46, height: 46)
                    Image(systemName: isCurrent ? (controller.isPlaying ? "waveform" : "pause.fill") : "music.note")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isCurrent ? Color.black.opacity(0.72) : AppTheme.primaryText)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(url.deletingPathExtension().lastPathComponent)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                    Text(isCurrent ? (controller.isPlaying ? "Now Playing" : "Ready to Resume") : "Tap to play this track")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(isCurrent ? AppTheme.accent : AppTheme.secondaryText)
                }

                Spacer()

                Text(trackBadge(index: index, isCurrent: isCurrent))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(isCurrent ? Color.black.opacity(0.72) : AppTheme.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isCurrent ? AppTheme.accent : Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(isCurrent ? AppTheme.activeRowBackground : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(isCurrent ? AppTheme.accent.opacity(0.55) : Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    func trackBadge(index: Int, isCurrent: Bool) -> String {
        if isCurrent {
            return controller.isPlaying ? "LIVE" : "PAUSED"
        }
        return "#\(index + 1)"
    }

    func formattedRate(_ rate: Float) -> String {
        let rounded = Int(rate)
        if Float(rounded) == rate {
            return "\(rounded)x"
        }
        return "\(rate.cleanString)x"
    }
}

enum AppTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.09, green: 0.05, blue: 0.13),
            Color(red: 0.16, green: 0.08, blue: 0.10),
            Color(red: 0.04, green: 0.05, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.48, blue: 0.28),
            Color(red: 0.74, green: 0.16, blue: 0.26)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelBackground = Color.white.opacity(0.06)
    static let activeRowBackground = Color(red: 0.43, green: 0.15, blue: 0.16).opacity(0.65)
    static let errorBackground = Color(red: 0.38, green: 0.12, blue: 0.14).opacity(0.82)
    static let accent = Color(red: 1.0, green: 0.79, blue: 0.58)
    static let warning = Color(red: 1.0, green: 0.79, blue: 0.47)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.68)
    static let shadow = Color.black.opacity(0.24)
}

struct AppCapsuleButtonStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.black.opacity(0.72))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(fill.opacity(configuration.isPressed ? 0.82 : 1.0))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
