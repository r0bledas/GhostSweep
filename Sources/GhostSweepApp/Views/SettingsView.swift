import SwiftUI
import GhostSweepCore

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("GhostSweep Preferences")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            Divider()

            // Automation & Prevention Shields Section
            VStack(alignment: .leading, spacing: 10) {
                Text("PREVENTION & SHIELDS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Toggle(isOn: $viewModel.liveShieldEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Real-Time Sentry Shield")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Actively watches connected external drives and vaporizes .DS_Store and ._* files the moment Finder creates them.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)

                Toggle(isOn: $viewModel.autoCleanOnFinderEject) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-Clean on Finder Eject")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Silently sweeps external drives before unmounting whenever you eject via Finder or desktop.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)

                // System Shield Status & Action
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("System-Wide macOS Shield")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let sys = viewModel.systemShieldStatus, sys.isFullyShielded {
                                Text("ACTIVE")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                        }
                        Text("Applies DSDontWriteUSBStores so Finder never creates .DS_Store on USB drives.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Apply Shield") {
                        viewModel.applySystemShieldSettings()
                    }
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)
            }

            Divider()

            // Presets Section
            VStack(alignment: .leading, spacing: 10) {
                Text("ACTIVE PRESETS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Toggle(isOn: $viewModel.enableAppleDebris) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple System Debris")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(".DS_Store, AppleDouble (._*), .Spotlight-V100, .Trashes, .fseventsd")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)


                Toggle(isOn: $viewModel.enableCrossPlatform) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cross-Platform Junk")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Thumbs.db, desktop.ini, $RECYCLE.BIN, .directory")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)

                Toggle(isOn: $viewModel.enableDeveloper) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Developer Artifacts (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("node_modules, .git, .cache, target, .build, __pycache__")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
            }

            Spacer()

            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.green)
                Text("Safety Guard: Internal macOS system drives (Macintosh HD) are always protected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(width: 480, height: 440)
    }
}
