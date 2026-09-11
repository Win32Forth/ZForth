import SwiftUI

struct FileCommands: Commands {
    var session: ForthSession

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
                session.statusLine = "Editor queued for evaluate"
            }
            .keyboardShortcut("e", modifiers: [.command])
        }
    }

    @MainActor
    private func openIntoEditor() async {
        guard let url = await session.openFile(
            prompt: "Open Forth source",
            types: ["fs", "fth", "txt"]
        ) else { return }

        do {
            session.editorText = try session.loadText(from: url)
            session.statusLine = "Loaded \(url.lastPathComponent)"
        } catch {
            session.statusLine = "Load failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func saveEditor() async {
        guard let url = await session.saveFile(
            prompt: "Save Forth source",
            suggestedName: "program.fs",
            types: ["fs", "fth", "txt"]
        ) else { return }

        do {
            try session.saveText(session.editorText, to: url)
            session.statusLine = "Saved \(url.lastPathComponent)"
        } catch {
            session.statusLine = "Save failed: \(error.localizedDescription)"
        }
    }
}
