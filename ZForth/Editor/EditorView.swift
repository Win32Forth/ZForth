import SwiftUI

struct EditorView: View {
    @Bindable var session: ForthSession
    
    var body: some View {
        TextEditor(text: Bindable(session).editorText)
            .font(.system(.body, design: .monospaced))
            .frame(minWidth: 400, minHeight: 280)
    }
}

