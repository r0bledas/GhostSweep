import SwiftUI
import GhostSweepCore

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Section 1: Automation & Protection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AUTOMATION & PROTECTION")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            settingsToggleRow(
                                title: "Active Real-Time Sentry",
                                subtitle: "Monitors mounted external drives and removes .DS_Store and ._* files immediately upon creation.",
                                isOn: $viewModel.liveShieldEnabled
                            )

                            Divider()
                                .padding(.leading, 12)

                            settingsToggleRow(
                                title: "Auto-Clean on Finder Eject",
                                subtitle: "Sweeps external drives before unmounting whenever ejected via Finder.",
                                isOn: $viewModel.autoCleanOnFinderEject
                            )

                            Divider()
                                .padding(.leading, 12)

                            // System Shield Row
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 8) {
                                        Text("System-Wide USB Shield")
                                            .font(.system(size: 13, weight: .medium))
                                        if let sys = viewModel.systemShieldStatus, sys.isFullyShielded {
                                            Text("Active")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 1)
                                                .background(Color.green.opacity(0.15))
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text("Configures DSDontWriteUSBStores to block .DS_Store creation on USB drives.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 16)
                                Button(viewModel.systemShieldStatus?.isFullyShielded == true ? "Reapply" : "Apply Shield") {
                                    viewModel.applySystemShieldSettings()
                                }
                                .controlSize(.small)
                            }
                            .padding(12)
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                    }

                    // Section 2: Active Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CLEANING PRESETS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            settingsToggleRow(
                                title: "Apple System Debris",
                                subtitle: ".DS_Store, AppleDouble (._*), .Spotlight-V100, .Trashes, .fseventsd",
                                isOn: $viewModel.enableAppleDebris
                            )

                            Divider()
                                .padding(.leading, 12)

                            settingsToggleRow(
                                title: "Cross-Platform Metadata",
                                subtitle: "Thumbs.db, desktop.ini, $RECYCLE.BIN, .directory",
                                isOn: $viewModel.enableCrossPlatform
                            )

                            Divider()
                                .padding(.leading, 12)

                            settingsToggleRow(
                                title: "Developer Artifacts",
                                subtitle: "node_modules, .git, .cache, target, .build, __pycache__",
                                isOn: $viewModel.enableDeveloper
                            )
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 2)
            }

            Divider()

            // Footer Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Internal system drives are permanently protected.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(20)
        .frame(width: 520, height: 500)
    }

    private func settingsToggleRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 16)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(12)
    }
}
