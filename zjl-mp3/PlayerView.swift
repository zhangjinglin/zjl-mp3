//
//  PlayerView.swift
//  zjl-mp3
//
//  Created by ZhangJinglin on 2026/3/15.
//

import SwiftUI

struct PlayerView: View {
    @ObservedObject var controller: PlaybackController

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Now Playing")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(currentTrackTitle)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                }
                Spacer()
                Text(formattedRate(controller.playbackRate))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
            }

            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { controller.progress },
                    set: { controller.seek(to: $0) }
                ))
                .tint(AppTheme.accent)

                HStack {
                    Text(formatTime(controller.currentTime))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text(formatTime(controller.duration))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            HStack(spacing: 16) {
                Button {
                    if controller.isPlaying {
                        controller.pause()
                    } else {
                        controller.play()
                    }
                } label: {
                    Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .black))
                        .frame(width: 64, height: 64)
                        .background(AppTheme.accent)
                        .foregroundStyle(Color.black.opacity(0.72))
                        .clipShape(Circle())
                        .shadow(color: AppTheme.accent.opacity(0.28), radius: 18, y: 8)
                }

                Button {
                    controller.skipForward(seconds: 30)
                } label: {
                    Image(systemName: "goforward.30")
                        .font(.system(size: 24, weight: .bold))
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.07))
                        .foregroundStyle(AppTheme.primaryText)
                        .clipShape(Circle())
                }

                Menu {
                    ForEach(PlaybackController.supportedPlaybackRates, id: \.self) { rate in
                        Button {
                            controller.setPlaybackRate(rate)
                        } label: {
                            if controller.playbackRate == rate {
                                Label(formattedRate(rate), systemImage: "checkmark")
                            } else {
                                Text(formattedRate(rate))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "speedometer")
                        Text(formattedRate(controller.playbackRate))
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(AppTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private func formatTime(_ value: Double) -> String {
        guard value.isFinite, value >= 0 else { return "0:00" }
        let totalSeconds = Int(value.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formattedRate(_ rate: Float) -> String {
        let rounded = Int(rate)
        if Float(rounded) == rate {
            return "\(rounded)x"
        }
        return "\(rate.cleanString)x"
    }

    private var currentTrackTitle: String {
        guard let index = controller.currentIndex, index < controller.playlist.count else {
            return "No Track Selected"
        }
        return controller.playlist[index].deletingPathExtension().lastPathComponent
    }
}

extension Float {
    var cleanString: String {
        let string = String(format: "%.2f", self)
        return string.replacingOccurrences(of: #"(\.0+|0+)$"#, with: "", options: .regularExpression)
    }
}
