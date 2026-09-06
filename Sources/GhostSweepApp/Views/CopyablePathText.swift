import SwiftUI
import AppKit

struct CopyablePathText: View {
    let path: String
    var fontSize: CGFloat = 10
    
    @State private var isHovering: Bool = false
    @State private var showCopiedFeedback: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Text(path)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(isHovering ? .accentColor : .secondary)
                .underline(isHovering)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            if showCopiedFeedback {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                    Text("Copied!")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.green)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else if isHovering {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 8))
                    .foregroundColor(.accentColor)
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onTapGesture {
            copyToClipboard()
        }
        .help("Click to copy full path")
        .contextMenu {
            Button(action: copyToClipboard) {
                Label("Copy Path", systemImage: "doc.on.doc")
            }
            Button(action: revealInFinder) {
                Label("Reveal in Finder", systemImage: "arrow.up.forward.app")
            }
        }
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)

        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedFeedback = false
            }
        }
    }

    private func revealInFinder() {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}
