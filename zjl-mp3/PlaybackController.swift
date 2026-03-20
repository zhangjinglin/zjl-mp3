//
//  PlaybackController.swift
//  zjl-mp3
//
//  Created by ZhangJinglin on 2026/3/15.
//

import AVFoundation
import Combine
import Foundation
import MediaPlayer

final class PlaybackController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let supportedPlaybackRates: [Float] = [1.0, 1.25, 1.5, 1.75, 2.0]

    @Published var playlist: [URL] = []
    @Published var currentIndex: Int? = nil
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackRate: Float = 1.5
    @Published var errorMessage: String? = nil

    private let bookmarkKey = "folderBookmark"
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var folderURL: URL?
    private var isAccessingFolder = false
    private var remoteCommandsConfigured = false

    var folderDisplayName: String {
        if let folderURL = folderURL {
            return folderURL.lastPathComponent
        }
        return "No folder selected"
    }

    override init() {
        super.init()
        configureAudioSession()
        configureRemoteCommands()
    }

    func restoreBookmarkIfNeeded() {
        guard folderURL == nil, let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return
        }

        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data,
                              options: [],
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            if isStale {
                saveBookmark(for: url)
            }
            loadFolder(url: url)
        } catch {
            errorMessage = "Failed to restore folder access: \(error.localizedDescription)"
        }
    }

    func loadFolder(url: URL) {
        stop()
        errorMessage = nil
        stopAccessingFolderIfNeeded()
        folderURL = url
        startAccessingFolderIfNeeded()
        saveBookmark(for: url)

        do {
            playlist = try loadMP3Files(in: url)
        } catch {
            playlist = []
            errorMessage = "Failed to load folder: \(error.localizedDescription)"
        }

        if !playlist.isEmpty {
            currentIndex = 0
            prepareCurrentItem()
        } else {
            currentIndex = nil
        }
    }

    func play() {
        configureAudioSession()
        guard let player = audioPlayer else {
            prepareCurrentItem()
            audioPlayer?.play()
            isPlaying = audioPlayer?.isPlaying ?? false
            startProgressTimer()
            updateNowPlayingInfo()
            return
        }
        player.play()
        isPlaying = player.isPlaying
        startProgressTimer()
        updateNowPlayingInfo()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingInfo()
    }

    func next() {
        guard let index = currentIndex else { return }
        let nextIndex = index + 1
        guard nextIndex < playlist.count else {
            stop()
            clearNowPlayingInfo()
            return
        }
        currentIndex = nextIndex
        prepareCurrentItem()
        play()
    }

    func previous() {
        guard let index = currentIndex else { return }
        let prevIndex = index - 1
        guard prevIndex >= 0 else {
            seek(to: 0)
            return
        }
        currentIndex = prevIndex
        prepareCurrentItem()
        play()
    }

    func playItem(at index: Int) {
        guard index >= 0, index < playlist.count else { return }
        currentIndex = index
        prepareCurrentItem()
        play()
    }

    func seek(to progress: Double) {
        guard let player = audioPlayer, player.duration > 0 else { return }
        let target = player.duration * progress
        player.currentTime = target
        self.progress = progress
        self.currentTime = player.currentTime
        updateNowPlayingInfo()
    }

    func skipForward(seconds: Double) {
        guard let player = audioPlayer, player.duration > 0 else { return }
        let target = min(player.currentTime + seconds, player.duration)
        player.currentTime = target
        progress = target / player.duration
        currentTime = player.currentTime
        duration = player.duration
        updateNowPlayingInfo()
    }

    func setPlaybackRate(_ rate: Float) {
        guard Self.supportedPlaybackRates.contains(rate) else { return }
        playbackRate = rate
        audioPlayer?.rate = rate
        updateNowPlayingInfo()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        progress = 0
        currentTime = 0
        duration = 0
        stopProgressTimer()
        clearNowPlayingInfo()
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let index = currentIndex, index < playlist.count else { return }
        let finishedURL = playlist[index]
        deleteFileIfPossible(url: finishedURL)

        // Remove from playlist and advance.
        playlist.remove(at: index)
        if playlist.isEmpty {
            currentIndex = nil
            stop()
            return
        }

        let nextIndex = min(index, playlist.count - 1)
        currentIndex = nextIndex
        prepareCurrentItem()
        play()
    }

    // MARK: - Private

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            do {
                try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            } catch {
                // Fallback for devices/OSes that reject the options.
                try session.setCategory(.playback, mode: .default, options: [])
            }
            try session.setActive(true)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
        }
    }

    private func loadMP3Files(in folderURL: URL) throws -> [URL] {
        let files = try FileManager.default.contentsOfDirectory(at: folderURL,
                                                               includingPropertiesForKeys: nil,
                                                               options: [.skipsHiddenFiles])
        let mp3s = files.filter { $0.pathExtension.lowercased() == "mp3" }
        return mp3s.sorted { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }
    }

    private func prepareCurrentItem() {
        guard let index = currentIndex, index < playlist.count else { return }
        let url = playlist[index]
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.enableRate = true
            player.rate = playbackRate
            player.delegate = self
            player.prepareToPlay()
            audioPlayer = player
            progress = 0
            currentTime = 0
            duration = player.duration
            updateNowPlayingInfo()
        } catch {
            errorMessage = "Failed to load file: \(url.lastPathComponent)"
        }
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let player = self.audioPlayer, player.duration > 0 else { return }
            self.progress = player.currentTime / player.duration
            self.currentTime = player.currentTime
            self.duration = player.duration
            self.updateNowPlayingInfo()
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func configureRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = false

        commandCenter.skipForwardCommand.preferredIntervals = [30]

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.isPlaying ? self.pause() : self.play()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let event = event as? MPChangePlaybackPositionCommandEvent,
                  let player = self.audioPlayer, player.duration > 0 else {
                return .commandFailed
            }
            let target = min(max(event.positionTime, 0), player.duration)
            player.currentTime = target
            self.progress = target / player.duration
            self.currentTime = player.currentTime
            self.updateNowPlayingInfo()
            return .success
        }
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(seconds: 30)
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let index = currentIndex, index < playlist.count else {
            clearNowPlayingInfo()
            return
        }
        let url = playlist[index]
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = url.lastPathComponent
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = playbackRate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func deleteFileIfPossible(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            errorMessage = "Failed to delete: \(url.lastPathComponent)"
        }
    }

    private func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(options: [.minimalBookmark],
                                            includingResourceValuesForKeys: nil,
                                            relativeTo: nil)
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        } catch {
            errorMessage = "Failed to save folder access: \(error.localizedDescription)"
        }
    }

    private func startAccessingFolderIfNeeded() {
        guard let folderURL = folderURL, !isAccessingFolder else { return }
        isAccessingFolder = folderURL.startAccessingSecurityScopedResource()
        if !isAccessingFolder {
            errorMessage = "Failed to access folder (permission denied)."
        }
    }

    private func stopAccessingFolderIfNeeded() {
        if isAccessingFolder, let folderURL = folderURL {
            folderURL.stopAccessingSecurityScopedResource()
            isAccessingFolder = false
        }
    }

    deinit {
        stopAccessingFolderIfNeeded()
    }
}
