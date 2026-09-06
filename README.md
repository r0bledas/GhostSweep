<p align="center">
  <img src="assets/icon.jpg" width="128" height="128" alt="GhostSweep Icon" style="border-radius: 28px;" />
</p>

# 👻 GhostSweep

> Lightweight, native macOS application and CLI tool that cleans and **permanently prevents** hidden residue files (`.DS_Store`, `._*`, `.Spotlight-V100`, `.Trashes`, Windows/Linux junk) on external drives. Built with Swift & SwiftUI with zero external dependencies.

---

## 🌟 Features

- **🛡️ Drive Immunization**: Places hardware-level prevention markers directly on the drive:
  - `.metadata_never_index`: Tells any Mac never to index the drive with Spotlight.
  - `.fseventsd/no_log`: Tells macOS never to log filesystem events to the volume.
  - Neutralized `.Trashes`: Replaces the trash directory with an immutable lock file (`chflags uchg`) so Finder permanently deletes files rather than accumulating hidden trash.
  - **Immunization Protection Guard**: Clean operations are guaranteed never to flag or delete immunization shield files.
- **⚡ Active Real-Time Sentry Shield**: Background `FSEventStream` watcher that detects newly created `.DS_Store` and AppleDouble (`._*`) files in milliseconds and vaporizes them before they settle.
- **🌐 System-Wide macOS Shield**: Verifies and configures `com.apple.desktopservices DSDontWriteUSBStores` so Finder never writes `.DS_Store` files to USB or network shares.
- **Apple System Debris Sweeper**: Eliminates existing `.DS_Store`, AppleDouble (`._*`), `.Spotlight-V100`, `.TemporaryItems`, etc.
- **Cross-Platform Sanitizer**: Cleans Windows and Linux junk files (`Thumbs.db`, `desktop.ini`, `$RECYCLE.BIN`, `.directory`).
- **Developer Artifacts (Optional)**: Can clean `node_modules`, `.git`, `.cache`, `target`, `.build`, `__pycache__` when moving project folders to USB.
- **Auto-Clean on Finder Eject**: Optional background watcher that silently sweeps external drives whenever you eject them via Finder.
- **Interactive Checklist**: Review and selectively toggle individual files or entire categories before deletion.
- **Strict System Guardrails**: Whitelists and protects internal system drives (`Macintosh HD`, `/System`, etc.) so only external drives or explicitly chosen folders can be swept.
- **Fast POSIX Engine**: Uses Darwin POSIX kernel-level directory enumeration to catch hidden AppleDouble `._*` files that standard Cocoa APIs mask.

---

## 🚀 Quick Start

### 1. Build and Run the App

```bash
cd /Users/raudel/Documents/XCode/Projects/GhostSweep

# Build the .app bundle and CLI
make build

# Launch the app
make run
```

Or open directly in Xcode:
```bash
open -a Xcode /Users/raudel/Documents/XCode/Projects/GhostSweep
```

---

### 2. Using the CLI (`ghostsweep`)

The CLI is fully standalone:

```bash
# List mounted external drives
.build/release/ghostsweep list

# Preview residue files on a drive or folder
.build/release/ghostsweep scan /Volumes/MyUSB

# Clean drive
.build/release/ghostsweep clean /Volumes/MyUSB --yes

# Immunize drive against Spotlight, Trashes, and FSEvents
.build/release/ghostsweep immunize /Volumes/MyUSB

# Clean including developer artifacts (node_modules, .git)
.build/release/ghostsweep clean /Volumes/MyUSB --all --yes
```

---

## 🏗️ Architecture

- **`GhostSweepCore`**: Shared Swift library containing:
  - `VolumeManager`: Discovers external drives and validates system safety.
  - `FileSweeper`: Fast POSIX-based scanner, dry-run calculator, and sweeper.
  - `DiskEjector`: Asynchronous disk ejector using `diskutil`.
  - `UnmountWatcher`: Listens for `NSWorkspace.willUnmountNotification` for automatic Finder unmount cleaning.
- **`GhostSweepApp`**: Modern SwiftUI macOS app with:
  - **Menu Bar Extra**: Persistent status bar icon with drive quick-actions.
  - **Main Window**: NavigationSplitView with drive manager, drag-and-drop zone, preset toggles, and interactive checklist.
- **`GhostSweepCLI`**: Fast command-line executable.

---

## 🧪 Testing

Run all unit tests:

```bash
make test
```
