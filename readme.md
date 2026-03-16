**iPhone MP3 Folder Player v1 Plan**

**Summary**
- Build a native iOS (Swift/SwiftUI) app that lets users pick a folder from the Files app, loads all MP3s in that folder as a playlist, plays them sequentially at 1.5x by default, and deletes each file immediately after it finishes playing.
- Support background/lock-screen playback.
- Provide controls: play/pause, previous, next, and a progress scrubber.

**Key Changes / Implementation**
- Folder selection and access
  - Use `UIDocumentPickerViewController` with `UTType.folder` to pick a folder.
  - Store a security-scoped bookmark for persistent access.
  - Start/stop `startAccessingSecurityScopedResource()` around file operations.
- Playlist building
  - Enumerate files with `FileManager` in the selected folder (non-recursive).
  - Filter by `.mp3` extension.
  - Sort by filename ascending.
- Playback
  - Use `AVAudioSession` with `.playback` and enable background audio.
  - Use `AVQueuePlayer` or `AVAudioPlayer` with manual queueing.
  - Set default rate to `1.5` (`AVAudioPlayer.enableRate = true` or `AVQueuePlayer` with `AVAudioTimePitchAlgorithm`).
  - Update UI with current item and progress; support previous/next.
- Delete-after-play
  - On track completion, delete the file via `FileManager.removeItem(at:)`.
  - Remove the item from the in-memory playlist; advance to next track.
  - Handle delete failures (e.g., permission or iCloud file not local) with a non-blocking error state.

**Public APIs / Interfaces**
- SwiftUI views:
  - `FolderPickerView` (invokes document picker)
  - `PlayerView` (playlist + controls + progress)
- Player controller abstraction (e.g., `PlaybackController`) exposing:
  - `load(folderURL)`
  - `play()`, `pause()`, `next()`, `previous()`
  - `currentItem`, `progress`, `isPlaying`
  - `errors` (optional)

**Test Plan (Manual)**
1. Pick a folder from Files with multiple MP3s; playlist shows in filename order.
2. Playback starts at 1.5x and continues sequentially.
3. After each track ends, confirm file is deleted in Files.
4. Background/lock-screen playback continues; media controls work.
5. Previous/next and scrubber work without crashing.
6. Folder with non-MP3 files: only MP3s are played.
7. Permission error path: pick an iCloud-only file not downloaded; verify graceful error.

**Assumptions**
- Target platform: native iOS (Swift/SwiftUI).
- MP3 source: Files app folder.
- Deletion means deleting the original file.
- Background playback required.
- Non-recursive folder scan.
- Playback order: filename ascending.
- Controls include previous + progress scrubber.
- Minimum iOS: 16+.
