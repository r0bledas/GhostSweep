import SwiftUI
import GhostSweepCore

struct DrivesListView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isTargetedForDrop: Bool = false
    @State private var isFolderHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EXTERNAL DRIVES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { viewModel.refreshVolumes() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Refresh mounted drives")
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            if viewModel.mountedVolumes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "externaldrive.badge.questionmark")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No external drives")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(viewModel.mountedVolumes) { volume in
                            DriveRowView(
                                volume: volume,
                                isSelected: viewModel.selectedVolume?.id == volume.id,
                                onSelect: { viewModel.selectVolume(volume) },
                                onEject: { viewModel.ejectCurrentVolume() }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
            }

            Divider()

            // Custom Folder / Drop Zone
            VStack(alignment: .leading, spacing: 8) {
                Text("CUSTOM FOLDER")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)

                Button(action: selectFolderDialog) {
                    HStack(spacing: 10) {
                        Image(systemName: viewModel.customFolderURL != nil ? "folder.fill" : "folder.badge.plus")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.customFolderURL?.lastPathComponent ?? "Choose Folder...")
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                            Text("or drop here to sweep")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.customFolderURL != nil ? Color.accentColor.opacity(0.15) : (isTargetedForDrop ? Color.accentColor.opacity(0.25) : (isFolderHovered ? Color.primary.opacity(0.05) : Color.clear)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isTargetedForDrop ? Color.accentColor : Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .onHover { isFolderHovered = $0 }
                .padding(.horizontal, 8)
                .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
                    guard let provider = providers.first else { return false }
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let url = url {
                            Task { @MainActor in
                                viewModel.selectCustomFolder(url)
                            }
                        }
                    }
                    return true
                }
            }
            .padding(.bottom, 12)
        }
        .frame(minWidth: 220, maxWidth: 260)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func selectFolderDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select for GhostSweep"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.selectCustomFolder(url)
        }
    }
}

struct DriveRowView: View {
    let volume: VolumeInfo
    let isSelected: Bool
    let onSelect: () -> Void
    let onEject: () -> Void
    @State private var isHovered: Bool = false
    @State private var isEjectHovered: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .accentColor : (isHovered ? .primary : .secondary))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(volume.name)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(volume.fileSystemType)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(isSelected ? 0.2 : 0.12))
                        .cornerRadius(4)
                }

                if volume.totalBytes > 0 {
                    ProgressView(value: volume.usagePercentage)
                        .progressViewStyle(.linear)
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                }
            }

            if volume.isEjectable {
                Button(action: onEject) {
                    Image(systemName: "eject.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isEjectHovered ? .primary : .secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(isEjectHovered ? Color.secondary.opacity(0.2) : Color.clear)
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .onHover { isEjectHovered = $0 }
                .help("Eject volume")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : (isHovered ? Color.primary.opacity(0.06) : Color.clear))
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
