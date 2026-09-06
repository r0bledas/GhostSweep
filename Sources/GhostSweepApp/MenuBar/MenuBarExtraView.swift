import SwiftUI
import GhostSweepCore

struct MenuBarExtraView: View {
    @ObservedObject var viewModel: AppViewModel
    let onOpenMainWindow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .center) {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14, weight: .bold))
                Text("GhostSweep")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                if viewModel.liveShieldEnabled {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Sentry Active")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            Divider()

            // Mounted External Drives
            if viewModel.mountedVolumes.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "externaldrive.badge.minus")
                        .foregroundColor(.secondary)
                    Text("No external drives connected")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            } else {
                VStack(spacing: 6) {
                    ForEach(viewModel.mountedVolumes) { volume in
                        HStack(spacing: 8) {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.primary)
                                .font(.system(size: 13))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(volume.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                Text("\(volume.formattedAvailableCapacity) free • \(volume.fileSystemType)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("Clean") {
                                viewModel.selectVolume(volume)
                                viewModel.executeSweep()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .font(.system(size: 11))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 2)
                    }
                }

                Divider()

                // Clean All Button
                HStack {
                    Button {
                        viewModel.executeCleanAll()
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isSweeping {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                                Text("Sweeping Drives...")
                                    .font(.system(size: 12, weight: .medium))
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Clean All Drives")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(viewModel.isSweeping)
                }
                .padding(.horizontal, 14)
            }

            Divider()

            // Footer
            HStack {
                Button("Open GhostSweep...") {
                    onOpenMainWindow()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.primary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .frame(width: 290)
    }
}
