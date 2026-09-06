import SwiftUI
import GhostSweepCore

struct ScanPreviewView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header Action Bar
            HStack {
                HStack(spacing: 6) {
                    Text("\(viewModel.selectedItemsCount) of \(viewModel.scannedItems.count) selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(viewModel.formattedSelectedSize)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Button("Select All") {
                    viewModel.selectAll(true)
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Button("Deselect All") {
                    viewModel.selectAll(false)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            if viewModel.scannedItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                    Text("No residue files found!")
                        .font(.headline)
                    Text("Target is free of .DS_Store, AppleDouble, and other junk files.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    let grouped = Dictionary(grouping: viewModel.scannedItems, by: { $0.category })
                    ForEach(PresetCategory.allCases.filter { grouped[$0] != nil }) { category in
                        if let items = grouped[category], !items.isEmpty {
                            CategorySectionView(
                                category: category,
                                items: items,
                                onToggleCategory: { isSelected in
                                    viewModel.toggleCategory(category: category, isSelected: isSelected)
                                },
                                onToggleItem: { id in
                                    viewModel.toggleItemSelection(id: id)
                                }
                            )
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

struct CategorySectionView: View {
    let category: PresetCategory
    let items: [ScannedItem]
    let onToggleCategory: (Bool) -> Void
    let onToggleItem: (UUID) -> Void

    var isAllSelected: Bool {
        items.allSatisfy { $0.isSelected }
    }

    var totalCategorySize: String {
        let size = items.reduce(0) { $0 + $1.sizeBytes }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var body: some View {
        Section(
            header: HStack {
                Toggle("", isOn: Binding(
                    get: { isAllSelected },
                    set: { onToggleCategory($0) }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()

                Image(systemName: category.systemImage)
                    .foregroundColor(.accentColor)

                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.bold)

                Spacer()

                Text("\(items.count) items (\(totalCategorySize))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        ) {
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Toggle("", isOn: Binding(
                        get: { item.isSelected },
                        set: { _ in onToggleItem(item.id) }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()

                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundColor(item.isDirectory ? .blue : .secondary)
                        .font(.caption)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.filename)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                        CopyablePathText(path: item.path, fontSize: 10)
                    }

                    Spacer()

                    Text(item.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
    }
}
