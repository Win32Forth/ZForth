import AppKit
import SwiftUI

struct FileCommands: Commands {
    var session: ForthSession
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open into Editor…") {
                Task { await openIntoEditor() }
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Save Editor…") {
                Task { await saveEditor() }
            }
            .keyboardShortcut("s", modifiers: .command)
        }
        CommandMenu("Forth") {
            Button("Evaluate Editor") {
                ForthEvalMailbox.post(session.editorText)
                session.submitConsoleLine("")   // wake zforth_accept
                session.statusLine = "Editor queued for evaluate"
            }
            .keyboardShortcut("e", modifiers: [.command])
        }
    }

    @MainActor
    private func openIntoEditor() async {
        guard let url = await session.openFile(
            prompt: "Open Forth source",
            types: ["fth", "txt"]
        ) else { return }

        do {
            session.editorText = try session.loadText(from: url)
            session.cwd = url.deletingLastPathComponent()
            session.statusLine = "Loaded \(url.lastPathComponent)"
            showEditorWindow()
        } catch {
            session.statusLine = "Load failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func showEditorWindow() {
        if let win = NSApp.windows.first(where: { window in
            window.identifier?.rawValue == "editor"
            || window.title.contains("Editor")
        }) {
            if windowIsMiniaturized(win) { win.deminiaturize(nil) }
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Window was closed: ask SwiftUI to recreate the "editor" scene.
    }

    private func windowIsMiniaturized(_ win: NSWindow) -> Bool {
        win.isMiniaturized
    }
    
    @MainActor
    private func saveEditor() async {
        guard let url = await session.saveFile(
            prompt: "Save Forth source",
            suggestedName: "program.fth",
            types: ["fth", "txt"]
        ) else { return }

        do {
            try session.saveText(session.editorText, to: url)
            session.statusLine = "Saved \(url.lastPathComponent)"
        } catch {
            session.statusLine = "Save failed: \(error.localizedDescription)"
        }
    }
}
