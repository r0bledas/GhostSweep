import SwiftUI
import GhostSweepCore

struct MainWindowView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showSettings: Bool = false

    var body: some View {
        NavigationSplitView {
            DrivesListView(viewModel: viewModel)
        } detail: {
            VStack(spacing: 0) {
                // Detail Header
                detailHeader

                Divider()

                if !viewModel.hasFullDiskAccess {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                            .foregroundColor(.orange)
                        Text("Full Disk Access is required by macOS to delete protected Spotlight directories (.Spotlight-V100).")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                        Button("Grant Access...") {
                            viewModel.openFullDiskAccessSettings()
                        }
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))

                    Divider()
                }

                // Content / Checklist
                if viewModel.isScanning {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(viewModel.currentStatus)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScanPreviewView(viewModel: viewModel)
                }

                Divider()

                // Bottom Action Footer
                footerBar
            }
        }
        .frame(minWidth: 780, minHeight: 480)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showResultSheet) {
            SweepResultSheet(result: viewModel.lastResult) {
                viewModel.showResultSheet = false
            }
        }
    }

    private var detailHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: viewModel.customFolderURL != nil ? "folder.fill" : "externaldrive.fill")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(viewModel.currentTargetURL?.lastPathComponent ?? "No Target Selected")
                        .font(.title3)
                        .fontWeight(.bold)

                    if let vol = viewModel.selectedVolume {
                        Text(vol.fileSystemType)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                if let vol = viewModel.selectedVolume, vol.totalBytes > 0 {
                    Text(vol.formattedCapacity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let custom = viewModel.customFolderURL {
                    CopyablePathText(path: custom.path, fontSize: 11)
                }
            }

            Spacer()

            // Header Action Buttons
            HStack(spacing: 8) {
                Button(action: { viewModel.startScan() }) {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isScanning || viewModel.isSweeping || viewModel.currentTargetURL == nil)

                if let imm = viewModel.immunizationStatus, viewModel.selectedVolume != nil {
                    Button(action: { viewModel.toggleImmunization() }) {
                        Label(
                            imm.isFullyImmunized ? "Drive Shielded" : "Immunize Drive",
                            systemImage: imm.isFullyImmunized ? "shield.fill" : "shield"
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(imm.isFullyImmunized ? .green : .accentColor)
                    .help(imm.isFullyImmunized ? "Drive is immunized against Spotlight, FSEvents, and Trashes. Click to toggle." : "Place hardware prevention markers so macOS cannot index or drop trash on this drive.")
                }

                Button(action: { viewModel.executeSweep() }) {
                    Label("Clean Now", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isScanning || viewModel.isSweeping || viewModel.selectedItemsCount == 0)
            }
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            if viewModel.isSweeping {
                ProgressView()
                    .scaleEffect(0.6)
            }
            Text(viewModel.currentStatus)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if viewModel.liveShieldEnabled {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("Live Shield Active")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .help("GhostSweep Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SweepResultSheet: View {
    let result: SweepResult?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(.accentColor)

            Text("Sweep Completed!")
                .font(.title2)
                .fontWeight(.bold)

            if let res = result {
                VStack(spacing: 8) {
                    HStack {
                        Text("Items Removed:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(res.itemsDeleted)")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Space Reclaimed:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(res.formattedReclaimedSize)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                .frame(width: 240)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                if !res.errors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Notice", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        ForEach(res.errors, id: \.self) { err in
                            Text(err)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .frame(maxWidth: 280)
                }
            }

            Button("Done", action: onDismiss)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
        }
        .padding(28)
        .frame(width: 340)
    }
}
