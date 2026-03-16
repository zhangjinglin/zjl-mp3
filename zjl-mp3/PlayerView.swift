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
        VStack(spacing: 12) {
            Slider(value: Binding(
                get: { controller.progress },
                set: { controller.seek(to: $0) }
            ))

            HStack {
                Text(formatTime(controller.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(controller.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 28) {
                Button {
                    if controller.isPlaying {
                        controller.pause()
                    } else {
                        controller.play()
                    }
                } label: {
                    Image(systemName: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44, weight: .regular))
                }
                Button {
                    controller.skipForward(seconds: 30)
                } label: {
                    Image(systemName: "goforward.30")
                        .font(.system(size: 32, weight: .regular))
                }
                Button {
                    controller.next()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 36, weight: .regular))
                }
            }
        }
        .padding(.bottom, 12)
    }

    private func formatTime(_ value: Double) -> String {
        guard value.isFinite, value >= 0 else { return "0:00" }
        let totalSeconds = Int(value.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
