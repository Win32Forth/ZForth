import SwiftUI
import AppKit

struct ConsoleView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var session: ForthSession
    @State private var inputLine = ""
    @State private var vmStarted = false

    var body: some View {
        VStack(spacing: 0) {
            ConsoleTextView(text: session.consoleText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                TextField("Input", text: $inputLine)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit { submit() }
                Button("Enter") { submit() }
                    .keyboardShortcut(.return, modifiers: [])
            }
            .padding(8)

            Text(session.statusLine)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
        }
        .frame(minWidth: 400, minHeight: 240)
        .background(
            KeyCatcher { event in
                if let chars = event.characters, let ch = chars.first {
                    session.submitKey(character: ch)
                }
            }
        )
        .onAppear {
            session.openEditorWindow = { openWindow(id: "editor") }
            ForthCBridge.attach(session)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first(where: { $0.title.contains("Console") })?
                .makeKeyAndOrderFront(nil)
            guard !vmStarted else { return }
            vmStarted = true
            ForthVMControl.start()
        }
    }

    private func submit() {
        let line = inputLine
        inputLine = ""
        session.submitConsoleLine(line)
    }
}
