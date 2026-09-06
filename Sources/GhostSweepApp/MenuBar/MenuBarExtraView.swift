import SwiftUI
import GhostSweepCore

struct MenuBarExtraView: View {
    @ObservedObject var viewModel: AppViewModel
    let onOpenMainWindow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
                Text("GhostSweep")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            Divider()

            if viewModel.mountedVolumes.isEmpty {
                HStack {
                    Image(systemName: "externaldrive.badge.minus")
                        .foregroundColor(.secondary)
                    Text("No external drives mounted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            } else {
                ForEach(viewModel.mountedVolumes) { volume in
                    HStack(spacing: 8) {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(volume.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(volume.fileSystemType)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("Clean") {
                            viewModel.selectVolume(volume)
                            viewModel.executeSweep()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .font(.caption)
                    }
                    .padding(.horizontal, 14)
                }
            }

            Divider()

            HStack {
                Button("Open GhostSweep...") {
                    onOpenMainWindow()
                }
                .buttonStyle(.plain)
                .font(.caption)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .frame(width: 290)
    }
}
