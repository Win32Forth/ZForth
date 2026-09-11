import AppKit
import SwiftUI

struct ConsoleTextView: NSViewRepresentable {
    var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = true

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)

        if let container = textView.textContainer {
            container.containerSize = NSSize(width: scroll.contentSize.width,
                                             height: CGFloat.greatestFiniteMagnitude)
            container.widthTracksTextView = true
        }

        textView.autoresizingMask = [.width]
        scroll.documentView = textView
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }

        if textView.string != text {
            let selected = textView.selectedRanges
            textView.string = text
            if selected.contains(where: { $0.rangeValue.length > 0 }) {
                textView.selectedRanges = selected
            }
            textView.scrollToEndOfDocument(nil)
        }

        if let container = textView.textContainer {
            container.containerSize = NSSize(width: scroll.contentSize.width,
                                             height: CGFloat.greatestFiniteMagnitude)
        }
    }
}

